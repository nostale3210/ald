#!/usr/bin/env bash


hash_usr() {
    hash_path() {
        file_path="$1"
        if file_hash="$(cksum -a blake2b --untagged "$file_path" 2>/dev/null)"; then
            printf "$file_hash\n" >> /files
        fi
    }

    pprint "Storing files by hash..."

    export -f hash_path

    printf "" > /files
    find /usr ! -type d -print0 | shuf -z | xargs -0 -n1 -P"$(("$(nproc --all)"**2))" \
        bash -c 'hash_path "$@"' _

    unset -f hash_path
}


verify_usr() {
    dep="$1"

    if [[ "$(find "${ALD_PATH:?}" -maxdepth 1 -type d -name ".[0-9]*" -printf " %P ")" != *" $dep "* &&
        -z $1 && "$(cat /usr/.ald_dep)" != "$dep" ]]; then
            fail_ex "-1" "Deployment $dep doesn't seem to exist."
    fi

    if [[ ! -s "${ALD_PATH:?}/.$dep" ]]; then
        fail_ex "-1" "No file list was found for deployment $dep."
    fi

    pprint ""
    iprint "Verifying checksums of deployment $dep..."

    if [[ "$(cat /usr/.ald_dep)" != "$dep" ]]; then
        tmp="\\${ALD_PATH:?}"
        csums="$(cat "${ALD_PATH:?}/.$dep" | sed "s/^\([0-9A-Za-z]*\s*\)/\1$tmp\/$dep/")"
    else
        csums="$(cat "${ALD_PATH:?}/.$dep")"
    fi

    { cksum -a blake2b -c <<< "$csums" | grep -v OK ; } || iprint "No mismatches found!"
}
