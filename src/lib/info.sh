#!/usr/bin/env


print_help() {
    printf "\033[1m\033[4mALD\033[24m\tApply & manage container image based os deployments\033[0m\n\n"
    printf "\033[1mUsage:\033[0m\tald SUBCOMMAND [OPTIONS]... [ARGUMENTS]...\n\n"
    printf "\033[1mSubcommands:\033[0m\n"
    printf "\thelp\t\tPrint this menu\n"
    printf "\tstatus\t\tPrint active and available deployments and their versions\n"
    printf "\tpull\t\tPull the newest version of the upstream container image, if a new version is available\n"
    printf "\tbuild\t\tBuild a Containerfile in /etc/ald\n"
    printf "\tswap\t\tReplace the currently active deployment with another specified, available one\n"
    printf "\trm\t\tRemove a specified, available deployment\n"
    printf "\tgc\t\tRemove old deployments until only n=KEEP_DEPS remain\n"

    printf "\tdep\t\tDeploy new versions\n"
    printf "\t\t\tOptions:\n"
    printf "\t\t\t\t-u\tPull newest image before deploying\n"
    printf "\t\t\t\t\t(Same as \`ald pull\`)\n"
    printf "\t\t\t\t-b\tBuild the local Containerfile before deploying\n"
    printf "\t\t\t\t\tCurrently required for the local image to be used\n"
    printf "\t\t\t\t\t(Same as \`ald build\`)\n"
    printf "\t\t\t\t-s\tSwap to the new deployment immediately after building\n"
    printf "\t\t\t\t\t(Same as \`ald swap DEPLOYMENT\`)\n"
    printf "\t\t\t\t-g\tTrigger gc after deploying\n"
    printf "\t\t\t\t\t(Same as \`ald gc\`)\n"
    printf "\t\t\t\t-z\tRelabel files according to the new deployment's selinux policy\n"

    printf "\tinit\t\tInitialise ALD on a system\n"
    printf "\t\t\tOptions:\n"
    printf "\t\t\t\t-b\tBuild the local Containerfile before initialising\n"
    printf "\t\t\t\t\tCurrently required for the local image to be used\n"
    printf "\t\t\t\t\t(Same as \`ald build\`)\n"
    printf "\t\t\t\t-z\tRelabel files according to the new deployment's selinux policy\n"
    printf "\t\t\t\t--ex\tUse a customised %s,\n\t\t\t\t\tit will be used instead of an automatically generated entry\n" "${ALD_PATH:?}/boot.conf.ex"

    printf "\tbootloader_update\tUpdate the system's bootloader\n"
    printf "\t\t\tOptions (one is required):\n"
    printf "\t\t\t\t--fg\tUpdate grub on fedora x86_64 systems\n"
}


print_status() {
    read -ra available_deployments <<< "$(find "${ALD_PATH:?}" -maxdepth 1 -type d -name "[0-9]*" | awk -F'/' '{print $NF}' | sort -nr | tr "\n" " ")"
    depl_version="$(grep ^VERSION= < "/usr/lib/os-release" | cut -d'=' -f2)"
    depl_name="$(grep ^NAME= < "/usr/lib/os-release" | cut -d'=' -f2)"

    printf "\033[1mCurrently active deployment:\033[0m\n\n"
    printf "\t\033[1m\033[4m%s\033[0m\t\u2500\u2500\u2500\tName: %s\n" "$(cat "/usr/.ald_dep")" "$depl_name"
    printf "\t\t\tVersion: %s\n" "$depl_version"
    printf "\t\t\tKernel: \"%s\"\n\n\n" "$(find "/usr/lib/modules" -maxdepth 1 -type d | sort | tail -n1 | awk -F'/' '{ print $NF }')"

    printf "\033[1mOther available deployments:\033[0m\n\n"
    for depl in "${available_deployments[@]}"; do
        depl_version="$(grep ^VERSION= < "${ALD_PATH:?}/$depl/usr/lib/os-release" | cut -d'=' -f2)"
        depl_name="$(grep ^NAME= < "${ALD_PATH:?}/$depl/usr/lib/os-release" | cut -d'=' -f2)"
        printf "\t\033[1m%s\033[0m\t\u2500\u2500\u2500\tName: %s\n" "$depl" "$depl_name"
        printf "\t\t\tVersion: %s\n" "$depl_version"
        printf "\t\t\tKernel: \"%s\"\n\n" "$(find "${ALD_PATH:?}/$depl/usr/lib/modules" -maxdepth 1 -type d | sort | tail -n1 | awk -F'/' '{ print $NF }')"
    done
}


show_updates() {
    rpm --version &>/dev/null || fail_ex "-1" "Currently only rpm-based systems are supported."
    if [[ "$(find "${ALD_PATH:?}" -maxdepth 1 -type d -printf "%P ")" != *"$1"* && "$1" != "$(cat "/usr/.ald_dep")" ]]; then
        fail_ex "-1" "No such deployment: $1."
    elif [[ "$(find "${ALD_PATH:?}" -maxdepth 1 -type d -printf "%P ")" != *"$2"* && "$2" != "$(cat "/usr/.ald_dep")" ]]; then
        fail_ex "-1" "No such deployment: $2."
    fi
    FALLBACK="$(find "${ALD_PATH:?}" -maxdepth 1 -type d -name "[0-9]*" | awk -F'/' '{print $NF}' | sort -n | tail -n1)"
    if [[ -n "$1" && "$1" != "$(cat "/usr/.ald_dep")" ]]; then OLD_DEP="${ALD_PATH:?}/$1"; else OLD_DEP="${ALD_PATH:?}/$FALLBACK"; fi
    if [[ -n "$2" && "$2" != "$(cat "/usr/.ald_dep")" ]]; then NEW_DEP="${ALD_PATH:?}/$2"; else NEW_DEP="/"; fi
    iprint "Comparing $OLD_DEP and $NEW_DEP:"
    rpm -qa --root="$OLD_DEP" | sort > "$HOME/.old" || { rm "$HOME/.old" && fail_ex "-1" "Couldn't retrieve packages from $OLD_DEP."; }
    rpm -qa --root="$NEW_DEP" | sort > "$HOME/.new" || { rm "$HOME/"{.old,.new} && fail_ex "-1" "Couldn't retrieve packages from $NEW_DEP."; }
    diff -y "$HOME/.old" "$HOME/.new" | grep "|\|>\|<" || pprint "There doesn't seem to be a difference bewteen $OLD_DEP and $NEW_DEP."
    rm "$HOME/"{.old,.new} || iprint "Failed to delete temporary files."
}
