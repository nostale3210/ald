#!/bin/bash

installkernel() {
    return 0
}

check() {
    if [[ -x $systemdutildir/systemd ]] && [[ -x /usr/libexec/ald-boot.sh ]]; then
        return 255
    fi

    return 1
}

depends() {
    return 0
}

install() {
    dracut_install /usr/libexec/ald-boot.sh
    dracut_install /usr/bin/ald

    inst_simple "${systemdsystemunitdir}/ald-boot.service"
    mkdir -p "${initdir}${systemdsystemconfdir}/initrd-root-fs.target.wants"
    ln_r "${systemdsystemunitdir}/ald-boot.service" \
        "${systemdsystemconfdir}/initrd-root-fs.target.wants/ald-boot.service"

    # Dependencies
}
