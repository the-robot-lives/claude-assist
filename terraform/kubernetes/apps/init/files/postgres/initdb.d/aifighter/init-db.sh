#!/usr/bin/env bash
# aifighter — database + login role
if [ -z "${_PG_INITDB_LIB:-}" ]; then source "$(dirname "${BASH_SOURCE[0]}")/_lib"; fi

create_db "aifighter" "AIFIGHTER_DB_USER" "AIFIGHTER_DB_PASSWORD"
