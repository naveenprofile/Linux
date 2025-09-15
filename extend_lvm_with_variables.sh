#!/bin/bash

# Variables
VOLUME_PATH="/dev/my_vg/my_lv"
EXTEND_SIZE="+5G"
FS_TYPE="ext4"

# Extend the logical volume
sudo lvextend -L $EXTEND_SIZE $VOLUME_PATH

# Resize the filesystem
if [ "$FS_TYPE" == "ext4" ]; then
    sudo resize2fs $VOLUME_PATH
elif [ "$FS_TYPE" == "xfs" ]; then
    sudo xfs_growfs $VOLUME_PATH
else
    echo "Unsupported filesystem type: $FS_TYPE"
    exit 1
fi

echo "Logical volume $VOLUME_PATH has been extended by $EXTEND_SIZE and resized for $FS_TYPE filesystem."
