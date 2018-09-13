#!/bin/sh

readonly distro="$1"
container_command="$2"

readonly build_dir=dockerfiles/"$distro"

usage() {
    echo "This script runs \"docker run\" for specific Dockerfiles."
    echo
    echo "Usage: $0 distro_version container_command"
    echo
    echo "  distro_version - the name of a directory found in ./dockerfiles/"
    echo "  container_command - the command to run when the container starts."
    echo "                      Defaults to './build.sh'"
    echo
    echo "Example:"
    echo "    ./run_build_env.sh ubuntu-xenial"
    echo "  Run a shell:"
    echo "    ./run_build_env.sh ubuntu-xenial /bin/bash"
    echo
    exit 1
}

if [ -z "$distro" ]; then
    usage
fi

if [ ! -d "$build_dir" ]; then
    echo "Dockerfile for distro '$1' does not exist in $build_dir."
    usage
fi

if [ -z "$container_command" ]; then
    container_command="./build.sh"
fi

readonly os_name=$(uname)
if [ "$os_name" = "Darwin" ]; then
    echo "Running under macOS (Darwin), some mounts are not available so not everything may work."
    docker run --rm -it -e HOME --privileged \
     -h eatsa-odroid-c2-build-env \
     -v "$HOME":"$HOME" \
     -v "$PWD":"$PWD" -w "$PWD" \
     -v /dev:/dev \
     eatsa-odroid-c2-rootfs:build-env-"$distro" \
     "$container_command"
else
    # macOS does not have the following, but linux host will:
    # -v /run/udev:/run/udev:ro \
    docker run --rm -it -e HOME --privileged \
     -h eatsa-odroid-c2-build-env \
     -v "$HOME":"$HOME" \
     -v "$PWD":"$PWD" -w "$PWD" \
     -v /dev:/dev \
     -v /run/udev:/run/udev:ro \
     eatsa-odroid-c2-rootfs:build-env-"$distro" \
     "$container_command"
fi
