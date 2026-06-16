#!/usr/bin/env bash
# gotta_cc — database + login role
if [ -z "${_PG_INITDB_LIB:-}" ]; then source "$(dirname "${BASH_SOURCE[0]}")/_lib"; fi

create_db "gotta_cc" "GOTTA_CC_DB_USER" "GOTTA_CC_DB_PASSWORD"
