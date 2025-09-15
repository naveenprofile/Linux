#!/bin/bash

VOLUME_PATH="/dev/my_vg/my_lv"
REDUCED_SIZE="8G"
MOUNT_POINT="/mnt/mydata"


# Unmount the logical volume
echo "Unmounting $MOUNT_POINT"
sudo umount $MOUNT_POINT

# Check the filesystem for errors
echo "Checking filesystem on $VOLUME_PATH"
sudo e2fsck -f $VOLUME_PATH

# Resize the filesystem to $REDUCED_SIZE
echo "Resizing filesystem to ..."
sudo resize2fs $VOLUME_PATH $REDUCED_SIZE

# Reduce the logical volume size
echo "Reducing logical volume to $REDUCED_SIZE..."
sudo lvreduce -L $REDUCED_SIZE $VOLUME_PATH -y

# Remount the logical volume
echo "Remounting $VOLUME_PATH to $MOUNT_POINT..."
sudo mount /dev/my_vg/my_lv #MOUNT_POINT

# Display final volume size
echo "Final volume size:"
sudo lvdisplay $VOLUME_PATH
