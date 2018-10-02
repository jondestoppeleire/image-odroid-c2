# shellcheck shell=sh
# shell compatible file for declaring shared configuration.
# No shebang (#!, sha-bang) as a subprocess is not desirable.
# Use `shellcheck -s sh` to validate.
#
# Usage, from shell or in a script:
#
#     . ./setup.sh
#

# GLOBALS
export EATSAPASS="eatsa"
# secret variable SKIP_APT_UPDATE to speed up development.

readonly workspace="./workspace"
readonly dist="./dist"

mkdir -p "${workspace}"
mkdir -p "${dist}"

# Use a base working ubuntu image for the odroid-c2
# Saved a copy of the image from https://odroid.in/ubuntu_16.04lts/ to S3.
readonly image_file="ubuntu64-16.04.3-minimal-odroid-c2-20171005.img"
#readonly image_file="ubuntu-18.04-3.16-minimal-odroid-c2-20180626.img"

readonly image_file_xz="${image_file}.xz"
readonly image_url="https://s3.amazonaws.com/eatsa-artifacts/wise-display/${image_file_xz}"
readonly md5sum_url="${image_url}.md5sum"
readonly work_image_xz="${workspace}/${image_file_xz}"
readonly work_image="${workspace}/${image_file}"
readonly output_image_file="eatsa-smartshelf-odroid-c2.img"
readonly work_output_image="${workspace}/${output_image_file}"
