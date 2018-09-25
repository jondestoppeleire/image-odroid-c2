#!/bin/bash
#
# build the odroid-c2 os image.
#
# Not using build-framework to simplify reading and comprehension.

# exit script on command failure not explicitly caught
set -e
[ -n "${DEBUG}" ] && set -x

# GLOBALS
export EATSAPASS="eatsa"
# secret variable SKIP_APT_UPDATE to speed up development.

readonly mydir="$PWD"
readonly workspace="./workspace"
readonly dist="./dist"

mkdir -p "${workspace}"
mkdir -p "${dist}"

# Use a base working ubuntu image for the odroid-c2
# Saved a copy of the image from https://odroid.in/ubuntu_16.04lts/ to S3.
readonly image_file="ubuntu64-16.04.3-minimal-odroid-c2-20171005.img"
readonly image_file_xz="${image_file}.xz"
readonly image_url="https://s3.amazonaws.com/eatsa-artifacts/wise-display/${image_file_xz}"
readonly md5sum_url="${image_url}.md5sum"
readonly output_file="eatsa-ubuntu64-16.04.3-odroid-c2.img"
readonly work_image_xz="${workspace}/${image_file_xz}"
readonly work_image="${workspace}/${image_file}"

# only download the image if it doesn't exist.
# We may already have uncompressed the image file if this is not the first
# run of the script.
if [ ! -e "${work_image_xz}" ]; then
    # -L follow redirects, S show errors, s - silent
    curl -LSs -o "${work_image_xz}" "${image_url}"
fi

# only download the md5sum file if it doesn't exist.
if [ ! -e "${work_image_xz}.md5sum" ]; then
    curl -LSs -o "${work_image_xz}.md5sum" "${md5sum_url}"
fi

# The md5 and extract is only valid when the first time running the script.
if [ -e "${work_image_xz}" ]; then
    pushd "${workspace}"
    md5sum --check "${image_file_xz}.md5sum"
    popd
    if [ ! -e "${work_image}" ]; then
        xz --decompress --keep "${work_image_xz}"
    fi
fi

# Download required software before doing time expensive operations.
# Remove this to make this project more generic.
./download_smartshelf_software.sh "${workspace}"

# Grow the disk image file.
# Expand the the file system to fill the expanded disk size.
# Note: ./resize.sh doesn't seem to work if the loop device is setup outside
# of the script...
./resize.sh "${work_image}" 2

# import
. ./image_utils.sh

# Mount the image's partitions and write to them.

# find first available loop device.
loop_device=$(losetup -f)

# use image_utils.sh functions that has auto cleanup
with_loop_device "${loop_device}" "${work_image}"

readonly rootfs_dir="${workspace}/rootfs"
readonly boot_partition_mount="${rootfs_dir}/media/boot"

# image_utils.sh - mounts the partitions and auto umount when script exits.
with_mount "${loop_device}p2" "${rootfs_dir}"
with_mount "${loop_device}p1" "${boot_partition_mount}"

with_chroot_mount "${rootfs_dir}" proc /proc
with_chroot_mount "${rootfs_dir}" sysfs /sys
with_chroot_mount "${rootfs_dir}" devpts /dev/pts

temp_disable_invoke_rc_d "${rootfs_dir}"

# chroot and install software
[ -z "${SKIP_APT_UPDATE}" ] && ./install_apt_update.sh "${rootfs_dir}"
./install_base_system.sh "${rootfs_dir}"
./install_eatsa_user.sh "${rootfs_dir}"

# call boot customizations last
./install_boot_customizations.sh "${rootfs_dir}"

# Install smartshelf software
./install_smartshelf_software.sh "${workspace}" "${rootfs_dir}"

# Generate new initrd to capture changes from everything above.
# Remove unused kernels
readonly removable_kernels=$(chroot "${rootfs_dir}" dpkg -l linux-image-\* | grep ^rc | awk '{ print $2 }')
if [ -n "${removable_kernels}" ]; then
    echo "${removable_kernels[@]}" | xargs chroot "${rootfs_dir}" dpkg --purge
fi

# Find the kernel version that's installed
# bash-fu breakdown:
#   $ dpkg --get-selections | grep "linux-image-[[:digit]].*"
#   linux-image-3.14.79-116				install
readonly installed_kernel_package=$(chroot "${rootfs_dir}" dpkg --get-selections | grep "linux-image-[[:digit:]].*")

# Get the first column and remove the "linux-image-" prefix
readonly kernel_version=$(echo "${installed_kernel_package}" | awk '{ print $1 }' | sed 's/linux-image-//')

# delete old version if it exists
rm -f "${rootfs_dir}/boot/uInitrd-${kernel_version}"

# register update-initramfs -u so that it's only run once.
chroot "${rootfs_dir}" update-initramfs -u

# create the uInitrd, U-boot
chroot "${rootfs_dir}" mkimage -A arm64 -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs \
    -d "/boot/initrd.img-${kernel_version}" "/boot/uInitrd-${kernel_version}"

# move newly built initrd's to boot partition
rm -f "${boot_partition_mount}/uInitrd"
cp -v "${rootfs_dir}/boot/uInitrd-${kernel_version}" "${boot_partition_mount}/uInitrd"

# Finally, move final product to dist.  Copy if $DEBUG is set.
# Bump version number as well?
#if [ -n "$DEBUG" ]; then
#    cp "${work_image}" "${dist}/${output_file}"
#else
#    mv "${work_image}" "${dist}/${output_file}"
#fi
