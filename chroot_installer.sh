#!/bin/sh
# Copyright 2019
# Created by Christopher Hittner and Justin Barish
# All Rights Reserved.

DEVICE=$1

install () {
    echo "The following will be installed: $@"
    pacman -S --noconfirm $@
    pacman -Scc --noconfirm
}

uninstall () {
    echo "Removing the following: $@"
    pacman -Rs $@
}

HOSTNAME=exam


echo "Setting time"
ln -sf /usr/share/zoneinfo/America/NewYork /etc/localtime
hwclock --systohc

echo "Generating locale"
locale-gen
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "Setting up hostname to be $HOSTNAME"
echo $HOSTNAME > /etc/hostname

echo "127.0.0.1	$HOSTNAME" > /etc/hosts
echo "::1		$HOSTNAME" >> /etc/hosts
echo "127.0.1.1	$HOSTNAME.localdomain	$HOSTNAME" >> /etc/hosts

echo "Creating student user"
useradd -m student

echo "Setting root password for device to be a random password"
ROOT_PASSWD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-1024})
echo "root:$ROOT_PASSWD" | chpasswd

echo "Setting student password for device to be a random password"
USER_PASSWD=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-1024})
echo "student:$USER_PASSWD" | chpasswd

# Encrpytion changes
# First, GRUB must be configured
ROOT_UUID=$(lsblk -no UUID "$DEVICE"4 | head -n 1)
CROOT_UUID=$(lsblk -no UUID "$DEVICE"4 | tail -n 1)

# Enable encryption
sed -i "s/#GRUB_ENABLE_CRYPTODISK/GRUB_ENABLE_CRYPTODISK/g" /etc/default/grub
# Use cryptroot
sed -i "s/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$ROOT_UUID:cryptroot\"/g" /etc/default/grub

# initramfs
mkinitcpio -p linux

echo "Installing GRUB"
grub-install --target=x86_64-efi --boot-directory=/boot --efi-directory=/boot/efi --removable --recheck

echo "Generating GRUB config at /boot/grub/grub.cfg"
grub-mkconfig -o /boot/grub/grub.cfg

echo "Generating GRUB config at /boot/efi/EFI/arch/grub.cfg"
mkdir -p /boot/efi/EFI/arch
grub-mkconfig -o /boot/efi/EFI/arch/grub.cfg

echo "Adding disk read optimizations"
echo "[Journal]" > /etc/systemd/journald.conf.d/usbstick.conf
echo "Storage=volatile" >> /etc/systemd/journald.conf.d/usbstick.conf
echo "RuntimeMaxUse=30M" >> /etc/systemd/journald.conf.d/usbstick.conf

echo "Setting up desktop environment"
install xfce4 lightdm lightdm-gtk-greeter xorg-server ttf-dejavu midori

# Set wallpaper
mv /wallpaper.jpg /usr/share/backgrounds/xfce/xfce-teal.jpg

# Enable lightdm.service so the GUI loads
systemctl enable lightdm.service
if [ $? -eq 0 ]; then
    echo "Activation of desktop environment was successful"
else
    echo "Upon attempting to activate display manager, nonzero error code was returned"
fi

# Provide JDK
echo "Setting up programming tools"
VRSN=8
echo "Including Java $VRSN"
install jre$VRSN-openjdk jdk$VRSN-openjdk openjdk$VRSN-doc junit
echo "Including Python"
install python

# Setup PAM configuration
echo "Installing PAM module"

# Install the custom PAM
cd /pamdata
make pam
# Enable the custom PAM
mv system-auth /etc/pam.d/
# Delete the PAM installation files
cd /
rm -rf pamdata

# Modify the student's bashrc to include the submission macro
echo "alias submit='sudo submit-assignment'" >> /home/student/.bashrc

# Add a informative print to the bashrc
echo 'echo "Welcome $USER!"' >> /home/student/.bashrc
echo 'echo "Copyright 2019 Christopher Hittner and Justin Barish. All Rights Reserved."' >> /home/student/.bashrc

# Create a custom script for opening javadocs
mkdir -p /home/student/Desktop
echo 'midori /usr/share/doc/java-openjdk8/api/overview-summary.html' >> /home/student/Desktop/open-javadoc.sh
chmod +x /home/student/Desktop/open-javadoc.sh

# Establish defaults
cp /home/student/.bashrc /etc/default
cp -r /etc/default/.emacs.d /home/student/
cp /home/student/Desktop/open-javadoc.sh /etc/default

# Delete self
rm /chroot_installer.sh

echo "Drive setup is now complete. Exiting from device"

