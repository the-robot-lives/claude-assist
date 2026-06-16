#!/usr/bin/env bash
# jailbreaking — database + login role
if [ -z "${_PG_INITDB_LIB:-}" ]; then source "$(dirname "${BASH_SOURCE[0]}")/_lib"; fi

create_db "jailbreaking" "JAILBREAKING_DB_USER" "JAILBREAKING_DB_PASSWORD"
