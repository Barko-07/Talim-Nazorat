-- Only admin roles confirm logins with an emailed code now; "Eslab qolish"
-- keeps other sessions for REMEMBER_ME_DAYS, so remembered devices are gone.
-- Run as the schema owner before starting the new app version:
--   psql "<owner DSN>" -v ON_ERROR_STOP=1 < 002_remember_me.sql
BEGIN;
ALTER TABLE auth_sessions ADD COLUMN IF NOT EXISTS remember boolean NOT NULL DEFAULT false;
DROP TABLE IF EXISTS trusted_devices;
COMMIT;
