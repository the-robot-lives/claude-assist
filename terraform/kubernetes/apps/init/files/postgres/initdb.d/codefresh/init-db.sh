#!/usr/bin/env bash
# codefresh — database + login role
if [ -z "${_PG_INITDB_LIB:-}" ]; then source "$(dirname "${BASH_SOURCE[0]}")/_lib"; fi

create_db "codefresh" "CODEFRESH_DB_USER" "CODEFRESH_DB_PASSWORD"
