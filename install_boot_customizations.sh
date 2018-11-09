#!/bin/bash
#
# Install software for the odroid-c2.
# This contains eatsa specific things.
# This should be last since it generates a new initrd for boot.

# Enable errexit option (exit script on error of any command)
set -e
[ -n "${DEBUG}" ] && set -x

. setup.sh

if [ ! -d "${rootfs_dir}" ]; then
    echo "The specified chroot directory ${rootfs_dir} does not exist!"
    exit 1
fi

run_install_boot_customizations() {
    # Delete HARDKERNEL customizations
    # This removes running resize2fs on first boot.
    local hardkernel_files=(
        aafirstboot
        .first_boot
    )
    for hk_file in "${hardkernel_files[@]}"; do
        rm -f "${rootfs_dir}/${hk_file}"
    done

    # copy all base files over
    cp -Rv base-files/boot-customization/* "${rootfs_dir}/"

    # use .partition2 as default
    chroot "${rootfs_dir}" cp "/media/boot/boot.ini.partition2" "/media/boot/boot.ini"
    chroot "${rootfs_dir}" cp "/etc/fstab.partition2" "/etc/fstab"

    local plymouth_themes="/usr/share/plymouth/themes"
    chroot "${rootfs_dir}" ln -fs "${plymouth_themes}/eatsa-logo/eatsa-logo.plymouth" /etc/alternatives/default.plymouth

    # not sure if this is used since we're using uboot but not grub
    chroot "${rootfs_dir}" ln -fs "${plymouth_themes}/eatsa-logo/eatsa-logo.grub" /etc/alternatives/default.plymouth.grub
}
