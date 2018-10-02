#!/bin/bash
#
# Compress and copy the full OS image from ./workspace to ./dist.
# This is separate from build.sh to avoid travis-ci timeout!

# exit script on command failure not explicitly caught
set -e
[ -n "${DEBUG}" ] && set -x

# source common variables / configuration
. ./setup.sh

# Compress the full image and move to dist. Save full image to make
# root filesystem and netboot artifacts
# Going with simple versioning right now - YYYYmmddHHMMSS
pushd "${workspace}"
xz --keep "${output_image_file}"
popd

# there should be a file in ./dist/eatsa-smartshelf-odroid-c2.img-YYYYmmddHHMMSS.xz
mv "${work_output_image}.xz" "${dist}/${output_image_file}-$(date +%Y%m%d%H%M%S).xz"
