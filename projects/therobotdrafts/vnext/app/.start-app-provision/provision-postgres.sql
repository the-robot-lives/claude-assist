DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'holograph') THEN
    CREATE ROLE "holograph" LOGIN PASSWORD 'S1LiXAGRMO5gD6xufzsDXtvg7-DPl3hd9RuKD86V7atznPpt';
  ELSE
    ALTER ROLE "holograph" LOGIN PASSWORD 'S1LiXAGRMO5gD6xufzsDXtvg7-DPl3hd9RuKD86V7atznPpt';
  END IF;
END
$$;

SELECT 'CREATE DATABASE "therobotdrafts_dev" OWNER "holograph"'
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'therobotdrafts_dev')\gexec

GRANT ALL PRIVILEGES ON DATABASE "therobotdrafts_dev" TO "holograph";
