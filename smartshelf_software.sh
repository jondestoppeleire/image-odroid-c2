#!/bin/bash
#
# Downloads the fw-smartshelf dependecies and deployables.
#

# Enable errexit option (exit script on error of any command)
set -e
[ -n "${DEBUG}" ] && set -x

. setup.sh

if [ ! -d "${workspace}" ]; then
    echo "The specified workspace directory ${workspace} does not exist!"
    exit 1
fi

if [ ! -d "${rootfs_dir}" ]; then
    echo "The specified chroot directory ${rootfs_dir} does not exist!"
    exit 1
fi

run_download_smartshelf_software() {
    local nodejs_url=https://deb.nodesource.com/setup_6.x
    # download nodejs
    if ! curl -sL -o "${workspace}/nodejs6x.sh" ${nodejs_url}; then
        echo "Error downloading nodejs from ${nodejs_url}"
        exit 1
    fi

    # Nothing to see here yet!
    echo "TODO: download the fw-smartshelf package from S3."
}

run_install_smartshelf_software() {
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
}
