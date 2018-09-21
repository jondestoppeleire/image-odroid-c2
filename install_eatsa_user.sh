#!/bin/bash
#
# Install software for the odroid-c2.
# This contains eatsa specific things.

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

if [ -z "${EATSAPASS}" ]; then
    echo "Expected a global environmental variable EATSAPASS to be set."
    exit 1
fi

# Delete the eatsa user if it already exists.
# Ignore the delete error if the user doesn't exist.
chroot "${rootfs_dir}" rm -rf /home/eatsa
chroot "${rootfs_dir}" userdel eatsa 2>/dev/null || true

# /home/eatsa should've been created by install_base_system.sh
chroot "${rootfs_dir}" useradd -m -s /bin/bash eatsa
echo "eatsa:$EATSAPASS" | chroot "${rootfs_dir}" chpasswd

# copy all base files over
cp -Rv base-files/eatsa-user/* "${rootfs_dir}/"

# Add eatsa to groups for hardware acceleration. Unsure if complete list.
# https://wiki.odroid.com/odroid-c2/troubleshooting/kodi_hw_acceleration
chroot "${rootfs_dir}" usermod -a -G audio,video,users,plugdev,netdev eatsa

chroot "${rootfs_dir}" mkdir -p /home/eatsa/chromium
chroot "${rootfs_dir}" chown -R eatsa:eatsa /home/eatsa

# autologin configuration, see the file:
# base-files/eatsa-user/etc/systemd/system/getty@tty1.service.d/autologin.conf
chroot "${rootfs_dir}" systemctl enable getty@tty1.service
