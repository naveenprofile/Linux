#!/bin/bash

DISK="/dev/sdb"
VG_NAME="my_vg"
LV_NAME="my_lv"
LV_SIZE="10G"
MOUNT_POINT="/mnt/mydata"
FS_TYPE="ext4"

# Create Physical Volume
sudo pvcreate $DISK
# Create Volume Group
sudo vgcreate $VG_NAME $DISK

# Create Logical Volume
sudo lvcreate -L 10G -n $LV_NAME $VG_NAME

# Format the Logical Volume
sudo mkfs.ext4 /dev/my_vg/my_lv

# Create Mount Point
sudo mkdir -p $MOUNT_POINT

# Mount the Logical Volume
sudo mount /dev/my_vg/my_lv $MOUNT_POINT

# Display the result
echo "LVM setup complete:"
lsblk
