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
    echo "Usage: $0 rootfs"
    echo
    echo "  rootfs - the directory containing the root file system"
    echo
    exit 1
}

rootfs="$1"
if [ ! -d "${rootfs}" ]; then
    echo "Expected a directory at ${rootfs}"
    usage
fi

# copy all base files over
cp -Rv display-config/* "${rootfs}/"

# Delete the eatsa user if it already exists. Ignore the delete error if the user doesn't exist.
chroot "${rootfs}" rm -rf /home/eatsa
chroot "${rootfs}" userdel eatsa 2>/dev/null || true
chroot "${rootfs}" useradd -m -s /bin/bash eatsa
echo "eatsa:$EATSAPASS" | chroot "${rootfs}" chpasswd

# Add eatsa to the video group in order to access /dev/fb0 for graphics.
chroot "${rootfs}" usermod -a -G video eatsa

# copy eatsa_stores SSH pub key to eatsa user directory
chroot "${rootfs}" mkdir -p /home/eatsa/.ssh
chroot "${rootfs}" chown -R eatsa:eatsa /home/eatsa/.ssh
