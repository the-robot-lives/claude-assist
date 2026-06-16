#!/usr/bin/env bash
# keygen — database + login role
if [ -z "${_PG_INITDB_LIB:-}" ]; then source "$(dirname "${BASH_SOURCE[0]}")/_lib"; fi

create_db "keygen" "KEYGEN_DB_USER" "KEYGEN_DB_PASSWORD"
