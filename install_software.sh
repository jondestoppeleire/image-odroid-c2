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
    echo "Usage: $0 image_file"
    echo
    echo "  image_file - an image containing disk partitions."
    echo
    exit 1
}

image_file=$1
if [ ! -e "${image_file}" ]; then
    echo "image_file '${image_file}' not found."
    usage
fi

# Define globals common throughout this script.
readonly rootfs_dir="rootfs"
readonly boot_partition_mount="${rootfs_dir}/media/boot"
readonly policy_rc_file="/usr/sbin/policy-rc.d"

# Define a cleanup in case the script errs out.
cleanup() {
    [ -n "${DEBUG}" ] && echo "cleanup called."

    chroot "${rootfs_dir}" rm -f "${policy_rc_file}" || true

    # unmount.
    chroot "${rootfs_dir}" umount /proc /sys /dev/pts || true
    mountpoint -q "${boot_partition_mount}" && umount "${boot_partition_mount}"
    mountpoint -q "${rootfs_dir}" && umount "${rootfs_dir}"
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

# Mount the image's partitions and write to them.

# find first available loop device.
loop_device=$(losetup -f)

# Attached the image file to the loop device.
losetup "${loop_device}" "${image_file}"

# tell the OS there's a new device and partitions.
partprobe "${loop_device}"

# Create mount points
mkdir -p "${boot_partition_mount}"

# mount.
mount "${loop_device}p2" "${rootfs_dir}"
mount "${loop_device}p1" "${boot_partition_mount}"

chroot "${rootfs_dir}" mount none -t proc /proc
chroot "${rootfs_dir}" mount none -t sysfs /sys
chroot "${rootfs_dir}" mount none -t devpts /dev/pts

# Add a (the Google) nameserver for apt-get to work
echo "nameserver 8.8.8.8" | chroot "${rootfs_dir}" tee /etc/resolv.conf

# disable starting daemons on pkg install (for buggy pkgs that don't detect chroot)
chroot "${rootfs_dir}" tee "${policy_rc_file}" << _EOF
#!/bin/sh
exit 101
_EOF
chmod a+x "${rootfs_dir}/${policy_rc_file}"

# ODROID-C2 specific - DO NOT UPGRADE THIS PACKAGE, broken builds!
chroot "${rootfs_dir}" apt-mark hold bootini

chroot "${rootfs_dir}" apt-get update

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
