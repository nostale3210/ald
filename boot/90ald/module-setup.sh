#!/bin/bash

check() {
    if [[ -x "$systemdutildir"/systemd ]] && [[ -x /usr/libexec/ald-boot.sh ]]; then
        return 255
    fi

    return 1
}

depends() {
    echo bash systemd

    return 0
}

installkernel() {
    hostonly='' instmods erofs loop
}

install() {
    
    inst_dir /usr/lib/ald

    inst_multiple /usr/lib/ald/*.sh \
        /usr/libexec/ald-boot.sh \
        "$systemdsystemunitdir"/ald-boot.service \
        ald
    
    $SYSTEMCTL -q --root "$initdir" enable ald-boot.service

    # Dependencies
}
