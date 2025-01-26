#!/usr/bin/env


pull_image() {
    pprint "Checking for updates..."
    installed_image="$(podman inspect --format '{{.Digest}}' "$SOURCE_IMAGE" 2>/dev/null)"
    remote_image="$(skopeo inspect --format '{{.Digest}}' "docker://$SOURCE_IMAGE" 2>/dev/null)"

    if [[ "$installed_image" == "$remote_image" ]]; then
        iprint "Latest image already pulled."
        exit 0
    else
        pprint "Pulling $SOURCE_IMAGE..."
        if [[ "$tput_support" == "y" ]]; then pprint "" && tput smcup; fi
        podman pull "$SOURCE_IMAGE" || fail_ex "-1" "Pulling image failed."
        if [[ "$tput_support" == "y" ]]; then tput rmcup; fi
    fi
}


build_image() {
    pprint "Building local image..."
    if [[ "$tput_support" == "y" ]]; then pprint "" && tput smcup; fi
    podman build --build-arg=SOURCE_IMAGE="$SOURCE_IMAGE" -t "$LOCAL_TAG" "${CONFIG_PATH:?}" || fail_ex "-1" "Building image failed."
    if [[ "$tput_support" == "y" ]]; then pprint "Finished building image..." && tput rmcup; fi
}


sync_image() {
    MOUNTC="$1"
    next_id="$2"

    rsync -ac -f"+ */" -f"- *" --delete "$MOUNTC"/{usr,etc} "${ALD_PATH:?}/image/" &>/dev/null || fail_ex \
        "$next_id" "Couldn't sync directory hierarchy."

    sync_batch() {
        rsync -aHlcx --delete --relative "$@" "${ALD_PATH:?}/image/" &>/dev/null || fail_ex "$next_id" "Couldn't sync files."
    }

    export -f sync_batch
    export -f fail_ex
    export ALD_PATH
    find "$MOUNTC"/{usr,etc} ! -type d -printf "%s\t%p\0" | sort -znr | cut -z -f2- | \
        sed -z "s|^\($MOUNTC\)|\1/.|g" | \
        xargs -0 -n5000 -P"$(("$(nproc --all)"/2))" bash -c 'sync_batch "$@"' _ &>/dev/null
    unset -f sync_batch

    comm -z23 <(find "${ALD_PATH:?}/image"/{usr,etc} -print0 | sed -z "s|^${ALD_PATH:?}/image||g" | sort -z) \
        <(find "$MOUNTC"/{usr,etc} -print0 | sed -z "s|^$MOUNTC||g" | sort -z) | \
        sed -z "s|^|${ALD_PATH:?}/image|g" | xargs -0 rm -rf &>/dev/null
}


init_ald() {
    shift

    echo "0" > "/usr/.ald_dep"
    boot_conf="$(find "${BOOT_PATH:?}/loader/entries" | sort | tail -n1)"
    if [[ "$*" == *"--ex"* ]]; then
        mv -f "${ALD_PATH:?}/boot.conf.ex" "${ALD_PATH:?}/boot.conf"
    else
        cp -fa "$boot_conf" "${ALD_PATH:?}/boot.conf" || fail_ex "-1" "Automatic boot entry creation failed."
        { grep -q title "${ALD_PATH:?}/boot.conf" && sed -i "s/^title .*$/title ALD Deployment INSERT_DEPLOYMENT/g" "${ALD_PATH:?}/boot.conf"; } || fail_ex "-1" "Automatic boot entry creation failed."
        { grep -q version "${ALD_PATH:?}/boot.conf" && sed -i "s/^version .*$/version INSERT_DEPLOYMENT/g" "${ALD_PATH:?}/boot.conf"; } || fail_ex "-1" "Automatic boot entry creation failed."
        { grep -q linux "${ALD_PATH:?}/boot.conf" && sed -i "s/^linux .*$/linux \/INSERT_DEPLOYMENT\/vmlinuz/g" "${ALD_PATH:?}/boot.conf"; } || fail_ex "-1" "Automatic boot entry creation failed."
        { grep -q initrd "${ALD_PATH:?}/boot.conf" && sed -i "s/^initrd .*$/initrd \/INSERT_DEPLOYMENT\/initramfs.img/g" "${ALD_PATH:?}/boot.conf"; } || fail_ex "-1" "Automatic boot entry creation failed."
        { grep -q options "${ALD_PATH:?}/boot.conf" && sed -i "s/^options \(.*\)$/options \1 ald.boot=INSERT_DEPLOYMENT/g" "${ALD_PATH:?}/boot.conf"; } || fail_ex "-1" "Automatic boot entry creation failed."
    fi

    if [[ "$*" == "-"*"b"* ]]; then build_image && SOURCE_IMAGE="$LOCAL_TAG"; fi
    STATE="drop"
    setup_dep
    if [[ "$*" == "-"*"z"* ]]; then apply_selinux_policy "1"; fi

    pprint "ALD initialised. Rebooting once is needed after initializing/switching image."
}
