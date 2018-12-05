#!/bin/bash
#
# Downloads the fw-smartshelf dependecies and deployables.
#
# This can be removed out of the image build process and into
# the fw-smartshelf build process to match other packages at eatsa.

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

download_node_js() {
    local nodejs_url=https://deb.nodesource.com/setup_6.x
    # download nodejs
    if ! curl -sL -o "${workspace}/nodejs6x.sh" ${nodejs_url}; then
        echo "Error downloading nodejs from ${nodejs_url}"
        return 1
    fi
}

install_nodejs() {
    # Install node JS
    if [ ! -e "${workspace}/nodejs6x.sh" ]; then
        echo "NodeJS installation script not found at ${workspace}/nodejs6x.sh, did download_smartshelf_software.sh complete successfully?"
        return 1
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

download_fw_smartshelf() {
    # the process_controller suffix is: ${TRAVIS_BRANCH}-${TRAVIS_BUILD_NUMBER}
    # see https://github.com/Keenwawa/fw-smartshelf/blob/sbux-quad/Makefile#L22
    local process_controller_file_suffix="$1"
    local fw_smartshelf_url="https://s3.amazonaws.com/eatsa-artifacts/fw-smartshelf/process_controller-${process_controller_file_suffix}.tgz"

    if ! curl -sL -o "${workspace}/process_controller-${process_controller_file_suffix}.tgz" "${fw_smartshelf_url}"; then
        echo "Error downloading from ${fw_smartshelf_url}."
        return 1
    fi
}

install_fw_smartshelf_artifact() {
    local process_controller_name="process_controller-${process_controller_file_suffix}.tgz"
    if [ ! -e "${workspace}/${process_controller_name}" ]; then
        echo "fw-smartshelf's process_controller.tgz artifact not found in ${workspace}."
        return 1
    fi

    # See https://docs.google.com/document/d/1uPeRP4Cbg6vSko7a4AAeiJv6IKy8-14JlFm7Z9u6OyQ/edit?ts=5ba484f3
    # Installing into the directory as in the google doc above.
    # The only difference is that the google doc uses the 'odroid' user but we use the eatsa user in eatsa builds.
    local install_dir="/home/eatsa/Documents/Smartshelf"
    mkdir -p "${rootfs_dir}/tmp"
    cp "${workspace}/${process_controller_name}" "${rootfs_dir}/tmp/${process_controller_name}"
    chroot "${rootfs_dir}" mkdir -p "${install_dir}"
    chroot "${rootfs_dir}" tar -xzvf "/tmp/${process_controller_name}" -C "${install_dir}"

    # cleanup and make sure eatsa user has permissions to the directories just created.
    chroot "${rootfs_dir}" chown -R eatsa:eatsa "${install_dir}"

    # What is npm config set unsafe-perm?
    # When running `npm install` in a docker container, we get the error `npm ERR! Cannot read property 'uid' of undefined`.
    # setting unsafe-perm fixes that.
    chroot "${rootfs_dir}" /bin/bash -c "cd ${install_dir} && npm config set unsafe-perm true && npm install"
}

# Takes the fw_smartshelf javascript artifact version as only argument.
run_download_smartshelf_software() {
    local process_controller_file_suffix="$1"
    download_node_js
    download_fw_smartshelf "${process_controller_file_suffix}"
}

run_install_smartshelf_software() {
    local process_controller_file_suffix="$1"
    install_nodejs
    install_fw_smartshelf_artifact "${process_controller_file_suffix}"
}
