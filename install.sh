#!/bin/sh
# Copyright 2019
# Created by Christopher Hittner and Justin Barish
# All Rights Reserved.

partition () {
    gparted
}

mountdev () {
    echo "Will mount $1 at $2"
    mkdir -p $2
    mount $1 $2
    if [ $? -ne 0 ]; then
        echo "Failed to mount $1 at $2; terminating"
        cleanup
        return 1
    else
        echo "Successfully mounted $1 at $2"
        return 0
    fi
}

unmount () {
    umount $1
    if [ $? -ne 0 ]; then
        echo "Failed to unmount $1; please handle manually"
    fi
}

cleanup () {
    echo "Unmounting all drives"
    unmount "$MNT/public"
    unmount "$MNT/boot/efi"
    unmount "$MNT/boot"
    unmount "$MNT"
    echo "Closing encryption map"
    cryptsetup close $CRYPT
}

DEVICE="$1"
MNT="$2"

INSTALLER=chroot_installer.sh

UNCLE_BEN="With great power comes great responsibility."

PUB_DEVICE=$DEVICE"1"
EFI_DEVICE=$DEVICE"2"
BOOT_DEVICE=$DEVICE"3"
ROOT_DEVICE=$DEVICE"4"

CRYPT=cryptroot
CRYPTROOT=/dev/mapper/$CRYPT
CRYPTROOT_PASSWD="password"

if [ "$EUID" -ne 0 ]; then
    # Requires root privileges
    echo "$0: Please run as root"
    exit 1
elif [ $# -lt 2 ]; then
    echo "$0: usage: $0 <device> <mount point>"
    echo "example: '$0 /dev/sdb /mnt'"
    exit 1
elif [ ! -e $DEVICE ]; then
    echo "$0: Device $DEVICE is not currently detected by the system."
    exit 1
elif [ ! -e $MNT ]; then
    echo "$0: Directory $MNT is not currently detected by the system."
    exit 1
fi

################
## FORMATTING ##
################

echo "Step 1: Partitioning"
echo "Formatting a space for the following partitions:"
echo $PUB_DEVICE": /public"
echo $EFI_DEVICE": /boot/efi (should be FAT32, enable 'esp' flag)"
echo $BOOT_DEVICE": /boot"
echo $ROOT_DEVICE": /"
echo ""

echo "Formatting $DEVICE with required partitions"
wipefs -a $DEVICE
cat diskformat | sfdisk $DEVICE
if [ $? -ne 0 ]; then
    echo "Failed to format $DEVICE with required partitions"
    exit 1
fi

# Create the encrpyted device
echo "Applying encryption to $ROOT_DEVICE"
echo "$CRYPTROOT_PASSWD" | cryptsetup -q -v luksFormat --type luks1 $ROOT_DEVICE
if [ $? -ne 0 ]; then
    echo "Failed to create encrypted root device"
    exit 1
fi

# Prepare the mapping
echo "Opening encrypted root"
echo "$CRYPTROOT_PASSWD" | cryptsetup open $ROOT_DEVICE $CRYPT
if [ $? -ne 0 ]; then
    echo "Failed to open encrypted root device"
    exit 1
fi

# Format the root directory of the device
echo "Formatting $ROOT_DEVICE as ext2"
mkfs.ext2 -F -L examroot $CRYPTROOT # The filesystem is built via encryption
echo "Formatting complete"

# Format the boot directory of the device
echo "Formatting $BOOT_DEVICE as ext2"
mkfs.ext2 -F -L examboot $BOOT_DEVICE
echo "Formatting complete"

echo "Formatting $EFI_DEVICE as fat32"
mkfs.fat -F 32 -n examefi $EFI_DEVICE
echo "Formatting complete"

# Format the key directory
echo "Formatting $PUB_DEVICE as ext2"
mkfs.fat -F 32 -n exampub $PUB_DEVICE
echo "Formatting complete"

echo "Step 1 complete!"
echo ""

##############
## MOUNTING ##
##############

echo "Step 2: Mounting"
echo "Mounting drives for installation in $MNT"

# Mount the root device
mountdev $CRYPTROOT "$MNT"
if [ $? -ne 0 ]; then
    cryptsetup close $CRYPT
    exit 1
else echo ""
fi

# Mount the boot device
mountdev $BOOT_DEVICE "$MNT/boot/"
if [ $? -ne 0 ]; then
    exit 1
else echo ""
fi

# Mount the EFI device
mountdev $EFI_DEVICE "$MNT/boot/efi"
if [ $? -ne 0 ]; then
    exit 1
else echo ""
fi

# Mount the key device
mkdir "$MNT/public"
mount $PUB_DEVICE "$MNT/public"
if [ $? -ne 0 ]; then
    exit 1
else echo ""
fi

# Make the directory structure for the public content
echo "Forging directory structure of /public"
mkdir "$MNT/public/keys" "$MNT/public/submission"

# Special directly only accessible by root
echo "Forging /private directory"
mkdir "$MNT/private"
chmod 700 "$MNT/private"

# Install base packages
echo "Step 3: Installation"
echo "Running pacstrap to install needed packages"
pacstrap "$MNT" base grub efibootmgr vim emacs make gcc sudo
if [ $? -ne 0 ]; then
    echo "Failed to install base packages to the device"
    cleanup
    exit 1
else
    echo "Execution of pacstrap was successful"
fi

echo "Generating fstab"
genfstab -U -p "$MNT" >> "$MNT/etc/fstab"

###################################
## DRIVE INSTALLATION FILE SETUP ##
###################################

# Move necessary files into the drive.

# /usr/local/bin:
# getkeys
#       Moves key data to /private
# hashit
#       Helper for the PAM module
# submit-assignment
#       Executes assignment submission operations
echo "Providing files for /usr/local/bin"
cp ./usrlocbin/* "$MNT/usr/local/bin/"

# /etc:
# mkinitcpio.conf
#       Configuration for initramfs; helps setup the encryption
# sudoers
#       Custom configuration to restrict usage of sudo
echo "Providing files for /etc"
cp ./etc/* "$MNT/etc/"

# Generate the LB (Linux Box) keypair
echo "Performing key generation"
./usrlocbin/makekeypair public_key_lb.pem private_key_lb.pem

# Public key goes to the partition
mv public_key_lb.pem "$MNT/public/keys/"

# Private key is in the main partition, and is encrypted until boot.
# It is only readable by root.
mkdir "$MNT/etc/keys"
chmod 700 "$MNT/etc/keys"
mv private_key_lb.pem "$MNT/etc/keys/"

# Provide the PAM installation data on the drive
echo "Providing PAM setup files"
cp -r pamdata "$MNT"

# Provide emacs config
echo "Providing emacs config"
mkdir "$MNT/etc/default/.emacs.d/"
cp ./home/init.el "$MNT/etc/default/.emacs.d/"

# Provide desktop wallpaper with author names
cp wallpaper.jpg "$MNT/"

echo "Copying installation script '$INSTALLER' to $MNT"
cp $INSTALLER "$MNT"

##############################
## DRIVE INSTALLATION PHASE ##
##############################

echo "Running secondary installer with $MNT as root directory (arch-chroot)"
arch-chroot "$MNT" sh $INSTALLER $DEVICE

echo "Initiating cleanup"
rm -f "$MNT/$INSTALLER"

# Unmount everything
cleanup

echo ""
echo "Installation was successful. You may use the USB when ready."

# Log the successful logging
touch install.log
echo "Installation to $DEVICE was successful. You may use the USB when ready." >> install.log

