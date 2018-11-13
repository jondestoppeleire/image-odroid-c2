#!/bin/bash
#
# Compress and copy the full OS image from ./workspace to ./dist.
# This is separate from build.sh to avoid travis-ci timeout!

# exit script on command failure not explicitly caught
set -e
[ -n "${DEBUG}" ] && set -x

# source common variables / configuration
. setup.sh

[ -n "${DEBUG}" ] && ls -lha "." "${workspace}" "${dist}"

if [ ! -f "${workspace}/version.txt" ]; then
    echo "Expected file ${workspace}/version.txt but not found."
    return 1
fi

# we use the version from ${workspace}/version.txt as that captured the
# timestamp used when running ./build.sh
readonly build_version=$(cat "${workspace}/version.txt")

# Compress the full image and move to dist. Save full image to make
# root filesystem and netboot artifacts
# Going with simple versioning right now - YYYYmmddHHMMSS
pushd "${workspace}"
xz --verbose --keep "${output_image_file}"
popd

# there should be a file in ./dist/eatsa-smartshelf-odroid-c2.img-YYYYmmddHHMMSS.xz
mv "${work_output_image}.xz" "${dist}/${output_image_file}-${build_version}.xz"
cp "${workspace}/filesystem-odroid_c2.squashfs" "${dist}/filesystem-odroid_c2-${build_version}.squashfs"
