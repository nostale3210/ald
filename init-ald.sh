#!/usr/bin/env bash

# invoke with `sudo bash -c "$(curl https://raw.githubusercontent.com/nostale3210/ald/main/init-ald.sh)"`

if [ "$(id -u)" != "0" ]; then
    printf "init-ald needs elevated priviledges!\n"
    exit 1
fi

ALD_PATH="${ALD_PATH:-/.ald}"
CONFIG_PATH="${CONFIG_PATH:-/etc/ald}"
FLAGS=()

mkdir -p "${CONFIG_PATH:?}"

podman cp "$(podman create --name ald-tmp ghcr.io/nostale3210/ald-utils:latest)":/ald "${ALD_PATH:?}" ||
    (printf "Installing needed files failed!\n" && exit 1)
podman rm ald-tmp

mv "${ALD_PATH:?}/ald" "/usr/bin/ald"
mv "${ALD_PATH:?}/lib" "/usr/lib/ald"
mv "${ALD_PATH:?}/Containerfile" "${CONFIG_PATH:?}"
mv "${ALD_PATH:?}/ald-config" "${CONFIG_PATH:?}"

read -rp "Is this system using selinux (enforcing)? [y/N] " use_selinux
if [ "$use_selinux" = "y" ]; then FLAGS+=(-z); fi

read -rp "Edit and build local containerfile? [y/N] " use_local
if [ "$use_local" = "y" ]; then FLAGS+=(-b) && "${EDITOR:-nano}" "${CONFIG_PATH:?}/Containerfile"; fi

read -rp "Edit configuration file before installation? [y/N] " edit_file
if [ "$edit_file" = "y" ]; then "${EDITOR:-nano}" "${ALD_PATH:?}/ald-config"; fi

/usr/bin/ald init "${FLAGS[@]}"
