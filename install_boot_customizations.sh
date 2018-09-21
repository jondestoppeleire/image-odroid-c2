#!/bin/bash
#
# Install software for the odroid-c2.
# This contains eatsa specific things.
# This should be last since it generates a new initrd for boot.

# Enable errexit option (exit script on error of any command)
set -e
[ -n "${DEBUG}" ] && set -x

usage() {
    echo "Install software for the odroid-c2 for eatsa's uses."
    echo "Assumes that a rootfs already exists and mounts are setup."
    echo
    echo "Usage: $0 rootfs_dir"
    echo
    echo "  rootfs_dir - a directory to chroot into"
    echo
    exit 1
}

rootfs_dir="$1"
if [ ! -d "${rootfs_dir}" ]; then
    echo "The specified chroot directory ${rootfs_dir} does not exist!"
    usage
fi

# copy all base files over
cp -Rv base-files/boot-customization/* "${rootfs_dir}/"

readonly plymouth_themes="/usr/share/plymouth/themes"
chroot "${rootfs_dir}" update-alternatives --install "${plymouth_themes}/default.plymouth" default.plymouth "${plymouth_themes}/eatsa-logo/eatsa-logo.plymouth" 100
