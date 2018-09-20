#!/bin/bash
#
# Install software for the odroid-c2.
# Mainly geared towards being a display or shelf.

# Enable errexit option (exit script on error of any command)
set -e
[ -n "${DEBUG}" ] && set -x

usage() {
    echo "Install software for the odroid-c2 for eatsa's uses."
    echo "Assumes that a rootfs already exists."
    echo
    echo "Usage: $0 rootfs_dir"
    echo
    echo "  rootfs_dir - a directory to chroot into"
    echo
    exit 1
}

rootfs_dir="$1"
if [ ! -d "${rootfs_dir}" ]; then
    echo "Workspace directory ${rootfs_dir} does not exist!"
    exit 1
fi

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

# cleanup invoked.
exit
