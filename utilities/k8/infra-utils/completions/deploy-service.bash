# bash completion for deploy-service.
#
# Install (either works):
#   1. Copy to ${XDG_DATA_HOME:-~/.local/share}/bash-completion/completions/deploy-service
#      (done by `make install-completions`; auto-loaded by bash-completion v2).
#   2. Source this file from .bashrc.

__deploy_service_image_keys() {
    local f="$PWD"
    # Walk up from $PWD to the repo root (first dir holding .infra-config.yaml).
    # Guard: missing yq or config ⇒ emit nothing.
    while [[ "$f" != "/" ]]; do
        if [[ -f "$f/.infra-config.yaml" ]]; then
            yq '.project.projects[].services[].name, .project.docker.images[].name' "$f/.infra-config.yaml" 2>/dev/null | sort -u
            return
        fi
        f="${f%/*}"
    done
}

_deploy_service() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    COMPREPLY=()

    # Flags whose value is the next word.
    case "$prev" in
        --tag)    return ;;
        --env)    COMPREPLY=($(compgen -W "dev stage prod" -- "$cur")); return ;;
        --config) COMPREPLY=($(compgen -f -- "$cur")); return ;;
    esac

    # Handle --flag= forms (bash-completion passes the whole token as cur).
    case "$cur" in
        --env=*)    COMPREPLY=($(compgen -W "dev stage prod" -P "--env=" -- "${cur#--env=}")); return ;;
        --config=*) COMPREPLY=($(compgen -f -P "--config=" -- "${cur#--config=}")); return ;;
        --tag=*)    return ;;
    esac

    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--tag --no-cache --skip-build --skip-deploy --stage --prod --dev --env --yes -y --dry-run --config -v --verbose -h --help" -- "$cur"))
        return
    fi

    # Positional: repeatable image keys.
    COMPREPLY=($(compgen -W "$(__deploy_service_image_keys)" -- "$cur"))
}

complete -F _deploy_service deploy-service
