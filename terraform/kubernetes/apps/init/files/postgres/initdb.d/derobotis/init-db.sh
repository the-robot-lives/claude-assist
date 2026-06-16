#!/usr/bin/env bash
# derobotis — database + login role
if [ -z "${_PG_INITDB_LIB:-}" ]; then source "$(dirname "${BASH_SOURCE[0]}")/_lib"; fi

create_db "derobotis" "DEROBOTIS_DB_USER" "DEROBOTIS_DB_PASSWORD"
