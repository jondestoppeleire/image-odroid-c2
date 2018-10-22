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

. setup.sh

_check_args() {
    local partition_number="$1"

    if ! fdisk -l "${work_output_image}" > /dev/null 2>&1; then
        echo "System fdisk command does not support '-l' option.  Are you running Linux?"
        return 1
    fi

    if [ -z "${partition_number}" ]; then
        echo "Partition number not specified."
        return 1
    fi

    partition_count=$(fdisk -l "${work_output_image}" | grep -c "${work_output_image}[[:digit:]+]")
    if [ "${partition_number}" -gt "${partition_count}" ]; then
        echo "Requested resize of partition # ${partition_number} is larger than"
        echo "number of partitions found (${partition_count}) in ${work_output_image}."
        return 1
    fi
}

# Expand the file.  This happens to make the last partition of the image larger.
# 2781872128 is the size of the file after expansion, figured out manually.
run_expand_file() {
    local image_file_size
    image_file_size=$(wc -c "${work_output_image}" | cut -f 1 -d ' ')
    if [ "${image_file_size}" -lt 2781872128 ]; then
        # yes, you can grow file size with truncate.
        truncate --size=+1G "${work_output_image}"
    fi
}

#####
# Expand the file system.
#####
_expand_filesystem() {
    local loop_device="$1"
    local partition_number="$2"

    # Expand partition $partition_number to the rest of the file.
    partprobe "${loop_device}"
    parted "${loop_device}" -s -- resizepart "${partition_number}" 100%
    [ -n "${DEBUG}" ] && fdisk -l "${loop_device}"

    # Force a file system check and expand the file system.
    # Typing the commands look like this:
    # `e2fsck -f /dev/loop0p2`
    e2fsck -f "${loop_device}p${partition_number}"
    resize2fs "${loop_device}p${partition_number}"

    # Tell the kernel to reread partition info of the loop device since we changed
    # the size of the partition.
    partprobe "${loop_device}"
}

run_resize_partition() {
    local loop_device="$1"
    local partition_number="$2"

    _check_args "${partition_number}"
    _expand_filesystem "${loop_device}" "${partition_number}"
}
