#!/bin/bash
#
# Install software for the smartshelf.
#
# In order to decouple smartshelf from a generic odroid-c2 setup,
# the base image can be built and uploaded to S3.
# Then, this script or smartshelf-odroid-c2 build project will download that
# base image, do all the losetup/mount stuff, then just run this script.

# Enable errexit option (exit script on error of any command)
set -e
[ -n "${DEBUG}" ] && set -x

usage() {
    echo "Install software for the odroid-c2 for eatsa's uses."
    echo "Assumes that a rootfs already exists and mounts are setup."
    echo
    echo "Usage: $0 workspace_dir rootfs_dir"
    echo
    echo "  workspace_dir - the workspace directory of files being manipulated are stored."
    echo "  rootfs_dir - a directory to chroot into"
    echo
    exit 1
}

workspace="$1"
if [ ! -d "${workspace}" ]; then
    echo "The specified workspace directory ${workspace} does not exist!"
    usage
fi

rootfs_dir="$2"
if [ ! -d "${rootfs_dir}" ]; then
    echo "The specified chroot directory ${rootfs_dir} does not exist!"
    usage
fi

# Install node JS
if [ ! -e "${workspace}/nodejs6x.sh" ]; then
    echo "NodeJS installation script not found at ${workspace}/nodejs6x.sh, did download_smartshelf_software.sh complete successfully?"
    exit 1
fi

# Copy the installation script into the chroot
mkdir -p "${rootfs_dir}/tmp"
cp "${workspace}/nodejs6x.sh" "${rootfs_dir}/tmp/nodejs6x.sh"
chroot "${rootfs_dir}" chmod 755 /tmp/nodejs6x.sh
# the script runs 'apt-get update'
chroot "${rootfs_dir}" ./tmp/nodejs6x.sh
chroot "${rootfs_dir}" apt-get install -y nodejs
chroot "${rootfs_dir}" rm -f /tmp/nodejs6x.sh
