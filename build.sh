#!/bin/bash
#
# build the odroid-c2 os image.
#
# Not using build-framework to simplify reading and comprehension.

# exit script on command failure not explicitly caught
set -e
[ -n "${DEBUG}" ] && set -x

readonly mydir="$PWD"
readonly workspace="./workspace"
readonly dist="./dist"

mkdir -p "${workspace}"
mkdir -p "${dist}"

cd "${workspace}" || exit 1

# Use a base working ubuntu image for the odroid-c2
# Saved a copy of the image from https://odroid.in/ubuntu_16.04lts/ to S3.
readonly image_file="ubuntu64-16.04.3-minimal-odroid-c2-20171005.img"
readonly image_file_xz="${image_file}.xz"
readonly image_url="https://s3.amazonaws.com/eatsa-artifacts/wise-display/${image_file_xz}"
readonly md5sum_url="${image_url}.md5sum"
readonly output_file="eatsa-ubuntu64-16.04.3-odroid-c2.img"

# only download the image if it doesn't exist.
# We may already have uncompressed the image file if this is not the first
# run of the script.
if [ ! -e "${image_file}" ] || [ ! -e "${image_file_xz}" ]; then
    curl -Ss -O "${image_url}"
fi

# only download the md5sum file if it doesn't exist.
if [ ! -e "${image_file_xz}.md5sum" ]; then
    curl -Ss -O "${md5sum_url}"
fi

# The md5 and extract is only valid when the first time running the script.
if [ -e "${image_file_xz}" ]; then
    md5sum --check "${image_file_xz}.md5sum"
    if [ ! -e "${image_file}" ]; then
        xz --decompress --keep ${image_file_xz}
    fi
fi

# Grow the disk image file.
# Expand the the file system to fill the expanded disk size.
"${mydir}"/resize.sh "${image_file}" 2

# chroot and install software
"${mydir}"/install_software.sh "${image_file}"

# get out of ./workspace
cd .. || exit 1

# Finally, move final product to dist.  Copy if $DEBUG is set.
# Bump version number as well?
#if [ -n "$DEBUG" ]; then
#    cp "${workspace}/${image_file}" "${dist}/${output_file}"
#else
#    mv "${workspace}/${image_file}" "${dist}/${output_file}"
#fi
