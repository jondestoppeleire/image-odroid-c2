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
    unset cleanup_functions
    set +e
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
    local image_file="$1"
    [ -n "${DEBUG}" ] && echo "cleanup_loop_device ${image_file}."

    # Find all loop devices assocated with the file
    # Use the first field in the output (cut)
    # Replace the last character ("/dev/loop0:") with nothing (sed)
    # disassociate all the devices
    active_devices=$(losetup -j "${image_file}" | cut -d' ' -f1 | sed 's/.$//')
    for active_device in $active_devices; do
        losetup -d "${active_device}"
        echo "Successfully detachd ${active_device} from ${image_file}"
    done
    return 0
}

#####
# Executes the functions in cleanup_functions in reverse order.
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
    local image_file="$2"

    # Do our best to make sure loop device is free.
    if [ "${loop_device}" != "$(losetup -f)" ]; then
        echo "Loop device ${loop_device} doesn't seem to be free."
        return 1
    fi

    if [ ! -e "${image_file}" ]; then
        echo "Image file ${image_file} does not exist."
        return 1
    fi

    # register the cleanup routine
    # Do this first in case losetup succeeds but partprobe fails.
    register_cleanup "cleanup_loop_device ${image_file}"

    # Attached the image file to the loop device.
    losetup "${loop_device}" "${image_file}"

    # tell the OS there's a new device and partitions.
    partprobe "${loop_device}"
}

# Automagically execute run_cleanup on script exit or if user ctrl-c
trap run_cleanup EXIT SIGINT SIGQUIT
