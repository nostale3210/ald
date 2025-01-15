#!/bin/sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh


ald_boot=$(getarg ald.boot)
echo "Cmdline: $ald_boot"
[ -z "$ald_boot" ] && exit 0

active_boot=$(cat "/sysroot/.ald/current" 2>/dev/null)
echo "Current: $active_boot"
[ -z "$active_boot" ] && exit 1


[ "$active_boot" = "$ald_boot" ] && \
    echo "Cmdline: $ald_boot" && \
    echo "Current: $active_boot" && \
    mount -o remount,rw /sysroot && \
    (mount -o bind,ro "/sysroot/usr" "/sysroot/usr" || printf "Couldn't bind mount /usr\n") && \
    (mount -o bind,rw "/sysroot/usr/local" "/sysroot/usr/local" || printf "Couldn't bind mount /usr/local\n") && \
    (chattr +i "/sysroot/" || printf "Couldn't lock /.\n") && \
    (mountpoint "/sysroot/.ald" || mount -o bind,ro "/sysroot/.ald" "/sysroot/.ald") && exit 0

mount -o remount,rw /sysroot
[ ! -d /sysroot/usr ] && mkdir -p /sysroot/usr
[ ! -d /sysroot/etc ] && mkdir -p /sysroot/etc

echo "Cmdline: $ald_boot (next)"
echo "Current: $active_boot"

ald swap "$ald_boot" --initramfs
