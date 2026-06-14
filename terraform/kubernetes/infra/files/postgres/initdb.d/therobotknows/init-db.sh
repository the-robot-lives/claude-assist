#!/usr/bin/env bash
# therobotknows — database + login role
if [ -z "${_PG_INITDB_LIB:-}" ]; then source "$(dirname "${BASH_SOURCE[0]}")/_lib"; fi

create_db "therobotknows" "THEROBOTKNOWS_DB_USER" "THEROBOTKNOWS_DB_PASSWORD"
