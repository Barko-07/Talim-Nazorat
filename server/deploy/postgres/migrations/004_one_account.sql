-- One person, one account (app/identity.py). Adds the normalized email and
-- phone keys with unique indexes, filled in for existing accounts.
--   sudo individ-deploy migrate ~/004_one_account.sql
-- If two existing accounts already share a mailbox (e.g. a Gmail address with
-- and without dots) the unique index fails and NOTHING is changed: merge or
-- delete one of them first. A phone number shared by existing accounts is kept
-- on the oldest account only (the others keep the number but not the key).
BEGIN;
SET ROLE individ_owner;

ALTER TABLE users ADD COLUMN email_key VARCHAR(254);
ALTER TABLE users ADD COLUMN phone_key VARCHAR(16);

UPDATE users SET email_key = CASE
    WHEN split_part(lower(email), '@', 2) IN ('gmail.com', 'googlemail.com')
        THEN replace(split_part(split_part(lower(email), '@', 1), '+', 1), '.', '') || '@gmail.com'
    ELSE lower(trim(email))
END;

UPDATE users SET phone_key = right(regexp_replace(phone, '\D', '', 'g'), 9)
WHERE length(regexp_replace(coalesce(phone, ''), '\D', '', 'g')) >= 9;

UPDATE users SET phone_key = NULL WHERE id IN (
    SELECT id FROM (
        SELECT id, row_number() OVER (PARTITION BY phone_key ORDER BY created_at) AS n
        FROM users WHERE phone_key IS NOT NULL
    ) dup WHERE n > 1
);

ALTER TABLE users ALTER COLUMN email_key SET NOT NULL;
CREATE UNIQUE INDEX ix_users_email_key ON users (email_key);
CREATE UNIQUE INDEX ix_users_phone_key ON users (phone_key);

COMMIT;
