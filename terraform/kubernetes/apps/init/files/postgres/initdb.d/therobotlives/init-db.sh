#!/usr/bin/env bash
# therobotlives — database + login role
if [ -z "${_PG_INITDB_LIB:-}" ]; then source "$(dirname "${BASH_SOURCE[0]}")/_lib"; fi

create_db "therobotlives" "THEROBOTLIVES_DB_USER" "THEROBOTLIVES_DB_PASSWORD"
