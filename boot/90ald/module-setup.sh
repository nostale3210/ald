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

    dracut_install /lib64/libacl.so.1
    dracut_install /lib64/libpopt.so.0
    dracut_install /lib64/liblz4.so.1
    dracut_install /lib64/libzstd.so.1
    dracut_install /lib64/libxxhash.so.0
    dracut_install /lib64/libcrypto.so.3
    dracut_install /lib64/libc.so.6
    dracut_install /lib64/libattr.so.1
    dracut_install /lib64/libz.so.1
    dracut_install /lib64/ld-linux-x86-64.so.2
    dracut_install /usr/bin/rsync
    dracut_install /usr/bin/exch

    dracut_install /lib64/libselinux.so.1
    dracut_install /lib64/libsepol.so.2
    dracut_install /lib64/libaudit.so.1
    dracut_install /lib64/libpcre2-8.so.0
    dracut_install /lib64/libcap-ng.so.0
    dracut_install /usr/sbin/setfiles
    
    dracut_install /lib64/libgcc_s.so.1
    dracut_install /lib64/libacl.so.1
    dracut_install /lib64/libblkid.so.1
    dracut_install /lib64/libcap.so.2
    dracut_install /lib64/libcrypt.so.2
    dracut_install /lib64/libmount.so.1
    dracut_install /lib64/libpam.so.0
    dracut_install /lib64/libseccomp.so.2
    dracut_install /lib64/libm.so.6
    dracut_install /usr/lib64/systemd/libsystemd-shared-256.11-1.fc41.so
    dracut_install /lib64/libattr.so.1
    dracut_install /lib64/libeconf.so.0
    dracut_install /usr/bin/systemd-inhibit

    inst_simple "${systemdsystemunitdir}/ald-boot.service"
    mkdir -p "${initdir}${systemdsystemconfdir}/initrd-root-fs.target.wants"
    ln_r "${systemdsystemunitdir}/ald-boot.service" \
        "${systemdsystemconfdir}/initrd-root-fs.target.wants/ald-boot.service"
}
