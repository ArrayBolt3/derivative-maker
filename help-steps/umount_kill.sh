#!/bin/bash -e

#
# Written by Jason Mehring (nrgaway@gmail.com)
# Modified by Patrick Schleizer (adrelanos@whonix.org)
#
# Kills any processes within the mounted location and
# unmounts any mounts active within.
#
# To keep the actual mount mounted, add a '/' to end
#
# $1: directory to umount
#
# Examples:
# To kill all processes and mounts within 'chroot-jessie' but keep
# 'chroot-jessie' mounted:
#
# ./umount_kill.sh chroot-jessie/
#
# To kill all processes and mounts within 'chroot-jessie' AND also
# umount 'chroot-jessie' mount:
#
# ./umount_kill.sh chroot-jessie
#

# $1 = full path to mount;
# $2 = if set will not umount; only kill processes in mount
umount_kill() {
    MOUNTDIR="$1"

    # We need absolute paths here so we don't kill everything
    if ! [[ "$MOUNTDIR" = /* ]]; then
        MOUNTDIR="${PWD}/${MOUNTDIR}"
    fi

    # Strip any extra trailing slashes ('/') from path if they exist
    # since we are doing an exact string match on the path
    MOUNTDIR=$(echo "$MOUNTDIR" | sed s#//*#/#g)

    dir="$MOUNTDIR"

    echo "-> Attempting to kill any processes still running in '$MOUNTDIR' before un-mounting"
#     for dir in $(grep "$MOUNTDIR" /proc/mounts | cut -f2 -d" " | sort -r | grep "^$MOUNTDIR")
#     do
        ## Debugging.
        true "--------------------------------------------------------------------------------"
        lsof "$dir"
        true "--------------------------------------------------------------------------------"

        pids=$(lsof "$dir" 2> /dev/null)
        pids=$(echo "$pids" | grep "$dir")
        pids=$(echo "$pids" | tail -n +2)
        pids=$(echo "$pids" | awk '{print $2}')

        if [ "$pids" = "" ]; then
           echo "Okay, no pids still running in '$MOUNTDIR', no need to kill any."
        else
           echo "Okay, the following pids are still running inside '$MOUNTDIR', which will now be killed."
           ps -p $pids
           kill -9 $pids
        fi

        if ! [ "$2" ] && $(mountpoint -q "$dir"); then
            echo "un-mounting $dir"
            umount -n "$dir" 2> /dev/null || \
                umount -n -l "$dir" 2> /dev/null || \
                echo "umount $dir unsuccessful!"
        elif ! [ "$2" ]; then
            # Look for (deleted) mountpoints
            echo "not a regular mount point: $dir"
            base=$(basename "$dir")
            dir=$(dirname "$dir")
            base=$(echo "$base" | sed 's/[\].*$//')
            dir="$dir/$base"
            umount -v -f -n "$dir" 2> /dev/null || \
                umount -v -f -n -l "$dir" 2> /dev/null || \
                echo "umount $dir unsuccessful!"
        fi
#     done
}

kill_processes_in_mount() {
    umount_kill $1 "false" || :
}

if [ ! "$(id -u)" = "0" ]; then
   echo "$0: ERROR: This MUST be run as root (sudo)!" >&2
   exit 1
fi

if [ $(basename "$0") == "umount_kill.sh" -a "$1" ]; then
    umount_kill "$1"
fi
