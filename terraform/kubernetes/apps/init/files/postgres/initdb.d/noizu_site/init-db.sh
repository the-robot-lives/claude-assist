#!/usr/bin/env bash
# noizu_site — database + login role
if [ -z "${_PG_INITDB_LIB:-}" ]; then source "$(dirname "${BASH_SOURCE[0]}")/_lib"; fi

create_db "noizu_site" "NOIZU_SITE_DB_USER" "NOIZU_SITE_DB_PASSWORD"
