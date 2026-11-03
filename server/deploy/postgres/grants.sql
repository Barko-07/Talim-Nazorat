-- Run after `python -m app.cli init-db` (as individ_owner) created the tables.
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO individ_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO individ_app;

-- Audit log is append-only for the application.
REVOKE UPDATE, DELETE, TRUNCATE ON audit_events FROM individ_app;

-- postgresql.conf:   listen_addresses = 'localhost'     password_encryption = scram-sha-256
-- pg_hba.conf (only local connections, strong auth):
--   local   all   postgres                      peer
--   host    individ  individ_app    127.0.0.1/32  scram-sha-256
--   host    individ  individ_owner  127.0.0.1/32  scram-sha-256
--   (no other host lines)
