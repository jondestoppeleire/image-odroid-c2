#!/bin/bash
#
# This script configures the host machine with anything
# necessary for the package build
#
# Note that this script does NOT use build-framework.

if apt-get -h > /dev/null 2>&1; then
    sudo apt-get install -y squashfs-tools xorriso genisoimage \
     qemu-user-static parted dosfstools binfmt-support debootstrap xz-utils
else
    echo "Cannot find apt-get program. Does your system support it?"
    exit 1
fi

# Depends on shellcheck 0.4.0+; the apt-get version is at an old 0.3.3
# https://manpages.debian.org/wheezy/dpkg-dev/deb-version.5.en.html
# https://sources.debian.org/src/dpkg/1.19.1/lib/dpkg/version.c/
#readonly deb_version=$(sudo apt-cache show shellcheck | awk '{ pring $2 }')
readonly shellcheck_version=0.4.6

is_compatible_version() {
    dpkg --compare-versions "$1" ge "${shellcheck_version}"
    return $?
}

install_shellcheck() {
    # scversion picked to match travis:
    # https://docs.travis-ci.com/user/build-environment-updates/
    # https://docs.travis-ci.com/user/build-environment-updates/2017-09-06/#changed
    readonly scversion="v${shellcheck_version}"
    curl -LSs "https://shellcheck.storage.googleapis.com/shellcheck-${scversion}.linux.x86_64.tar.xz" -o "/tmp/shellcheck-${scversion}.tar.xz"
    tar --xz -xvf "/tmp/shellcheck-${scversion}.tar.xz" -C /tmp
    sudo install "/tmp/shellcheck-${scversion}/shellcheck" /usr/local/bin
    /usr/local/bin/shellcheck --version
}

if shellcheck --version > /dev/null 2>&1; then
    deb_ver=$(shellcheck --version | grep -i version: | awk '{ print $2 }')
    if ! is_compatible_version "${deb_ver}"; then
        echo "Found an old version of shellcheck, removing and installing a later version."
        sudo apt-get remove -y shellcheck && install_shellcheck
    else
        echo "Compatible version of shellcheck already installed."
    fi
else
    # not installed, install a compatible version, choosing an apt version over manual install
    deb_ver=$(sudo apt-cache show shellcheck | grep -i version: | awk '{ print $2 }')
    if is_compatible_version "${deb_ver}"; then
        echo "Installing shellcheck from apt."
        sudo apt-get install shellcheck
    else
        echo "Installing a newer version of shellcheck than available in apt."
        install_shellcheck
    fi
fi
