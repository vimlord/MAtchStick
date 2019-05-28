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
    sh install.sh $DEVICE $MOUNT
        
    if [ $? -eq 0 ]; then
        echo "Installed to $DEVICE" >> report.log
    else
        echo "Failed to install to $DEVICE" >> report.log
    fi  

done
