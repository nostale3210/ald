#!/usr/bin/env bash


rm_dep() {
    pprint "Unlocking image storage..."
    mountpoint "${ALD_PATH:?}" &>/dev/null && umount -f "${ALD_PATH:?}"

    pprint "Removing deployment $1..."
    if [[ -z $1 || "$(cat /usr/.ald_dep)" == "$1" ||
        "$(find "${ALD_PATH:?}" -maxdepth 1 -type f -name ".[0-9]*" -printf " %P " | \
        sed "s/\.//g")" != *" $1 "* ]];
        then
            fail_ex "-1" "Deployment $1 doesn't exist or isn't removable."
    fi
    mountpoint "${ALD_PATH:?}/$1/usr/local" &>/dev/null && umount -f "${ALD_PATH:?}"

    rm -rf "${ALD_PATH:?}/$1" || iprint "Removing $ALD_PATH/$1 failed, manual intervention might be necessary."
    rm -rf "${BOOT_PATH:?}/$1" || iprint "Removing $BOOT_PATH/$1 failed, manual intervention might be necessary."
    rm -rf "${BOOT_PATH:?}/loader/entries/$1.conf" || iprint "Removing $BOOT_PATH/loader/entries/$1.conf failed, manual intervention might be necessary."

    rm -rf "${ALD_PATH:?}/.$1"

    mountpoint /usr &>/dev/null || { mount -o bind,ro /usr /usr && mount -o bind,rw /usr/local /usr/local; }
    pprint "Locking image storage..."
    mountpoint "${ALD_PATH:?}" &>/dev/null || mount -o bind,ro "${ALD_PATH:?}" "${ALD_PATH:?}"
}


rm_deps() {
    read -ra av_deps <<< "$(find "${ALD_PATH:?}" -maxdepth 1 -type f -name ".[0-9]*" -printf "%P " | sed "s/\.//g")"
    for av in "${av_deps[@]}"; do
        if [[ ( ! -d "${ALD_PATH:?}/$av" && "$(cat /usr/.ald_dep)" != "$av" ) ||
            ! -d "${BOOT_PATH:?}/$av" || ! -f "${BOOT_PATH:?}/loader/entries/$av.conf" ]];
                then
                    rm_dep "$av"
        fi
    done

    while [[ "$(find "${ALD_PATH:?}" -maxdepth 1 -type d -name "[0-9]*" | awk -F'/' '{print $NF}' | sort -nr | wc -l)" -gt "$((KEEP_DEPS-1))" ]]; do
        rm_dep "$(find "${ALD_PATH:?}" -maxdepth 1 -type d -name "[0-9]*" | awk -F'/' '{print $NF}' | sort -n | head -n1)"
    done
}


deduplicate_boot_files() {
    pprint "Deduplicating inactive deployments..."
    read -ra available_boot_files <<< "$(find "${BOOT_PATH:?}" -maxdepth 1 -type d -name "[0-9]*" -not -path "${BOOT_PATH:?}/$(cat "/usr/.ald_dep")" | tr "\n" " ")"
    if [[ "$tput_support" == "y" ]]; then pprint "" && tput smcup; fi
    hardlink -tXOv -s1 "${available_boot_files[@]}"
    if [[ "$tput_support" == "y" ]]; then tput rmcup && pprint ""; fi
}
