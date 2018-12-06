#!/bin/bash
#
# build the odroid-c2 os image.
#
# The general steps in building any os image should be:
# 1. produce a root filesystem
#   * This is normally done using a tool like `debootstrap`.
#   * In this build, we use an already built os image and extract the root
#     filesystem out of it since it avoids downloading source code and
#     and cross compiling everything.
#   * Use Yocto or Buildroot to build a root filesystem.
#
# 2. Create an image file
#   * Generally, create a blank image file.
#   * Write a MBR/GPT (mount blank image on a loop device and fdisk it)
#     * We create 4 paritions here: BOOT, /data, and two partitions for the
#       root filesystems.  /data will store which root filesystem is active.
#     * We don't create more than 4 partitions to keep it simple and not need
#       to use extended partitions.
#   * dd the boot loader
#   * create a boot partition
#   * dd the root filesystem onto a partition of the blank image file
#
# Not using build-framework to simplify reading and comprehension.
#
# Environment variables:
#
#  * DEBUG
#      - Set this to any value to print out debug information, empty to unset.
#  * SKIP_FULL_IMAGE_DIST
#      - set this to any value to skip producing a full image as it takes a
#        a long time for xz to compress and dump the image in ./dist.  Useful
#        when debugging or only caring about netboot portion during development.

# exit script on command failure not explicitly caught
set -e
[ -n "${DEBUG}" ] && set -x

# source common variables / configuration
. setup.sh

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
    if [ ! -e "${work_image}" ] && [ ! -e "${work_output_image}" ]; then
        xz --verbose --decompress --keep "${work_image_xz}"
    fi
fi

# ${work_image} already exists (original file decompressed by xz),
# rename it to the working image. This makes it less confusing if the extracted
# file was tampered with or freshly decompressed.
if [ ! -e "${work_output_image}" ]; then
    mv "${work_image}" "${work_output_image}"
fi

# Download required software before doing time expensive operations.
# Extract this out to make this project more generic for other purposes.
# $fw_smartshelf_version is defined in ./setup.sh
. smartshelf_software.sh
run_download_smartshelf_software "${fw_smartshelf_version}"

# import
. image_utils.sh
. partition_utils.sh

# Grow the disk image before attaching it to a loop device, otherwise the
# file size changes won't be reflected when already attached to loop device.
#
# https://wiki.odroid.com/odroid-c2/software/partition_table
# BL1 / MBR : sector 0 to 96, sector=512 bytes
# u-boot    : sector 97 to 1503, sector=512 bytes
# BOOT      : sector 2048 to 264191, total bytes so far = 264192*512=135266304
# ROOT1     : 2G = 2147483648 bytes, = 4194304 sectors
# ROOT2     : 2G = 2147483648 bytes
# DATA      : 2G = 2147483648 bytes
# Total size = 3 * 2147483648 = 6442450944 bytes
pt_utils_expand_file "${work_output_image}" 6442450944

# Mount the image's partitions and write to them.

# find first available loop device.
loop_device=$(losetup -f)

# use image_utils.sh functions that has auto cleanup
with_loop_device "${loop_device}" "${work_output_image}"

# Create partitions needed for Dual Copy upgrade scheme.
pt_utils_create_partitions "${loop_device}"

# image_utils.sh - mounts the partitions and auto umount when script exits.
with_mount "${loop_device}p2" "${rootfs_dir}"
with_mount "${loop_device}p1" "${boot_partition_mount}"

with_chroot_mount "${rootfs_dir}" proc /proc
with_chroot_mount "${rootfs_dir}" sysfs /sys
with_chroot_mount "${rootfs_dir}" devpts /dev/pts

temp_disable_invoke_rc_d "${rootfs_dir}"

# chroot and install software
. install_apt_update.sh
[ -z "${SKIP_APT_UPDATE}" ] && run_install_apt_update

. install_base_system.sh
run_install_base_system

# remember to call update_uInitrd boot_customizations are made.
. install_boot_customizations.sh
run_install_boot_customizations

. install_eatsa_user.sh
run_install_eatsa_user

# Install smartshelf software, from smartshelf_software.sh
run_install_smartshelf_software "${fw_smartshelf_version}"

# Write version file to partitions
echo "${dist_version}" > "${workspace}/version.txt"
cp -v "${workspace}/version.txt" "${rootfs_dir}/version.txt"
cp -v "${workspace}/version.txt" "${boot_partition_mount}/version.txt"

# copy over upgrade and other control scripts.
cp -Rv base-files/supervisor-scripts/* "${rootfs_dir}/"

# Generate new initrd to capture changes from everything above.
# Remove unused kernels
readonly removable_kernels=$(chroot "${rootfs_dir}" dpkg -l linux-image-\* | grep ^rc | awk '{ print $2 }')
if [ -n "${removable_kernels}" ]; then
    echo "${removable_kernels[@]}" | xargs chroot "${rootfs_dir}" dpkg --purge
fi

# Function used as in development code, we needed to run this section multiple times.
update_uInitrd() {
    # Find the kernel version that's installed
    # bash-fu breakdown:
    #   $ dpkg --get-selections | grep "linux-image-[[:digit]].*"
    #   linux-image-3.14.79-116				install
    local installed_kernel_package
    installed_kernel_package=$(chroot "${rootfs_dir}" dpkg --get-selections | grep "linux-image-[[:digit:]].*")

    # Get the first column and remove the "linux-image-" prefix
    local kernel_version
    kernel_version=$(echo "${installed_kernel_package}" | awk '{ print $1 }' | sed 's/linux-image-//')

    # register update-initramfs -u so that it's only run once.
    chroot "${rootfs_dir}" update-initramfs -u

    # create the uInitrd, U-boot
    chroot "${rootfs_dir}" mkimage -A arm64 -O linux -T ramdisk -C none -a 0 -e 0 -n initramfs \
        -d "/boot/initrd.img-${kernel_version}" "/boot/uInitrd-${kernel_version}"

    # overwrite initrd in boot partition with one just generated.
    cp -v "${rootfs_dir}/boot/uInitrd-${kernel_version}" "${boot_partition_mount}/uInitrd"
}

update_uInitrd

# clean up
# As defined in wise-display/build-scripts/build-install
chroot "${rootfs_dir}" apt-get remove -y linux-firmware
chroot "${rootfs_dir}" apt-get autoremove -y
rm -rf "${rootfs_dir}"/usr/share/locale/*
rm -rf "${rootfs_dir}"/usr/share/man/*

rm -rf "${rootfs_dir}"/var/cache/apt/*
rm -rf "${rootfs_dir}"/var/cache/debconf/*
rm -rf "${rootfs_dir}"/var/cache/man/*
rm -rf "${rootfs_dir}"/var/lib/apt/lists/*
rm -rf "${rootfs_dir}"/var/tmp/*
rm -rf "${rootfs_dir}"/usr/share/doc/*
rm -rf "${rootfs_dir}"/usr/share/icons/*

# https://linux.die.net/man/8/sync
# sync writes any data buffered in memory out to disk.
sync

# create a squashfs image before unmounting
# This code needs to move into a netboot creation step
cleanup_chroot_mount "${rootfs_dir}" /dev/pts
cleanup_chroot_mount "${rootfs_dir}" /sys
cleanup_chroot_mount "${rootfs_dir}" /proc
cleanup_mount "${boot_partition_mount}"

mksquashfs "${rootfs_dir}" "${workspace}/${output_filesystem_file}.squashfs" -b 4096
