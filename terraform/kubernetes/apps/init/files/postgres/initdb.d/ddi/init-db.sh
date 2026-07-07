#!/usr/bin/env bash
# ddi (designing.derobot.is) — database + login role
if [ -z "${_PG_INITDB_LIB:-}" ]; then source "$(dirname "${BASH_SOURCE[0]}")/_lib"; fi

create_db "designing_derobot_is_dev" "DDI_DB_USER" "DDI_DB_PASSWORD"
