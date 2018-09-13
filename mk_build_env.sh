#!/bin/bash

readonly distro="$1"
readonly build_dir=dockerfiles/"$distro"

usage() {
    echo "This script runs \"docker build\" for specific Dockerfiles."
    echo
    echo "Usage: $0 distro_version"
    echo
    echo "  distro_version - the name of a directory found in ./dockerfiles/"
    echo
    echo "Example:"
    echo "    ./mk_build_env.sh ubuntu-xenial"
    echo
    exit 1
}

if [ -z "$distro" ]; then
    usage
fi

if [ ! -d "$build_dir" ]; then
    echo "Dockerfile for distro '$distro' does not exist in dockerfiles/"
    usage
fi

if ! docker image inspect eatsa-odroid-c2-rootfs:build-env-"$distro" > /dev/null 2>&1; then
    docker build -t eatsa-odroid-c2-rootfs:build-env-"$distro" "$build_dir"
else
    echo "Using existing Docker image $(docker images -q eatsa-odroid-c2-rootfs:build-env-"$distro")."
fi
