#!/bin/bash
#
# Install software for the odroid-c2.
# This contains eatsa specific things.

# Enable errexit option (exit script on error of any command)
set -e
[ -n "${DEBUG}" ] && set -x

usage() {
    echo "Install software for the odroid-c2 for eatsa's uses."
    echo
    echo "Usage: $0 rootfs_dir"
    echo
    echo "  rootfs_dir - the directory containing the root file system"
    echo
    exit 1
}

rootfs_dir="$1"
if [ ! -d "${rootfs_dir}" ]; then
    echo "Expected a directory at ${rootfs_dir}"
    usage
fi

# copy all base files over
# avoids all the `cp` statements of other build-install scripts by mirroring
# the directory structure and replacing all the files.
cp -Rv display-config/* "${rootfs_dir}/"

# Delete the eatsa user if it already exists.
# Ignore the delete error if the user doesn't exist.
chroot "${rootfs_dir}" rm -rf /home/eatsa
chroot "${rootfs_dir}" userdel eatsa 2>/dev/null || true
chroot "${rootfs_dir}" useradd -m -s /bin/bash eatsa
echo "eatsa:$EATSAPASS" | chroot "${rootfs_dir}" chpasswd

# Add eatsa to the video group in order to access /dev/fb0 for graphics.
chroot "${rootfs_dir}" usermod -a -G video eatsa

# copy eatsa_stores SSH pub key to eatsa user directory
chroot "${rootfs_dir}" mkdir -p /home/eatsa/.ssh
chroot "${rootfs_dir}" chown -R eatsa:eatsa /home/eatsa/.ssh

# set time to UTC
chroot "${rootfs_dir}" rm -f /etc/localtime
chroot "${rootfs_dir}" ln -s /usr/share/zoneinfo/Etc/UTC /etc/localtime

# in build-install(s) for other platforms, configuration for interfaces.d are
# not present. In this build, using a preexisting image, there is already
# a reasonable configuration
# cat /etc/network/interfaces.d/eth0
