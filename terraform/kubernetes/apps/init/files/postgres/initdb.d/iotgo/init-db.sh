#!/usr/bin/env bash
# iotgo — database + login role
if [ -z "${_PG_INITDB_LIB:-}" ]; then source "$(dirname "${BASH_SOURCE[0]}")/_lib"; fi

create_db "iotgo" "IOTGO_DB_USER" "IOTGO_DB_PASSWORD"
