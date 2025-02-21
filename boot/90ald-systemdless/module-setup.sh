#!/bin/bash

check() {
    if [[ -x /usr/libexec/ald-boot.sh ]]; then
        return 255
    fi

    return 1
}

depends() {
    echo bash

    return 0
}

installkernel() {
    hostonly='' instmods erofs loop
}

install() {
    
    inst_dir /usr/lib/ald

    inst_multiple /usr/lib/ald/*.sh \
        /usr/libexec/ald-boot.sh \
        ald

    inst_hook pre-pivot 40 "$moddir/ald-hook.sh"
    
    # Dependencies
}
