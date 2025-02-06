#!/usr/bin/env bash


pprint() {
    if [[ "$tput_support" == "y" ]]; then
        echo "$1" > "$locsync"
    else
        printf "%s\n" "$1"
    fi
}


iprint() {
    if [[ "$tput_support" == "y" ]]; then
        printf "\e[2K\r[Info] %s\n" "$1"
    else
        printf "[Info] %s\n" "$1"
    fi
}


clean_draw() {
    echo "" > "$locsync"
    sleep 0.2
    kill "$(jobs -p)" 2>/dev/null
    rm "$locsync" &>/dev/null
    printf "\e[2K\r\e[?25h"
    return 0
}


draw_bar() {
    printf "\e[?25l"
    local locsync="$1"
    while true; do
        while [[ -z "$(cat "$locsync")" ]]; do sleep 1; done
        for status in "|" "/" "-" "\\"; do
            printf "\e[2K\r[%s] %s" "$status" "$(cat "$locsync")"
            sleep 0.1
        done
    done
}


fail_ex() {
    printf "\n\033[31;1mCritical Failure!\033[0m\n%s\n\n" "$2"

    if [[ ! "$(cat "/usr/.ald_dep")" == "$1" && ! "$1" == "-1" ]]; then
        pprint "Attempting cleanup..."
        podman rm ald-tmp &>/dev/null
        podman rm ald-utils &>/dev/null
        podman rm ald-boot &>/dev/null
        rm -rf "${ALD_PATH:?}/${1:?}"
        chattr -f -i "${ALD_PATH:?}/init/$1.sh"
        rm -rf "${ALD_PATH:?}/init/${1:?}.sh"
        rm -rf "${BOOT_PATH:?}/${1:?}"
        rm -rf "${BOOT_PATH:?}/loader/entries/${1:?}.conf"

        rm -rf "${ALD_PATH:?}/.${1:?}"
    fi

    mountpoint /usr &>/dev/null || { mount -o bind,ro /usr /usr && mount -o bind,rw /usr/local /usr/local; }
    mountpoint "${ALD_PATH:?}" &>/dev/null || mount -o bind,ro "${ALD_PATH:?}" "${ALD_PATH:?}"
    exit 1
}


apply_selinux_policy() {
    nextdep="$1"

    pprint "Relabeling deployment $1..."
    restorecon -RF "${BOOT_PATH:?}"

    setfiles -F -T "$(("$(nproc --all)"/2))" -r "${ALD_PATH:?}/$nextdep" \
        "${ALD_PATH:?}/$nextdep/etc/selinux/targeted/contexts/files/file_contexts" \
        "${ALD_PATH:?}/$nextdep" 2>/dev/null
}
