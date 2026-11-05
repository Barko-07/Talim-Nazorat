-- All work data moves to the server: one encrypted `records` table, who-works-
-- with-which-child in `student_access`, and an append-only change history.
-- The first-draft student tables (never used by the app, empty) are dropped.
-- Run as the postgres superuser (it switches to the schema owner itself):
--   sudo -u postgres psql -d individ -v ON_ERROR_STOP=1 < 003_records.sql
BEGIN;
SET ROLE individ_owner;

DROP TABLE IF EXISTS student_specialists;
DROP TABLE IF EXISTS observations;
DROP TABLE IF EXISTS assessments;
DROP TABLE IF EXISTS students;

CREATE TABLE records (
	kind VARCHAR(32) NOT NULL,
	rid VARCHAR(64) NOT NULL,
	institution_id VARCHAR(32),
	student_id VARCHAR(64),
	owner_id VARCHAR(32) NOT NULL,
	recipient_id VARCHAR(32),
	confidential BOOLEAN NOT NULL,
	data TEXT NOT NULL,
	deleted BOOLEAN NOT NULL,
	version INTEGER NOT NULL,
	created_at TIMESTAMP WITH TIME ZONE NOT NULL,
	updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
	updated_by VARCHAR(32),
	PRIMARY KEY (kind, rid),
	FOREIGN KEY(institution_id) REFERENCES institutions (id),
	FOREIGN KEY(owner_id) REFERENCES users (id)
);
CREATE INDEX ix_records_recipient_id ON records (recipient_id);
CREATE INDEX ix_records_owner_id ON records (owner_id);
CREATE INDEX ix_records_institution_id ON records (institution_id);
CREATE INDEX ix_records_student_id ON records (student_id);

CREATE TABLE student_access (
	student_id VARCHAR(64) NOT NULL,
	user_id VARCHAR(32) NOT NULL,
	via VARCHAR(16) NOT NULL,
	PRIMARY KEY (student_id, user_id),
	FOREIGN KEY(user_id) REFERENCES users (id) ON DELETE CASCADE
);
CREATE INDEX ix_student_access_user_id ON student_access (user_id);

CREATE TABLE record_changes (
	id SERIAL NOT NULL,
	at TIMESTAMP WITH TIME ZONE NOT NULL,
	user_id VARCHAR(32) NOT NULL,
	kind VARCHAR(32) NOT NULL,
	rid VARCHAR(64) NOT NULL,
	student_id VARCHAR(64),
	institution_id VARCHAR(32),
	action VARCHAR(16) NOT NULL,
	fields VARCHAR(1000) NOT NULL,
	before TEXT,
	after TEXT,
	PRIMARY KEY (id)
);
CREATE INDEX ix_record_changes_institution_id ON record_changes (institution_id);
CREATE INDEX ix_record_changes_at ON record_changes (at);
CREATE INDEX ix_record_changes_user_id ON record_changes (user_id);
CREATE INDEX ix_record_changes_student_id ON record_changes (student_id);

-- The application: read/write work data; the change history, like the audit
-- log, can only be added to - never edited or deleted.
GRANT SELECT, INSERT, UPDATE, DELETE ON records, student_access TO individ_app;
GRANT SELECT, INSERT ON record_changes TO individ_app;
GRANT USAGE, SELECT ON SEQUENCE record_changes_id_seq TO individ_app;

-- Tables added by later migrations get the ordinary data rights automatically
-- (append-only tables still need their REVOKE in that migration).
ALTER DEFAULT PRIVILEGES FOR ROLE individ_owner IN SCHEMA public
	GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO individ_app;
ALTER DEFAULT PRIVILEGES FOR ROLE individ_owner IN SCHEMA public
	GRANT USAGE, SELECT ON SEQUENCES TO individ_app;

RESET ROLE;
COMMIT;
