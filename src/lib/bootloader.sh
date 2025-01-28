#!/usr/bin/env


# Check for and init bootloader update for specific distro
update_bootloader() {
    if [[ "$*" == *"--fg"* ]]; then
        fedora_grub
    else
        iprint "No bootloader seems to be available for this configuration."
    fi
}


# Bootloader update for fedora grub2-x86_64
fedora_grub() {
    mkdir "${ALD_PATH:?}/tmp-boot"
    cat > "${ALD_PATH:?}/tmp-boot/Containerfile" << EOF
FROM "${SOURCE_IMAGE}"

RUN { sudo dnf5 reinstall -y grub2-efi-x64.x86_64 || sudo dnf5 install -y grub2-efi-x64.x86_64 } || { echo "Couldn't install grub!" && exit 1 }

RUN { dnf5 reinstall -y shim-x64.x86_64 || sudo dnf5 install -y shim-x64.x86_64 } || { echo "Couldn't install shim!" && exit 1 }
EOF
    podman build -t localhost/ald-boot "${ALD_PATH:?}/tmp-boot" || fail_ex "-1" "Couldn't create image."
    podman create --name ald-boot localhost/ald-boot &>/dev/null || fail_ex "-1" "Couldn't sync files."

    if [[ "$?" != "0" ]]; then fail_ex "-1" "Failed to fetch bootloader components."; fi
    podman cp ald-boot:/boot/efi/EFI/fedora/shimx64.efi "${EFI_PATH:?}" ||
        fail_ex "-1" "Failed to retrieve bootloader components."
    podman cp ald-boot:/boot/efi/EFI/fedora/grubx64.efi "${EFI_PATH:?}" ||
        fail_ex "-1" "Failed to retrieve bootloader components."
    podman cp ald-boot:/boot/efi/EFI/fedora/mmx64.efi "${EFI_PATH:?}" ||
        fail_ex "-1" "Failed to retrieve bootloader components."
    podman cp ald-boot:/boot/efi/EFI/fedora/BOOTX64.CSV "${EFI_PATH:?}" ||
        fail_ex "-1" "Failed to retrieve bootloader components."
    podman cp ald-boot:/boot/efi/EFI/BOOT/fbx64.efi "${EFI_PATH:?}" ||
        fail_ex "-1" "Failed to retrieve bootloader components."

    pprint "Updating shim..."
    cp "${EFI_PATH:?}/shimx64.efi" "${EFI_PATH:?}/shimx64.efi.bak" ||
        fail_ex "-1" "Failed to prepare bootloader components."
    cp "${EFI_PATH:?}/shimx64.efi" "${EFI_PATH:?}/shimx64.efi.bak.bak" ||
        fail_ex "-1" "Failed to prepare bootloader components."
    exch "${EFI_PATH:?}/shimx64.efi" "${EFI_PATH:?}/EFI/BOOT/BOOTX64.EFI" ||
        fail_ex "-1" "Failed to place bootloader components."
    exch "${EFI_PATH:?}/shimx64.efi.bak" "${EFI_PATH:?}/EFI/fedora/shim.efi" ||
        iprint "Failed to place bootloader components."
    exch "${EFI_PATH:?}/shimx64.efi.bak.bak" "${EFI_PATH:?}/EFI/fedora/shimx64.efi" ||
        iprint "Failed to place bootloader components."
    rm "${EFI_PATH:?}"/{shimx64.efi,shimx64.efi.bak,shimx64.efi.bak.bak} ||
        iprint "Failed to cleanup bootloader components."

    pprint "Updating grub..."
    exch "${EFI_PATH:?}/grubx64.efi" "${EFI_PATH:?}/EFI/fedora/grubx64.efi" ||
        iprint "Failed to place bootloader components."
    exch "${EFI_PATH:?}/mmx64.efi" "${EFI_PATH:?}/EFI/fedora/mmx64.efi" ||
        iprint "Failed to place bootloader components."
    exch "${EFI_PATH:?}/BOOTX64.CSV" "${EFI_PATH:?}/EFI/fedora/BOOTX64.CSV" ||
        iprint "Failed to place bootloader components."
    exch "${EFI_PATH:?}/fbx64.efi" "${EFI_PATH:?}/EFI/BOOT/fbx64.efi" ||
        iprint "Failed to place bootloader components."
    rm "${EFI_PATH:?}"/{grubx64.efi,mmx64.efi,BOOTX64.CSV,fbx64.efi} ||
        iprint "Failed to cleanup bootloader components."

    podman rm ald-boot &>/dev/null || iprint "Failed to remove container ald-boot."
    podman rmi localhost/ald-boot &>/dev/null || iprint "Failed to remove image localhost/ald-boot."
    rm -rf "${ALD_PATH:?}/tmp-boot" &>/dev/null
    pprint "Update complete!"
}
