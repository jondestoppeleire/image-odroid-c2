#!/bin/bash
#
# Install software for the odroid-c2.
# This contains base system configuration.

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
# avoids all the `cp` statements of other build-install scripts by mirroring
# the directory structure and replacing all the files.
cp -Rv base-files/base-system/* "${rootfs_dir}/"

# set time to UTC
chroot "${rootfs_dir}" rm -f /etc/localtime
chroot "${rootfs_dir}" ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime

# in build-install(s) for other platforms, configuration for interfaces.d are
# not present. In this build, using a preexisting image, there is already
# a reasonable configuration
# cat /etc/network/interfaces.d/eth0

# Use one server key across all display-client devices.
# Set ssh server permissions
chroot "${rootfs_dir}" chmod 600 /etc/ssh/ssh*key
chroot "${rootfs_dir}" chmod 644 /etc/ssh/ssh*key.pub
