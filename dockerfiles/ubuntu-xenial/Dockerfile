FROM ubuntu:xenial-20181005

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y debootstrap \
    binfmt-support qemu-user-static curl git build-essential gnupg sudo \
    parted dosfstools squashfs-tools xz-utils udev vim && \
    update-binfmts --enable qemu-aarch64

ENV USER=root \
    HOME=/root \
    DEBIAN_FRONTEND=noninteractive
