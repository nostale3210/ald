#!/usr/bin/env bash


get_id() {
    current_id="$(cat "/usr/.ald_dep")"
    max_id="$(find "${ALD_PATH:?}" -maxdepth 1 -type d -name "[0-9]*" | awk -F'/' '{print $NF}' | sort -n | tail -n1)"
    max_id="$(echo "$current_id" "$max_id" | tr " " "\n" | sort -n | tail -n1)"
    echo "$((max_id+1))"
}


create_deployment() {
    next_id="$1"

    podman cp -a ald-tmp:/files "${ALD_PATH:?}/.$next_id" &>/dev/null || { iprint "No file list found. Skipping..." &&
        { touch "${ALD_PATH:?}/.$next_id" ||
            fail_ex "$next_id" "Couldn't create lockfile for deployment $next_id."
        }
    }

    mkdir -p "${ALD_PATH:?}/$next_id/usr" || fail_ex "$next_id" "Couldn't create deployment root."
    mkdir -p "${BOOT_PATH:?}/$next_id" || fail_ex "$next_id" "Couldn't create deployment boot directory."

    pprint "Creating deployment $next_id..."
    rsync -aHlx --link-dest="../../image/usr/" "${ALD_PATH:?}/image/usr/" "${ALD_PATH:?}/$next_id/usr/" || fail_ex "$next_id" "Couldn't sync files."
    echo "$next_id" > "${ALD_PATH:?}/$next_id/usr/.ald_dep" || iprint "Saving new deployment failed, naming out of sync."
    rsync -aHlx "${ALD_PATH:?}/image/etc" "${ALD_PATH:?}/$next_id" || fail_ex "$next_id" "Couldn't sync files."
}


reset_state() {
    pprint "Syncing absolutely required config..."
    cp -rfa --parents /etc/fstab /etc/crypttab /etc/locale.conf /etc/localtime /etc/adjtime \
        /etc/sudoers.d /etc/group /etc/gshadow /etc/subgid /etc/subuid \
        /etc/NetworkManager/system-connections /etc/vconsole.conf /etc/pki \
        /etc/firewalld /etc/environment /etc/hostname \
        /etc/X11/xorg.conf.d/00-keyboard.conf /etc/sudoers /etc/ald \
        "${ALD_PATH:?}/$1/" || fail_ex "$1" "Resetting /etc failed."
}


system_config() {
    next_id="$1"

    pprint "Syncing system configuration..."
    if [[ "$STATE" == "drop" ]]; then
        reset_state "$next_id"
    else
        rsync -aHlx /etc "${ALD_PATH:?}/$next_id" || fail_ex "$next_id" "Couldn't place system config."
    fi
    podman cp ald-tmp:/etc/passwd "${ALD_PATH:?}" || fail_ex "$next_id" "Couldn't place system config."
    podman cp ald-tmp:/etc/shadow "${ALD_PATH:?}" || fail_ex "$next_id" "Couldn't place system config."

    sort /etc/passwd "${ALD_PATH:?}/passwd" | awk -F':' '!a[$1]++' > "$ALD_PATH/$next_id/etc/passwd" || fail_ex "$next_id" "Couldn't place system config."
    sort /etc/shadow "${ALD_PATH:?}/shadow" | awk -F':' '!a[$1]++' > "$ALD_PATH/$next_id/etc/shadow" || fail_ex "$next_id" "Couldn't place system config."
    rm "${ALD_PATH:?}"/{passwd,shadow} || fail_ex "$next_id" "Couldn't place system config."
}


boot_entry() {
    next_id="$1"

    new_kernel="$(find "${ALD_PATH:?}/$next_id/usr/lib/modules" -name vmlinuz | sort | tail -n1)" || fail_ex "$next_id" "Couldn't place new kernel."
    new_init="$(find "${ALD_PATH:?}/$next_id/usr/lib/modules" -name initramfs.img | sort | tail -n1)" || fail_ex "$next_id" "Couldn't place new initramfs."
    cp -rfa "$new_kernel" "${BOOT_PATH:?}/$next_id" || fail_ex "$next_id" "Couldn't place new kernel."
    cp -rfa "$new_init" "${BOOT_PATH:?}/$next_id" || fail_ex "$next_id" "Couldn't place new initramfs."

    deduplicate_boot_files

    pprint "Preparing boot entry..."
    cp -rfa "${ALD_PATH:?}/boot.conf" "${BOOT_PATH:?}/loader/entries/$next_id.conf" || fail_ex "$next_id" "Couldn't place boot config."
    sed -i "s@INSERT_DEPLOYMENT@$next_id@g" "${BOOT_PATH:?}/loader/entries/$next_id.conf" || fail_ex "$next_id" "Placing template files for $ID failed."
}


setup_dep() {
    shift
    if [[ "$*" == "-"*"u"* ]]; then pull_image; fi
    if [[ "$*" == "-"*"b"* ]]; then build_image && sleep 1 && SOURCE_IMAGE="$LOCAL_TAG"; fi

    pprint "Retrieving vars..."
    next_id="$(get_id)"

    trap 'fail_ex $next_id "Failed to create deployment."' INT TERM

    pprint "Unlocking image storage..."
    mountpoint "${ALD_PATH:?}" &>/dev/null && umount -f "${ALD_PATH:?}"

    pprint "Syncing image root to fs..."
    podman create --replace --name ald-tmp "$SOURCE_IMAGE" &>/dev/null || fail_ex "$next_id" "Couldn't sync files."
    MOUNTC="$(podman mount ald-tmp)"
    mkdir -p "${ALD_PATH:?}/image"
    sync_image "$MOUNTC" "$next_id"
    podman unmount ald-tmp &>/dev/null || iprint "Temporary container still mounted!"

    create_deployment "$next_id"

    system_config "$next_id"

    podman rm ald-tmp &>/dev/null || fail_ex "$next_id" "Couldn't remove temporary container."

    if [[ "$*" == "-"*"z"* ]]; then apply_selinux_policy "$next_id"; fi

    boot_entry "$next_id"

    if [[ "$*" == "-"*"s"* ]]; then swap_deployment "$next_id"; fi
    if [[ "$*" == "-"*"g"* ]]; then rm_deps; fi

    pprint "Deployment $next_id installed!"

    pprint "Locking image storage..."
    mountpoint "${ALD_PATH:?}" &>/dev/null || mount -o bind,ro "${ALD_PATH:?}" "${ALD_PATH:?}"
}
