FROM ubuntu:xenial

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y debootstrap \
    qemu-user-static curl git build-essential gnupg sudo parted dosfstools gnupg udev

#RUN curl -L https://s3.amazonaws.com/eatsa-packages/build-framework/build-framework-master-1.5.0.tgz | tar -C /tmp -zx && \
#    mkdir -p ~/bf && \
#    mv /tmp/build-framework ~/bf/build-frameowrk && \
#    ln -s ~/bf/build-framework ~/build-framework

ENV USER=root \
    HOME=/root \
    DEBIAN_FRONTEND=noninteractive
