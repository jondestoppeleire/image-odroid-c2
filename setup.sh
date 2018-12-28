# shellcheck shell=sh
# shell compatible file for declaring shared configuration.
# No shebang (#!, sha-bang) as a subprocess is not desirable.
# Use `shellcheck -s sh` to validate.
#
# Usage, from shell or in a script:
#
#     . ./setup.sh
#

[ -n "${DEBUG}" ] && set -x

# Allows multiple scripts to import this file without erroring out
# on multiple declarations of readonly variables
if [ -n "${SETUP_SH_IMPORTED}" ]; then
    [ -n "${DEBUG}" ] && echo "setup.sh already ran before, short circuiting."
    return 0
fi

# Not imported before, set the flag and let the rest of the script run.
readonly SETUP_SH_IMPORTED="setup.sh is now imported."

# GLOBALS
export EATSAPASS="eatsa"
# secret variable SKIP_APT_UPDATE to skip apt update step in build.sh
# export SKIP_APT_UPDATE=1

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

# IMPORTANT! if you change the value of this variable, make sure to update it
# in the wise-upgrade.sh script used during runtime!
readonly output_filesystem_file="filesystem-smartshelf-odroid_c2"

readonly output_image_file="eatsa-smartshelf-odroid_c2.img"
readonly work_output_image="${workspace}/${output_image_file}"

# To build multiple stable branches, change this variable to
# read from an environmental variable.  Then set the environmental
# variable using travis-ci's build matrix feature.
readonly fw_smartshelf_version="sbux-quad-26"

readonly rootfs_dir="${workspace}/rootfs"
readonly boot_partition_mount="${rootfs_dir}/media/boot"
readonly data_partition_mount="${rootfs_dir}/media/data"

mkdir -p "${boot_partition_mount}"
mkdir -p "${data_partition_mount}"

# Use UTC date and NOT SERVER LOCAL DATE
readonly dist_version="$(date -u +%s)"
