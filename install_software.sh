#!/bin/bash
#
# Install software for the odroid-c2.
# Mainly geared towards being a display or shelf.

# Enable errexit option (exit script on error of any command)
set -e
[ -n "${DEBUG}" ] && set -x

image_file=$1

usage() {
    echo "Install software for the odroid-c2 for eatsa's uses."
    echo
    echo "Usage: $0 image_file"
    echo
    echo "  image_file - an image containing disk partitions."
    echo
    exit 1
}

if [ ! -e "${image_file}" ]; then
    echo "image_file '${image_file}' not found."
    usage
fi

# Mount the image's partitions and write to them.

# find first available loop device.
loop_device=$(losetup -f)

# Define a cleanup in case the script errs out.
cleanup() {
    [ -n "${DEBUG}" ] && echo "cleanup called."

    chroot rootfs rm -f /usr/sbin/policy-rc.d || true

    # unmount.
    chroot rootfs umount /proc /sys /dev/pts || true
    mountpoint -q rootfs/media/boot && umount rootfs/media/boot
    mountpoint -q rootfs && umount rootfs
    sync

    # Find all loop devices assocated with the file
    # Use the first field in the output (cut)
    # Replace the last character ("/dev/loop0:") with nothing (sed)
    # disassociate all the devices
    active_devices=$(losetup -j "${image_file}" | cut -d' ' -f1 | sed 's/.$//')
    for active_device in $active_devices; do
        losetup -d "${active_device}"
    done
}
# cleanup will run when the script exits or if user kills the script.
trap cleanup EXIT SIGINT SIGQUIT

# Attached the image file to the loop device.
losetup "${loop_device}" "${image_file}"

# tell the OS there's a new device and partitions.
partprobe "${loop_device}"

# Create mount points
mkdir -p rootfs/media/boot

# mount.
mount "${loop_device}p2" rootfs
mount "${loop_device}p1" rootfs/media/boot

chroot rootfs mount none -t proc /proc
chroot rootfs mount none -t sysfs /sys
chroot rootfs mount none -t devpts /dev/pts

# Add a (the Google) nameserver for apt-get to work
echo "nameserver 8.8.8.8" | chroot rootfs tee /etc/resolv.conf

# disable starting daemons on pkg install (for buggy pkgs that don't detect chroot)
chroot rootfs tee /usr/sbin/policy-rc.d << _EOF
#!/bin/sh
exit 101
_EOF
chmod a+x rootfs/usr/sbin/policy-rc.d

# ODROID-C2 specific - DO NOT UPGRADE THIS PACKAGE, broken builds!
chroot rootfs apt-mark hold bootini

chroot rootfs apt-get update

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

chroot rootfs apt-get install -y --no-install-recommends "${packages[@]}"
chroot rootfs apt-get install -y ca-certificates --only-upgrade

# cleanup invoked.
exit
