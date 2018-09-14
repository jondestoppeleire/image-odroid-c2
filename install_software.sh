#!/bin/bash
#
# Install software for the odroid-c2.
# Mainly geared towards being a display or shelf.

# Enable errexit option (exit script on error of any command)
set -e
[ -n "${DEBUG}" ] && set -x

usage() {
    echo "Install software for the odroid-c2 for eatsa's uses."
    echo
    echo "Usage: $0 image_file workspace"
    echo
    echo "  image_file - an image containing disk partitions."
    echo "  workspace  - the directory to do rootfs work"
    echo
    exit 1
}

image_file="$1"
if [ ! -e "${image_file}" ]; then
    echo "image_file '${image_file}' not found."
    usage
fi

workspace="$2"
if [ -z "${workspace}" ]; then
    workspace="$PWD"
fi

if [ ! -d "${workspace}" ]; then
    echo "Workspace directory ${workspace} does not exist!"
    exit 1
fi

# Define globals common throughout this script.
readonly rootfs_dir="${workspace}/rootfs"
readonly boot_partition_mount="${rootfs_dir}/media/boot"

# import
. ./image_utils.sh

# Mount the image's partitions and write to them.

# find first available loop device.
loop_device=$(losetup -f)

# use image_utils.sh functions that has auto cleanup
with_loop_device "${loop_device}" "${image_file}"

with_mount "${loop_device}p2" "${rootfs_dir}"
with_mount "${loop_device}p1" "${boot_partition_mount}"

with_chroot_mount "${rootfs_dir}" proc /proc
with_chroot_mount "${rootfs_dir}" sysfs /sys
with_chroot_mount "${rootfs_dir}" devpts /dev/pts

temp_disable_invoke_rc_d "${rootfs_dir}"

# Add a (the Google) nameserver for apt-get to work
echo "nameserver 8.8.8.8" | chroot "${rootfs_dir}" tee /etc/resolv.conf

# ODROID-C2 specific - DO NOT UPGRADE THIS PACKAGE, broken builds!
chroot "${rootfs_dir}" apt-mark hold bootini
chroot "${rootfs_dir}" apt-get update

# This can be split up in the future into multiple steps if
# different builds for the odroid-c2 are needed.
# Packages to install later are things like chromium-browser.
packages=(
    ubuntu-standard
    language-pack-en
    xorg
    chromium-browser
    u-boot-tools
    linux-firmware
    wpasupplicant
    squashfs-tools
    openbox
    unclutter
    xdotool
    socat
    imagemagick
    openssh-server
    openntpd
    supervisor
    acpid
    ifplugd
    nginx-core
    plymouth-theme-ubuntu-logo
)

chroot "${rootfs_dir}" apt-get install -y --no-install-recommends "${packages[@]}"
chroot "${rootfs_dir}" apt-get install -y ca-certificates --only-upgrade

./install_eatsa.sh "${rootfs_dir}"
# cleanup invoked.
exit
