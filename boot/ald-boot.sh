#!/bin/sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh


ald_boot=$(getarg ald.boot)
[ -z "$ald_boot" ] && exit 0

active_boot=$(cat "/sysroot/.ald/current" 2>/dev/null)
[ -z "$active_boot" ] && exit 1


[ "$active_boot" = "$ald_boot" ] && \
    echo "Current: $active_boot" && \
    echo "Cmdline: $ald_boot" && \
    (mount -o bind,ro "/sysroot/usr" "/sysroot/usr" || printf "Couldn't bind mount /usr") && \
    (mount -o bind,rw "/sysroot/usr/local" "/sysroot/usr/local" || printf "Couldn't bind mount /usr/local") && \
    (chattr +i "/sysroot/" || printf "Couldn't lock /.\n") && \
    mountpoint "/sysroot/.ald" || mount -o bind,ro "/sysroot/.ald" "/sysroot/.ald"
    exit 0

mount -o remount,rw /sysroot
[ ! -d /sysroot/usr ] && mkdir -p /sysroot/usr

ald swap "$ald_boot" --initramfs
