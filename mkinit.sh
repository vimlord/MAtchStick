touch report.log

echo "$0 executed @ $(date)"

for v in {c..z};
do
    DEVICE="/dev/sd$v"
    MOUNT="/mnt/$v"
    if [ ! -e $DEVICE ]
    then
        continue
    fi  
    echo "Install to $DEVICE at $MOUNT"
    mkdir $MOUNT

    echo "password" | cryptsetup open $DEVICE cryptroot
    mount /dev/mapper/cryptroot $MOUNT

    cp ./etc/mkinitcpio.conf $MOUNT/etc/
    
    arch-chroot $MOUNT mkinitcpio -p linux

    umount $MOUNT
    cryptsetup close cryptroot

    sh install.sh $DEVICE $MOUNT
        
    if [ $? -eq 0 ]; then
        echo "Ran mkinitcpio on $DEVICE" >> report.log
    else
        echo "Failed to run mkinitcpio to $DEVICE" >> report.log
    fi  

done
