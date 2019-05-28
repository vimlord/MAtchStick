#!/bin/sh
# Copyright 2019
# Created by Christopher Hittner and Justin Barish
# All Rights Reserved.

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

DEVICE=$1

CRYPTROOT=/dev/mapper/cryptroot
CRYPTROOT_PASSWD="password"

ROOT_DEVICE="$DEVICE"4
PUBLIC_DEVICE="$DEVICE"1

if [ "$EUID" -ne 0 ]; then
    # Requires root privileges
    echo "$0: Please run as root"
    exit
elif [ $# -eq 0 ]; then
    echo "$0: usage: $0 <device>"
    echo "example: '$0 /dev/sdb'"
    exit
elif [ ! -e $DEVICE ]; then
    echo "$0: Device $DEVICE is not currently detected by the system."
    exit
fi

# Open the encrypted root
echo "Opening encrypted root"
echo "$CRYPTROOT_PASSWD" | cryptsetup open $ROOT_DEVICE cryptroot
if [ $? -ne 0 ]; then
    echo "Failed to open encrypted root device"
    exit
fi

# Mount the root device
mountdev $CRYPTROOT "/mnt"
if [ $? -ne 0 ]; then
    cryptsetup close cryptroot
    exit
else echo ""
fi

# Mount the public device
mountdev $PUBLIC_DEVICE "/mnt/public"
if [ $? -ne 0 ]; then
    unmount /mnt
    cryptsetup close cryptroot
    exit
else echo ""
fi

# Generate the LB (Linux Box) keypair
echo "Performing key generation"
./usrlocbin/makekeypair public_key_lb.pem private_key_lb.pem

# Public key goes to the partition
mv public_key_lb.pem /mnt/public/keys/

# Private key is in the main partition, and is encrypted until boot.
# It is only readable by root.
mkdir -p /mnt/etc/keys
chmod 700 /mnt/etc/keys
mv private_key_lb.pem /mnt/etc/keys/

# Tear down
unmount /mnt/public
unmount /mnt
cryptsetup close cryptroot

echo ""
echo "LB key reset is complete. You may use the USB when ready."

