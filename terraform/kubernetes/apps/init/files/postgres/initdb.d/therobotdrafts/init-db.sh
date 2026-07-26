#!/usr/bin/env bash
# therobotdrafts (therobotdrafts.com, vnext) — database + login role
if [ -z "${_PG_INITDB_LIB:-}" ]; then source "$(dirname "${BASH_SOURCE[0]}")/_lib"; fi

create_db "therobotdrafts" "THEROBOTDRAFTS_DB_USER" "THEROBOTDRAFTS_DB_PASSWORD"
