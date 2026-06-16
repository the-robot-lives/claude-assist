#!/usr/bin/env bash
# therobotplans — database + login role
if [ -z "${_PG_INITDB_LIB:-}" ]; then source "$(dirname "${BASH_SOURCE[0]}")/_lib"; fi

create_db "therobotplans" "THEROBOTPLANS_DB_USER" "THEROBOTPLANS_DB_PASSWORD"
