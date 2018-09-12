#!/bin/bash
#
# This script configures the host machine with anything
# necessary for the package build
#
# Note that this script does NOT use build-framework.

if apt-get --version > /dev/null 2>&1; then
    sudo apt-get install -y squashfs-tools xorriso genisoimage \
     qemu-user-static parted dosfstools binfmt-support debootstrap xz-utils
else
    echo "Cannot find apt-get program. Does your system support it?"
    exit 1
fi
