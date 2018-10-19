#!/bin/bash
#
# Install software for the odroid-c2.
# Mainly geared towards being a display or shelf.

# Enable errexit option (exit script on error of any command)
set -e
[ -n "${DEBUG}" ] && set -x

. setup.sh

if [ ! -d "${rootfs_dir}" ]; then
    echo "The specified chroot directory ${rootfs_dir} does not exist!"
    exit 1
fi

run_install_apt_update() {
    # Add a (the Google) nameserver for apt-get to work
    echo "nameserver 8.8.8.8" | chroot "${rootfs_dir}" tee /etc/resolv.conf

    # ODROID-C2 specific - DO NOT UPGRADE THIS PACKAGE, broken builds!
    chroot "${rootfs_dir}" apt-mark hold bootini
    chroot "${rootfs_dir}" apt-get update

    # This can be split up in the future into multiple steps if
    # different builds for the odroid-c2 are needed.
    # Packages to install later are things like chromium-browser.
    packages=(
        # tools for building/configureing os
        u-boot-tools
        squashfs-tools
        xdotool
        # firmware stuff
        linux-firmware
        wpasupplicant
        acpid
        ifplugd
        # OS tools
        wget
        socat
        openssh-server
        openntpd
        supervisor
        watchdog
        # Display / userland stuff
        ubuntu-standard
        plymouth-theme-ubuntu-logo
        language-pack-en
        xorg
        chromium-browser
        openbox
        unclutter
        imagemagick
        nginx-core
    )

    release_version=$(chroot "${rootfs_dir}" lsb_release -r -s)
    if [ "${release_version}" = "18.04" ]; then
        packages+=(mali-x11)
    else
        # This is good for 16.04, not sure above versions above 18.04.
        packages+=(xserver-xorg-video-mali)
    fi

    chroot "${rootfs_dir}" apt-get install -y --no-install-recommends "${packages[@]}"
    chroot "${rootfs_dir}" apt-get install -y ca-certificates --only-upgrade
}
