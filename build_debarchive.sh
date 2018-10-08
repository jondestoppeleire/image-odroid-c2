# shellcheck shell=bash
#
# creates a debarchive file compatible wise-display.
#
# Usage:
#
#     . build_debarchive.sh

echo "build_debarchive.sh: importing setup.sh"
# import common variables
. setup.sh

echo "Creating ${dist}/debarchive-odroid_c2-${dist_version}.tgz"
tar --directory "${rootfs_dir}" --exclude=lock --exclude=partial \
    -czf "${dist}/debarchive-odroid_c2-${dist_version}.tgz" \
    var/cache/apt /var/lib/apt
