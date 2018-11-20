#!/bin/bash
#
# Grows a file system to the size of the disk image.
# Lots of assumptions made specific to odroid-c2 build.
# Called from build.sh
#
# Safe to run multiple times.
#
# Depends on the following utilities:
#   - fdisk with -l option, provided by util-linux package.
#   - grep
#   - losetup
#   - parted
#   - image_utils.sh - custom functions to handle loop devices and mounts.
#

# Enable errexit option (exit script on error of any command)
set -e
[ -n "${DEBUG}" ] && set -x

# Expand the file to the desired size, or fail if the file is larger than the
# desired size.
pt_utils_expand_file() {
    local the_file="$1"
    local desired_size_bytes="$2"
    local image_size_bytes
    image_size_bytes=$(wc -c "${the_file}" | cut -f 1 -d ' ')
    if [ "${image_size_bytes}" -lt "${desired_size_bytes}" ]; then
        local grow_bytes=$((desired_size_bytes - image_size_bytes))
        # grow file size with truncate.
        truncate --size=+${grow_bytes} "${the_file}"
    elif [ "${image_size_bytes}" -eq "${desired_size_bytes}" ]; then
        # image_size_bytes already desired size
        return 0
    else
        echo "${the_file} is ${image_size_bytes}, larger than ${desired_size_bytes}."
        echo "Create a new, smaller file instead of resizing to avoid inadvertent data loss."
        return 1
    fi
}

#####
# Expand the file system.
#####
_expand_filesystem() {
    local loop_device="$1"
    local partition_number="$2"

    # Force a file system check and expand the file system.
    # Typing the commands look like this:
    # `e2fsck -f /dev/loop0p2`
    e2fsck -f "${loop_device}p${partition_number}"
    resize2fs "${loop_device}p${partition_number}"

    # Tell the kernel to reread partition info of the loop device since we changed
    # the size of the partition.
    partprobe "${loop_device}"
}

# Assume we're using a base image from hardkernel with 2 partitions, a boot and root.
# Any other setup and we'd need to create all the partitions.
pt_utils_create_partitions() {
    local loop_device="$1"

    if ! fdisk -l "${loop_device}" > /dev/null 2>&1; then
        echo "System fdisk command does not support '-l' option.  Are you running Linux?"
        return 1
    fi

    partition_count=$(fdisk -l "${loop_device}" | grep -c "${loop_device}p[[:digit:]+]")
    if [ "${partition_count}" -eq 4 ]; then
        # assume we've already partitioned the image file correctly
        echo "Image file already has 4 partitions, assuming it's good to go."
        return 0
    fi

    if [ "${partition_count}" -ne 2 ]; then
        echo "Unimplemented build - we currently assume 2 partitions from a hardkernel supplied image."
        echo "Building from scratch is A LOT more work, see Yocto project with meta-odroid layer as example."
        return 1
    fi

    # resize partition 2 - From sector 264192, + 4194304 sectors, - 1 for end of sector
    # partition 3 - from 4458496s, +4194304s, - 1 for end of sector
    # partition 4 - from 8652800s until end of disk
    parted "${loop_device}" -s -- resizepart 2 4458495s \
      mkpart primary ext2 4458496s 8652799s \
      mkpart primary ext2 8652800s -1s

    partprobe "${loop_device}"

    [ -n "${DEBUG}" ] && fdisk -l "${loop_device}"

    # Rename partitions for our own purposes so we can swap them easily.
    _expand_filesystem "${loop_device}" 2
    e2label "${loop_device}p2" rootfs_p2

    mkfs.ext4 "${loop_device}p3"
    e2label "${loop_device}p3" rootfs_p3

    # create filesystem on partition 4
    mkfs.ext4 "${loop_device}p4"
    e2label "${loop_device}p4" data
}
