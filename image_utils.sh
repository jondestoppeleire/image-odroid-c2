#!/bin/bash
#
# A library of functions meant to be source or dotted in by other scripts.

# The array storing functions meant for deferred execution.
cleanup_functions=()

#####
# Adds a bash string to the cleanup_functions array.
# For example, use
#     register_cleanup "myFunc Arg1 Arg1"
# to have myFunc called with Arg1 and Arg2 in run_cleanup.
#
# Globals:
#   cleanup_functions - an array storing statements to be evaluated.
# Arguments:
#   $1 - a bash statement to be evaluated.
# Returns:
#   None
#####
register_cleanup() {
    cleanup_functions+=("$1")
}

#####
# Executes the statements in cleanup_functions in reverse order.
# Globals:
#   cleanup_functions - an array storing functions calls.
# Arguments:
#   $1 - a function to be called for cleanup
# Returns:
#   None
#####
run_cleanup() {
    set -e
    for (( idx=${#cleanup_functions[@]}-1 ; idx>=0 ; idx-- )) ; do
        if ! eval "${cleanup_functions[idx]}"; then
            echo "Failed to clean up while running '${cleanup_functions[idx]}'."
            echo "Dumping cleanup commands:"
            printf '%s\n' "${cleanup_functions[@]}"
        fi
    done
    # delete the cleanup functions so they're not run again.
    unset cleanup_functions
    cleanup_functions=()
    set +e
}

# Automagically execute run_cleanup on script exit or if user ctrl-c
trap run_cleanup EXIT SIGINT SIGQUIT

#####
# Lists active loop devices in use associated with given file.
# Globals:
#   None
# Arguments:
#   $1 - the file to assocate to the loop device.
# Returns:
#   Exit code - 0 if successful, a larger value otherwise.
#####
get_active_loop_devices() {
    local img_file="$1"
    losetup -j "${img_file}" | cut -d' ' -f1 | sed 's/.$//'
}

#####
# Detaches all loop devices associated to the given file.
# Globals:
#   None
# Arguments:
#   $1 - the file to assocate to the loop device.
# Returns:
#   Exit code - 0 if successful, a larger value otherwise.
#####
cleanup_loop_device() {
    local img_file="$1"
    if [ -z "${img_file}" ]; then
        echo "Usage: $0 img_file"
        return 1
    fi

    [ -n "${DEBUG}" ] && echo "cleanup_loop_device ${img_file}."

    # Find all loop devices assocated with the file
    # Use the first field in the output (cut)
    # Replace the last character ("/dev/loop0:") with nothing (sed)
    # disassociate all the devices
    active_devices=$(get_active_loop_devices "${img_file}")
    for active_device in $active_devices; do
        losetup -d "${active_device}"
        echo "Successfully detached ${active_device} from ${img_file}"
    done
    return 0
}

#####
# Attaches a file to a loop device and registers a cleanup function that runs
# when the calling script exists or is interrupted.
#
# Globals:
#   None
# Arguments:
#   $1 - the free loop device to use. Usually pass in $(losetup -f).
#   $2 - the file to assocate to the loop device.
# Returns:
#   None
#####
with_loop_device() {
    local loop_device="$1"
    local img_file="$2"

    # Do our best to make sure loop device is free.
    if [ "${loop_device}" != "$(losetup -f)" ]; then
        echo "Loop device ${loop_device} doesn't seem to be free."
        return 1
    fi

    if [ ! -e "${img_file}" ]; then
        echo "Image file ${img_file} does not exist."
        return 1
    fi

    # register the cleanup routine
    # Do this first in case losetup succeeds but partprobe fails.
    register_cleanup "cleanup_loop_device ${img_file}"

    # Attached the image file to the loop device.
    losetup "${loop_device}" "${img_file}"

    # tell the OS there's a new device and partitions.
    partprobe "${loop_device}"
}

#####
# Unmounts a mount point.
#
# Globals:
#   None
# Arguments:
#   $1 - the mount point
# Returns:
#   None
#####
cleanup_mount() {
    local mount_point="$1"
    mountpoint -q "${mount_point}" && umount "${mount_point}"
    sync
}

#####
# Helper function to create mount dirs and clean up when done.
#
# Globals:
#   None
# Arguments:
#   $1 - device to mount
#   $2 - the mount point
# Returns:
#   None
#####
with_mount() {
    local device="$1"
    local mount_point="$2"

    mkdir -p "${mount_point}"

    # no need to check device, as mount will barf on invalid params.
    mount "${device}" "${mount_point}"

    register_cleanup "cleanup_mount ${mount_point}"
}


#####
# Clean up mounts in a chroot.
#
# Globals:
#   None
# Arguments:
#   $1 - chroot directory
#   $2 - mount point
# Returns:
#   None
#####
cleanup_chroot_mount() {
    local chroot_dir="$1"
    local mount_point="$2"

    chroot "${chroot_dir}" \
      /bin/bash -c "if mountpoint -q ${mount_point}; then umount ${mount_point}; else exit 0; fi"
}

#####
# Helper function to create mount inside a chroot and clean up when done.
#
# Globals:
#   None
# Arguments:
#   $1 - chroot directory
#   $2 - mount type
#   $3 - mount point
# Returns:
#   None
#####
with_chroot_mount() {
    local chroot_dir="$1"
    local mount_type="$2"
    local mount_point="$3"

    chroot "${chroot_dir}" mount none -t "${mount_type}" "${mount_point}"

    register_cleanup "cleanup_chroot_mount ${chroot_dir} ${mount_point}"
}

#####
# Deletes the /usr/sbin/policy-rc.d file.
#
# Globals:
#   None
# Arguments:
#   $1 - chroot directory
# Returns:
#   None
#####
readonly policy_rc_file="/usr/sbin/policy-rc.d"
cleanup_temp_disable_invoke_rc_d() {
    local chroot_dir="$1"
    chroot "${chroot_dir}" rm -f "${policy_rc_file}"
    echo "Removed ${chroot_dir}${policy_rc_file}"
}

#####
# Write a non-zero exit to policy-rc in the chroot to disable services from
# starting.  Registers a cleanup function to delete the file when done.
#
# Globals:
#   None
# Arguments:
#   $1 - chroot directory
# Returns:
#   None
#####
temp_disable_invoke_rc_d() {
    local chroot_dir="$1"
    chroot "${chroot_dir}" tee "${policy_rc_file}" > /dev/null << _EOF
#!/bin/sh
exit 101
_EOF
    chmod a+x "${chroot_dir}${policy_rc_file}"
    echo "Wrote to ${chroot_dir}${policy_rc_file}"

    register_cleanup "cleanup_temp_disable_invoke_rc_d ${chroot_dir}"
}
