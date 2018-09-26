FROM ubuntu:xenial

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y debootstrap \
    qemu-user-static curl git build-essential gnupg sudo parted dosfstools \
    gnupg udev shellcheck vim && \
    update-binfmts --enable qemu-aarch64

ENV USER=root \
    HOME=/root \
    DEBIAN_FRONTEND=noninteractive
