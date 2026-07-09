#!/usr/bin/env bash
# foryou — database + login role
if [ -z "${_PG_INITDB_LIB:-}" ]; then source "$(dirname "${BASH_SOURCE[0]}")/_lib"; fi

create_db "foryou" "FORYOU_DB_USER" "FORYOU_DB_PASSWORD"
