# bash completion for infra-config.
#
# Install (either works):
#   1. Copy to ${XDG_DATA_HOME:-~/.local/share}/bash-completion/completions/infra-config
#      (done by `make install-completions`; auto-loaded by bash-completion v2).
#   2. Source this file from .bashrc.

__infra_config_resources() {
    echo "helm-dir helm-alias namespace timeout tier-chart docker-image docker-dir project service docker-group"
}

__infra_config_keys() {
    local r="$1"
    [ -z "$r" ] && return
    # Call infra-config list <resource> and strip ANSI / headers / separators.
    # Guard: missing infra-config or error ⇒ emit nothing.
    infra-config list "$r" 2>/dev/null \
        | sed $'s/\x1b\\[[0-9;]*m//g' \
        | awk '/▶/ || /─/ {next} /^  [A-Z]/ {next} NF==0 {next} {print $1}'
}

_infra_config() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    COMPREPLY=()

    local global_flags="--config --dry-run --yes -y --assist -h --help"

    # Flags whose value is the next word.
    case "$prev" in
        --config) COMPREPLY=($(compgen -f -- "$cur")); return ;;
        --assist) return ;;
    esac

    # Handle --config= form.
    case "$cur" in
        --config=*) COMPREPLY=($(compgen -f -P "--config=" -- "${cur#--config=}")); return ;;
    esac

    # Locate the action (first non-flag word after infra-config).
    local action="" cmd_i=0 i w
    for ((i = 1; i < COMP_CWORD; i++)); do
        w="${COMP_WORDS[i]}"
        case "$w" in
            --config) ((i++)) ;;
            -*) ;;
            *) action="$w"; cmd_i=$i; break ;;
        esac
    done

    if [[ -z "$action" ]]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "$global_flags" -- "$cur"))
        else
            COMPREPLY=($(compgen -W "list add remove" -- "$cur"))
        fi
        return
    fi

    # Locate the resource (second non-flag word).
    local resource="" res_i=0
    for ((i = cmd_i + 1; i < COMP_CWORD; i++)); do
        w="${COMP_WORDS[i]}"
        case "$w" in
            --config) ((i++)) ;;
            -*) ;;
            *) resource="$w"; res_i=$i; break ;;
        esac
    done

    if [[ -z "$resource" ]]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "$global_flags" -- "$cur"))
        else
            COMPREPLY=($(compgen -W "$(__infra_config_resources)" -- "$cur"))
        fi
        return
    fi

    # Third positional: existing keys (for add/remove only).
    case "$action" in
        add|remove)
            if [[ "$cur" != -* ]]; then
                COMPREPLY=($(compgen -W "$(__infra_config_keys "$resource")" -- "$cur"))
            fi
            return ;;
        list)
            return ;;
    esac
}

complete -F _infra_config infra-config
