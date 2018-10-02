# This is unused as of Sept. 11, 2018
# The directory layout and this file demonstrates how to make new
# build environments while keeping the existing ones running in parallel.
FROM ubuntu:bionic

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y debootstrap \
    qemu-user-static curl git build-essential gnupg sudo parted dosfstools \
    gnupg udev vim && \
    update-binfmts --enable qemu-aarch64

ENV USER=root \
    HOME=/root \
    DEBIAN_FRONTEND=noninteractive
