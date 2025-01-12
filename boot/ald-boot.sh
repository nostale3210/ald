#!/bin/sh

type getarg >/dev/null 2>&1 || . /lib/dracut-lib.sh


ald_boot=$(getarg ald.boot)
[ -z "$ald_boot" ] && exit 0

active_boot=$(cat "/sysroot/var/deployments/current 2>/dev/null)
[ -z "$active_boot" ] && exit 1


[ "$active_boot" = "$ald_boot" ] && exit 0

ald swap "$ald_boot" --initramfs
