#!/usr/bin/env bash
# startapp — database + login role
if [ -z "${_PG_INITDB_LIB:-}" ]; then source "$(dirname "${BASH_SOURCE[0]}")/_lib"; fi

create_db "start_app" "START_APP_DB_USER" "START_APP_DB_PASSWORD"
