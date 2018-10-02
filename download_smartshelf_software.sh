#!/bin/bash
#
# Downloads the fw-smartshelf dependecies and deployables.
#

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

workspace="$1"
if [ ! -d "${workspace}" ]; then
    echo "The specified workspace directory ${workspace} does not exist!"
    usage
fi

readonly nodejs_url=https://deb.nodesource.com/setup_6.x
# download nodejs
if ! curl -sL -o "${workspace}/nodejs6x.sh" ${nodejs_url}; then
    echo "Error downloading nodejs from ${nodejs_url}"
    exit 1
fi

# Nothing to see here yet!
echo "TODO: download the fw-smartshelf package from S3."
