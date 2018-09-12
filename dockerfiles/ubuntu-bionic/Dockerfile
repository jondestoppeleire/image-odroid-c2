# This is unused as of Sept. 11, 2018
# However, it's just an example of how to build new OS environments.
FROM ubuntu:bionic

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y debootstrap \
    qemu-user-static curl git build-essential gnupg sudo parted dosfstools gnupg udev

ENV USER=root \
    HOME=/root \
    DEBIAN_FRONTEND=noninteractive
