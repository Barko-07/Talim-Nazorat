-- Emailed login codes, remembered devices, recovery codes and sign-up approval.
-- Run as the schema owner BEFORE starting the new app version:
--   psql "<owner DSN>" -v ON_ERROR_STOP=1 < 001_login_factors.sql
-- then `python -m app.cli init-db` (creates the new tables: recovery_codes,
-- trusted_devices, pending_registrations) and grants.sql again for the app role.
BEGIN;
ALTER TABLE users ADD COLUMN IF NOT EXISTS pending_approval boolean NOT NULL DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile text;
ALTER TABLE auth_sessions ADD COLUMN IF NOT EXISTS factor varchar(16) NOT NULL DEFAULT '';
COMMIT;
