#!/usr/bin/env bash
# tobornalp — database + login role
if [ -z "${_PG_INITDB_LIB:-}" ]; then source "$(dirname "${BASH_SOURCE[0]}")/_lib"; fi

create_db "tobornalp" "TOBORNALP_DB_USER" "TOBORNALP_DB_PASSWORD"
