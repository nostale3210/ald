#!/bin/sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh


[ -z "$1" ] && exit 1
sysroot="$1"

ald_boot=$(getarg ald.boot)
[ -z "$ald_boot" ] && exit 0

active_boot=$(cat "$sysroot/usr/.ald_dep" 2>/dev/null)
[ -z "$active_boot" ] && printf "Couldn't determine active deployment. Dirty Switch!\n"

mount -o remount,rw --make-private "$sysroot"
[ ! -d "$sysroot/usr" ] && mkdir -p "$sysroot/usr"
[ ! -d "$sysroot/etc" ] && mkdir -p "$sysroot/etc"

[ "$active_boot" = "$ald_boot" ] && \
    echo "Current/Cmdline: $ald_boot" && \
    (mount -o loop "$sysroot/.ald/$ald_boot/$ald_boot.efs" "$sysroot/usr" || printf "Couldn't bind mount /usr\n") && \
    (mount -o bind "$sysroot/.ald/$ald_boot/etc" "$sysroot/etc" || printf "Couldn't bind mount /usr\n") && \
    (mount -o bind,rw "$sysroot/usr/local" "$sysroot/usr/local" || printf "Couldn't bind mount /usr/local\n") && \
    (mountpoint "$sysroot/.ald" >/dev/null 2>&1 || mount -o bind,ro "$sysroot/.ald" "$sysroot/.ald") && \
    (chattr +i "$sysroot/" || printf "Couldn't lock /.\n") && \
    exit 0

echo "Current: $active_boot"
echo "Cmdline: $ald_boot (next)"

ald swap "$ald_boot" --rootd "$sysroot"
