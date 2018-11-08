#!/bin/bash

set -e
[ -n "${DEBUG}" ] && set -x

# constructs the url where wise-display hosts (os) images.
get_images_server_url() {
    local storemgr_host="storemanager"
    local storemgr_port="1990"
    if mount -r -L EATSACONF /mnt > /dev/null 2>&1; then
        # shellcheck disable=SC1091
        [ -r /mnt/config.txt ] && . /mnt/config.txt
        umount /mnt
    fi
    # See https://keenwawa.atlassian.net/wiki/spaces/Eng/pages/370180105/wise-display+to+be+renamed+to+display-manager#wise-display(toberenamedtodisplay-manager)-USBconfigdrive
    # for variables set from USB config stick
    [ -n "${WISE_SMIP}" ] && storemgr_host="${WISE_SMIP}"
    [ -n "${WISE_SMPORT}" ] && storemgr_port="${WISE_SMPORT}"

    echo "http://${storemgr_host}:${storemgr_port}"
}

# Delete all .squashfs files except for the lateset one.
remove_old_archives() {
    local work_dir="${1}"
    local fs_name_prefix="${2}"
    # 1. find all files prefixed filesystem-odroid_c2
    # 2. Sort by file name in reverse order.  The assumption is that the files
    #    are suffixed with unix timestamp, so newest file is first.
    # 3. tail: grab all names starting from 2nd one
    # 4. rm all but the latest file
    find "${work_dir}" -name "${fs_name_prefix}*.squashfs" | \
      sort -r      | \
      tail -n +2   | \
      xargs rm -f

    # also delete all partially downloaded files
    rm -f "${work_dir}"/*.part
    rm -f "${work_dir}"/*.sha256sum
}

get_latest_sha256sum() {
    local images_server_url="${1}"
    local fs_name_prefix="${2}"
    local remote_file_name_suffix="${3}"

    # 1. Request the index (make sure wise-display nginx.conf autoindex on)
    # 2. Find the value inside the <a href="myvalue"> --> href="myvalue"
    # 3. Strip out myvalue using `cut -d'"' -f 2`, using " as the delimiter
    # 4. Sort in reverse to get the latest first (assumes unix epoc timestamp suffix)
    # 5. Take the first value
    curl -sSL "${images_server_url}" | \
      grep -o "href=\"${fs_name_prefix}.*\\.${remote_file_name_suffix}\"" | \
      cut -d'"' -f 2 | \
      sort -r | \
      head -1
}

download_filesystem_archive() {
    local work_dir="${1}"
    local fs_name_prefix="${2}"
    local images_server_url
    local latest_sha256sum

    # clear out old archives except for most recent one
    remove_old_archives "${work_dir}" "${fs_name_prefix}"

    images_server_url=$(get_images_server_url)
    latest_sha256sum=$(get_latest_sha256sum "${images_server_url}" "${fs_name_prefix}" "sha256sum")

    # There are no sha256sum files describing the images
    if [ -z "${latest_sha256sum}" ]; then
        echo "Expected files named like ${fs_name_prefix}*.sha256sum at \"${images_server_url}\", but non found."
        return 1
    fi

    # download "latest" sha256 file
    if curl -sSL "${images_server_url}/${latest_sha256sum}" -o "${work_dir}/${latest_sha256sum}.part"; then
        mv "${work_dir}/${latest_sha256sum}.part" "${work_dir}/${latest_sha256sum}"
    else
        echo "Could not find ${images_server_url}/${latest_sha256sum}"
        return 1
    fi

    # Since we removed old archives above, we can compare the sha256sum.
    local have_latest
    local last_used_archive
    last_used_archive=$(find "${work_dir}" -name "${fs_name_prefix}*sha256sum")
    if [ -e "${last_used_archive}" ]; then
        pushd "${work_dir}" > /dev/null 2>&1
        if shasum -a 256 -c "${latest_sha256sum}" > /dev/null 2>&1; then
            have_latest="yes"
        fi
        popd > /dev/null 2>&1
    fi

    if [ -n "${have_latest}" ]; then
        [ -n "${DEBUG}" ] && echo "sha256sum matches, we have the latest already."
        remove_old_archives "${work_dir}" "${fs_name_prefix}"
        return 0
    fi

    [ -n "${DEBUG}" ] && echo "sha256sum doesn't match, downloading new file..."
    # Grab the filename from the checksum file!
    local new_fs_archive
    new_fs_archive=$(awk '{print $2}' "${work_dir}/${latest_sha256sum}")
    curl -sSL "${images_server_url}/${new_fs_archive}" -o "${work_dir}/${new_fs_archive}.part"

    # make sure the downloaded file's sha checks out before renaming to official
    local shasum_check
    shasum_check=$(shasum -a 256 "${work_dir}/${new_fs_archive}.part" | awk '{print $1}')
    if grep -s "${shasum_check}" "${work_dir}/${latest_sha256sum}"; then
        mv "${work_dir}/${new_fs_archive}.part"  "${work_dir}/${new_fs_archive}"
        remove_old_archives "${work_dir}" "${fs_name_prefix}"
    else
        echo "Bad checksum, found ${shasum_check} but expecting:"
        cat "${work_dir}/${latest_sha256sum}"
        return 1
    fi

    echo "${work_dir}/${new_fs_archive}"
}

do_upgrade() {
    local work_dir="${1}"
    local fs_name_prefix="${2}"

    [ -z "${work_dir}" ] && work_dir="/media/data"
    [ -z "${fs_name_prefix}" ] && fs_name_prefix="filesystem-odroid_c2"

    #local fs_archive
    #fs_archive=$(download_filesystem_archive "${work_dir}" "${fs_name_prefix}")
    download_filesystem_archive "${work_dir}" "${fs_name_prefix}"

    # After download_filesystem_archive, we only expect to have a .squashfs
    # file as the .sha256sum file is deleted.
    #
    # Now figure out which partition to unsquashfs to.
    # on success, flip a bunch of bits.
}

WISE_SMIP=localhost
do_upgrade test_wise_upgrade_work dummy-odroid_c2
#do_upgrade test_wise_upgrade_work dummy-odroid_c2_file_not_exist
