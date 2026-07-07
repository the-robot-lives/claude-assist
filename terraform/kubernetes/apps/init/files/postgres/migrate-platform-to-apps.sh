#!/usr/bin/env bash
# Generates SQL to bootstrap app-timescaledb roles/grants.
# Run this locally, copy the output, paste into psql on the pod.

cat <<SQL
-- aifighter
CREATE ROLE aifighter WITH LOGIN PASSWORD '$(dc get services apps.aifighter_db_password --reveal --raw 2>/dev/null)';
ALTER DATABASE aifighter OWNER TO aifighter;
GRANT ALL PRIVILEGES ON DATABASE aifighter TO aifighter;

-- derobotis
CREATE ROLE derobotis WITH LOGIN PASSWORD '$(dc get services apps.derobotis_db_password --reveal --raw 2>/dev/null)';
ALTER DATABASE derobotis OWNER TO derobotis;
GRANT ALL PRIVILEGES ON DATABASE derobotis TO derobotis;

-- gotta_cc
CREATE ROLE gotta_cc WITH LOGIN PASSWORD '$(dc get services apps.gotta_cc_db_password --reveal --raw 2>/dev/null)';
ALTER DATABASE gotta_cc OWNER TO gotta_cc;
GRANT ALL PRIVILEGES ON DATABASE gotta_cc TO gotta_cc;

-- iotgo
CREATE ROLE iotgo WITH LOGIN PASSWORD '$(dc get services apps.iotgo_db_password --reveal --raw 2>/dev/null)';
ALTER DATABASE iotgo OWNER TO iotgo;
GRANT ALL PRIVILEGES ON DATABASE iotgo TO iotgo;

-- jailbreaking
CREATE ROLE jailbreaking WITH LOGIN PASSWORD '$(dc get services apps.jailbreaking_db_password --reveal --raw 2>/dev/null)';
ALTER DATABASE jailbreaking OWNER TO jailbreaking;
GRANT ALL PRIVILEGES ON DATABASE jailbreaking TO jailbreaking;

-- noizu_site
CREATE ROLE noizu_site WITH LOGIN PASSWORD '$(dc get services apps.noizu_site_db_password --reveal --raw 2>/dev/null)';
ALTER DATABASE noizu_site OWNER TO noizu_site;
GRANT ALL PRIVILEGES ON DATABASE noizu_site TO noizu_site;

-- therobotknows
CREATE ROLE therobotknows WITH LOGIN PASSWORD '$(dc get services apps.therobotknows_db_password --reveal --raw 2>/dev/null)';
ALTER DATABASE therobotknows OWNER TO therobotknows;
GRANT ALL PRIVILEGES ON DATABASE therobotknows TO therobotknows;

-- therobotlives
CREATE ROLE therobotlives WITH LOGIN PASSWORD '$(dc get services apps.therobotlives_db_password --reveal --raw 2>/dev/null)';
ALTER DATABASE therobotlives OWNER TO therobotlives;
GRANT ALL PRIVILEGES ON DATABASE therobotlives TO therobotlives;

-- therobotplans
CREATE ROLE therobotplans WITH LOGIN PASSWORD '$(dc get services apps.therobotplans_db_password --reveal --raw 2>/dev/null)';
ALTER DATABASE therobotplans OWNER TO therobotplans;
GRANT ALL PRIVILEGES ON DATABASE therobotplans TO therobotplans;

-- ddi (designing.derobot.is)
CREATE ROLE ddi WITH LOGIN PASSWORD '$(dc get services apps.ddi_db_password --reveal --raw 2>/dev/null)';
CREATE DATABASE designing_derobot_is_dev OWNER ddi;
GRANT ALL PRIVILEGES ON DATABASE designing_derobot_is_dev TO ddi;

-- startapp (role exists, update password + own start_app db)
ALTER ROLE startapp WITH PASSWORD '$(dc get services apps.startapp_db_password --reveal --raw 2>/dev/null)';
ALTER DATABASE start_app OWNER TO startapp;
GRANT ALL PRIVILEGES ON DATABASE start_app TO startapp;
SQL
