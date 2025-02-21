#!/usr/bin/env bash


swap_deployment() {
    if [[ "$(find "${ALD_PATH:?}" -maxdepth 1 -type d -name "[0-9]*" -printf " %P ")" != *" $1 "* || -z $1 ]]; then
        fail_ex "-1" "Deployment $1 doesn't exist or can't be swapped to."
    fi
    pprint "Unlocking image storage..."
    mountpoint "${ALD_PATH:?}" &>/dev/null && umount -f "${ALD_PATH:?}" &>/dev/null

    pprint "Replacing deployment $(cat "$PREFIX/usr/.ald_dep") with $1."
    swap_dep="$(cat "$PREFIX/usr/.ald_dep")"

    chattr -i "$PREFIX/" || if [[ ! -f "/etc/initrd-release" ]]; then iprint "Couldn't unlock /."; fi

    if [[ -d "${ALD_PATH:?}/$1/usr" ]]; then
        { mountpoint "$PREFIX/usr" &>/dev/null && umount -Rfl "$PREFIX/usr"; } ||
            if [[ ! -f "/etc/initrd-release" ]]; then iprint "Couldn't temporarily remove /usr bind mount."; fi

        exch "$PREFIX/usr" "${ALD_PATH:?}/$1/usr" || fail_ex "-1" "Couldn't atomically switch deployments."
        exch "$PREFIX/etc" "${ALD_PATH:?}/$1/etc" || iprint "Couldn't atomically switch system config, system might be instable."

        mount -o bind,ro "$PREFIX/usr" "$PREFIX/usr" || iprint "Restoring /usr bind mount failed, fs is rw."

        mv "${ALD_PATH:?}/$1" "${ALD_PATH:?}/$swap_dep" || iprint "Renaming old deployment failed, naming out of sync."
    else
        mount -o loop "${ALD_PATH:?}/$1/$1.efs" "${ALD_PATH:?}/image" || fail_ex "-1" "Couldn't mount /usr image"
        mount -o bind "${ALD_PATH:?}/$1/etc" "${ALD_PATH:?}/$1/etc" || fail_ex "-1" "Couldn't mount /etc snapshot"

        if mountpoint -q "$PREFIX/usr" &>/dev/null; then
            mmb -mb "${ALD_PATH:?}/image" "$PREFIX/usr" &>/dev/null
            umount -fl "$PREFIX/usr"
        else
            mmb -m "${ALD_PATH:?}/image" "$PREFIX/usr" &>/dev/null
        fi
        if mountpoint -q "$PREFIX/etc" &>/dev/null; then
            mmb -mb "${ALD_PATH:?}/$1/etc" "$PREFIX/etc" &>/dev/null
            umount -fl "$PREFIX/etc"
        else
            mmb -m "${ALD_PATH:?}/$1/etc" "$PREFIX/etc" &>/dev/null
        fi
    fi

    mount -o bind,rw "$PREFIX/usr/local" "$PREFIX/usr/local" || iprint "Restoring /usr bind mount failed, fs is rw."
    chattr +i "$PREFIX/" || iprint "Couldn't lock /."

    pprint "Locking image storage..."
    if [[ ! -f "/etc/initrd-release" ]]; then
        mountpoint "${ALD_PATH:?}/$swap_dep/usr/local" &>/dev/null && { umount -fl "${ALD_PATH:?}/$swap_dep/usr/local" ||
            iprint "/usr/local might still be mounted to old deployment"; }
    fi
    mountpoint "${ALD_PATH:?}" &>/dev/null || mount -o bind,ro "${ALD_PATH:?}" "${ALD_PATH:?}"
}
