#!/bin/sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh


ald_boot=$(getarg ald.boot)
[ -z "$ald_boot" ] && exit 0

active_boot=$(cat "/sysroot/var/deployments/current" 2>/dev/null)
[ -z "$active_boot" ] && exit 1


[ "$active_boot" = "$ald_boot" ] && \
    echo "Current: $active_boot" && \
    echo "Next: $ald_boot" && \
    (mount -o bind,ro "/sysroot/usr" "/sysroot/usr" || printf "Couldn't bind mount /usr") && \
    (chattr +i "/sysroot/" || printf "Couldn't lock /.\n") && \
    find "/sysroot/var/deployments" -mindepth 2 -maxdepth 2 -type d -name "usr" -exec bash -c 'mountpoint {} &>/dev/null || mount -o bind,ro {} {} &>/dev/null' \; && \
    exit 0

mount -o remount,rw /sysroot
[ ! -d /sysroot/usr ] && mkdir -p /sysroot/usr

ald swap "$ald_boot" --initramfs
