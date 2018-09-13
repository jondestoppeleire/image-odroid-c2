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

# Enable errexit option (exit script on error of any command)
set -e
[ -n "${DEBUG}" ] && set -x

image_file=$1
partition_number=$2

usage() {
    echo "Resize the file system in a disk image."
    echo
    echo "Usage: $0 image_file parition_number"
    echo
    echo "  image_file - an image containing disk partitions."
    echo "  partition_number - the partition number in the image to resize."
    echo
    exit 1
}

if [ ! -e "${image_file}" ]; then
    echo "image_file '${image_file}' not found."
    usage
fi

if ! fdisk -l "${image_file}" > /dev/null 2>&1; then
    echo "System fdisk command does not support '-l' option.  Are you running Linux?"
    exit 1
fi

partition_count=$(fdisk -l "${image_file}" | grep -c "${image_file}[[:digit:]+]")
if [ "${partition_number}" -gt "${partition_count}" ]; then
    echo "Requested resize of partition # ${partition_number} is larger than"
    echo "number of partitions found (${partition_count}) in ${image_file}."
    exit 1
fi

# Expand the file.  This happens to make the last partition of the image larger.
# 2781872128 is the size of the file after expansion, figured out manually.
readonly image_file_size=$(wc -c "${image_file}" | cut -f 1 -d ' ')
if [ "${image_file_size}" -lt 2781872128 ]; then
    # yes, you can grow file size with truncate.
    truncate --size=+1G "${image_file}"
fi

# Expand the file system.

# find first available loop device.
loop_device=$(losetup -f)

# Define a cleanup in case the script errs out.
cleanup() {
    [ -n "${DEBUG}" ] && echo "cleanup called."

    # Find all loop devices assocated with the file
    # Use the first field in the output (cut)
    # Replace the last character ("/dev/loop0:") with nothing (sed)
    # disassociate all the devices
    active_devices=$(losetup -j "${image_file}" | cut -d' ' -f1 | sed 's/.$//')
    for active_device in $active_devices; do
        losetup -d "${active_device}"
    done
}
# cleanup will run when the script exits or if user kills the script.
trap cleanup EXIT SIGINT SIGQUIT

# Attached the image file to the loop device.
losetup "${loop_device}" "${image_file}"

# tell the OS there's a new device and partitions.
partprobe "${loop_device}"

# Expand partition $partition_number to the rest of the file.
parted "${loop_device}" -s -- resizepart "${partition_number}" 100%

# Force a file system check and expand the file system.
# Typing the commands look like this:
# `e2fsck -f /dev/loop0p2`
e2fsck -f "${loop_device}p${partition_number}"
resize2fs "${loop_device}p${partition_number}"

# Tell the kernel to reread partition info of the loop device since we changed
# the size of the partition.
partprobe "${loop_device}"

# done - cleanup should be invoked due to the trap.
exit
