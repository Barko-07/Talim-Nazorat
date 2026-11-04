-- Run as the postgres superuser:  sudo -u postgres psql < setup.sql
-- Then set passwords:  \password individ_owner   and   \password individ_app
--
-- Two roles, least privilege:
--   individ_owner  owns the schema; used only for `python -m app.cli init-db` and migrations.
--   individ_app    used by the running API: read/write data, but the audit log is
--                  append-only (no UPDATE/DELETE) and it cannot change the schema.

CREATE ROLE individ_owner LOGIN;
CREATE ROLE individ_app LOGIN;
CREATE DATABASE individ OWNER individ_owner ENCODING 'UTF8';
\connect individ

REVOKE ALL ON DATABASE individ FROM PUBLIC;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT CONNECT ON DATABASE individ TO individ_app;
GRANT USAGE ON SCHEMA public TO individ_app;

-- After init-db has created the tables (run as individ_owner), apply grants:
--   sudo -u postgres psql -d individ < grants.sql
