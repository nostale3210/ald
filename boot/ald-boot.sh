#!/bin/sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh


ald_boot=$(getarg ald.boot)
[ -z "$ald_boot" ] && exit 0

active_boot=$(cat "/sysroot/var/deployments/current" 2>/dev/null)
[ -z "$active_boot" ] && exit 1


[ "$active_boot" = "$ald_boot" ] && \
    mount -o bind,ro "/sysroot/usr" "/sysroot/usr" && \
    chattr +i "/sysroot/" || printf "Couldn't lock /.\n" && \
    find "/sysroot/var/deployments" -mindepth 2 -maxdepth 2 -type d -name "usr" -exec bash -c 'mountpoint {} &>/dev/null || mount -o bind,ro {} {} &>/dev/null' \; && \
    exit 0

ald swap "$ald_boot" --initramfs
