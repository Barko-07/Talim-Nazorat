# Individ: security report before server launch

**Date:** 3 November 2026 · **Branch:** `security-hardening`
**Scope:** the Flutter app, the new server backend (`server/`), the deployment configuration, dependencies, and the full git history.

## Summary

- The app had **no server backend**: login and data lived on each device. Most of the requested protections (server-side validation, parameterized queries, rate limiting, CORS, cookies, CSRF, HTTPS) need a server, so a **secure backend was built** in `server/` (Python FastAPI, PostgreSQL in production).
- **66 automated security tests** cover the backend, and all pass. The Flutter app's 244 tests also pass.
- **No real secrets were found** in the code or anywhere in the git history (all branches, every commit).
- **No known vulnerabilities** in dependencies (`pip-audit`; `flutter pub` shows no security advisories).
- **4 issues were fixed**, 2 of them found while reviewing the new code itself (listed below).
- **Still open before real children's data goes in:** connect the app to the server, configure an email provider, and confirm Uzbekistan's data-location rules.

## What was asked, and what was done

| # | Request | Status | How | Proven by |
|---|---|---|---|---|
| 1 | Government-grade authentication | ✅ | Password plus **two-factor authentication (TOTP)**. 2FA is mandatory for system and school administrators and optional for other staff. New accounts get a temporary password and must change it at first login. Codes can't be reused. | `test_auth.py` |
| 2 | Hide API keys | ✅ | The project uses no third-party API keys. All server secrets come only from environment variables (`/etc/individ/individ.env`, `chmod 640`), never from code or git. | history scan, `.gitignore` |
| 3 | Secure the database | ✅ | PostgreSQL listens on localhost only and uses SCRAM passwords. Two database roles: the app's role can't change tables, and **the audit log can't be edited or deleted by the app**. Diagnoses, guardian phones, notes, observations and 2FA secrets are **encrypted with AES-256-GCM** before they reach the database. Backups are encrypted with a key kept off the server. | `test_sensitive_columns_encrypted_at_rest`, `deploy/postgres/*.sql` |
| 4 | Enforce HTTPS | ✅ | nginx redirects all HTTP to HTTPS (TLS 1.2/1.3 only) and sends HSTS (2 years, preload). The app itself refuses non-HTTPS requests in production. | `test_production_enforces_https_and_sends_hsts` |
| 5 | Hash passwords | ✅ | **Argon2id** (64 MB, 3 passes; OWASP recommendation). Old app hashes (PBKDF2) are upgraded at next login. Strong-password rules: 12+ characters, 3 character types, no common or demo passwords, not containing the name or email. | `test_passwords_stored_as_argon2id`, `test_weak_passwords_rejected` |
| 6 | Server-side form validation | ✅ | Every request body is checked on the server: unknown fields refused, lengths and formats limited, dates and scores sanity-checked. Errors never echo back what was sent, so passwords never leak into error messages. | `test_validation_rejects_unknown_fields_and_never_echoes_input` |
| 7 | XSS protection | ✅ | HTML/script markup is refused in names. The API returns only JSON with `Content-Security-Policy: default-src 'none'`. The web app gets an enforced CSP, and Flutter never renders text as HTML. | `test_xss_*` |
| 8 | Log and monitor suspicious activity | ✅ | Every login, failure, lockout, refused action, admin action and record view goes to an append-only audit log. **10+ warnings from one IP within 10 minutes triggers a `SUSPICIOUS_ACTIVITY` alert**, optionally sent to a webhook (e.g. Telegram). Emails are masked in logs, passwords are never logged, and log-forging characters are stripped. | `test_monitoring_and_config.py` |
| 9 | Lock down admin routes, but keep your access | ✅ | `/api/admin/*` works only for a **system administrator who completed 2FA in this session**, optionally only from your IP (`ADMIN_IP_ALLOWLIST`). Everyone else gets "404 Not Found", so the routes aren't even revealed. **Your own admin account is created on the server** with `python -m app.cli create-admin`; lost phone: `reset-mfa`. The last admin can't be removed or demoted. | `test_admin_and_access.py`, `test_cli.py` |
| 10 | Parameterized queries | ✅ | All database access goes through the SQLAlchemy ORM, which sends values separately from SQL. Search wildcards are escaped. | `test_sql_injection_payloads_are_treated_as_data` |
| 11 | Check environment variables | ✅ | In production the server **refuses to start** with a weak or missing `SECRET_KEY` or encryption key, a non-PostgreSQL database, an `http://` address, a `*` CORS origin, insecure cookies, admin 2FA turned off, or no mail server. `python -m app.cli check-config` checks before launch. | `test_unsafe_production_config_refuses_to_start` (8 cases) |
| 12 | Rate limiting | ✅ | Three layers: (1) nginx: 10 req/s per IP for the API, 10/min for login and password routes; (2) the app: 120 API requests per minute per IP; (3) database-backed limits shared by all server processes: 10 logins/min per IP, 5 2FA attempts per 5 min, 3 codes per 15 min, 5 reset requests per 15 min per IP. Accounts lock after 5 wrong passwords, for 15 min, doubling each time, up to 24 h. | `test_login_rate_limited_per_ip`, `test_lockout_*`, `test_general_api_rate_limit` |
| 13 | Restrict CORS | ✅ | Closed by default: the web app and API share one domain, so no cross-origin access is needed. If ever needed, only listed `https://` origins are allowed, never `*`. | `test_cors_closed_by_default_and_allowlist_only` |
| 14 | Security headers | ✅ | HSTS, CSP, `X-Frame-Options: DENY`, `nosniff`, `Referrer-Policy: no-referrer`, `Permissions-Policy`, `Cross-Origin-Opener-Policy`, `Cache-Control: no-store` on API responses; server version hidden. | `test_security_headers_on_every_response` |
| 15 | Secure session cookies | ✅ | `__Host-` prefix, `Secure`, `HttpOnly` (JavaScript can't read it), `SameSite=Strict`. Sessions are stored on the server, and the database holds only a hash of each session token. The token is replaced on login, 2FA and password change (prevents session fixation). Sessions expire after **30 min idle / 8 h maximum**. Logout and blocking take effect immediately. | `test_login_sets_httponly_strict_cookie…`, `test_secure_cookie_uses_host_prefix…`, `test_idle_and_absolute_timeouts`, `test_session_rotates…` |
| 16 | CSRF protection | ✅ | Three checks on every request that changes data: a per-session CSRF token, a required custom header (foreign sites can't send it without our CORS approval), and an allowed-Origin check. `SameSite=Strict` cookies on top. | `test_csrf_custom_header_and_origin_and_token` |
| 17 | Expiring reset links + emailed code to change password | ✅ | **Forgot password:** a 6-digit code by email that is valid **10 minutes**, single use, burned after 5 wrong tries; a new code cancels the old one; codes are stored only as hashes. The answer is identical whether or not the account exists. **Change password (logged in):** requires the current password **and** an emailed code. After a reset or change, all other sessions are signed out and a notice email is sent. | `test_password.py` (8 tests) |
| 18 | Production debug mode | ✅ | Server: API docs off in production, generic error messages (no stack traces), no auto-reload, sandboxed systemd service on localhost only. Flutter: release builds have debug mode off; the debug banner is hidden; demo logins work only with `DEMO_MODE` (public demo only). | `test_production_hides_api_docs…`, `test_unknown_routes_and_errors_leak_nothing` |
| 19 | Update vulnerable dependencies | ✅ | 16 Flutter packages updated to their latest compatible versions. Server packages pinned to exact versions (`requirements.txt`). `pip-audit`: **no known vulnerabilities**. | `pip-audit`, `flutter pub upgrade` |
| 20 | Remove unused packages | ✅ | `cupertino_icons` removed (never used). | `flutter test`: 244 pass |
| 21 | Check for exposed files | ✅ | Deleted `scripts/server.py` (an old dev server with CORS `*` that listened on all networks). `backups/` is no longer tracked in git (your local file is kept). The web build holds only app files (no source maps or data). nginx refuses hidden files, `.env`, backups, databases, logs, source maps and scripts. | file review, `deploy/nginx/individ.conf` |
| 22 | Scan git history for leaked secrets | ✅ | All 47 commits on every branch searched for private keys, AWS/Google/GitHub/Slack/Stripe/OpenAI/Telegram tokens, JWTs, database URLs with passwords, `.env`/keystore files, and password assignments. **No real secrets found.** Only test passwords and the public demo passwords (see next row). | scan output |
| 23 | Revoke and replace compromised keys | ✅ | There are no real keys to revoke. The demo passwords `Parol2026!` and `AdminPass123!` are public in git history, so they are **treated as compromised**: the server has no demo accounts and **rejects these passwords** for any account, and the Flutter app accepts them only in the public demo build. The old committed backup holds only synthetic demo data, no passwords. | `password_problems` list, `test_create_admin_rejects_weak_password` |
| 24 | Thorough security review | ✅ | Code review of every new file. Findings are below. | — |
| 25 | Test the protections | ✅ | 66 automated tests plus a live check of the running server with real HTTP requests. | `cd server && pytest` |

## Findings and fixes

| Severity | Finding | Fix |
|---|---|---|
| High | No server-side security at all: anyone with the app has their data only on their own device, and the planned server would have had no protections. | Built `server/` with the protections above. |
| Medium | `scripts/server.py`: a dev web server sending `Access-Control-Allow-Origin: *` and listening on all network interfaces. | Deleted. `serve_web.py` (localhost only, strict headers) remains for local testing. |
| Medium | `backups/database_backup.json` was tracked in git. Today it holds demo data, but a real backup committed there would publish children's data. | Removed from git tracking; `backups/`, `*.db`, `*.sqlite` and dump files are now in `.gitignore`. |
| Medium | **Found in review of the new code:** rate-limit clean-up compared time windows of different sizes, which could reset hourly limits (e.g. password reset codes) early. | Windows now stored as timestamps; regression test `test_cleanup_never_resets_longer_windows`. |
| Low | **Found in review of the new code:** a flood of rejected requests created one audit row each, which an attacker could use to fill the database. | Audit writes for rejected requests throttled to 5 per minute per IP and action; test `test_flood_of_rejected_requests…`. |
| Low | `cupertino_icons` package unused. | Removed. |
| Info | Public demo passwords exist in git history. | Treated as compromised (row 23). |

## Known limits, and what is still needed (honest list)

1. **The Flutter app is not yet connected to the new server.** Today it still saves data on the device, and the Vercel site is a demo. Connecting the app is the next step ("fix the databases and backends").
2. **The server covers users, schools, students, assessments and observations so far.** IEP plans, sessions, referrals, measurements and the other data types still need server endpoints, with the same permission rules.
3. **An email (SMTP) provider is required** to send one-time codes. The server won't start in production without one. Options: your hosting provider's mail, or a transactional email service.
4. **Tested on SQLite locally.** PostgreSQL will be checked on the real server during deployment.
5. **The enforced web CSP** in `deploy/nginx/individ.conf` must be checked in a browser after deployment (Flutter needs `wasm-unsafe-eval` and Google Fonts).
6. **Account lockout can be abused** to lock someone out on purpose. This is the usual trade-off: it's limited by per-IP limits, and an admin can unlock (`/api/admin/users/{id}/unlock`).
7. **2FA recovery codes are not implemented.** A lost phone is handled by an admin, or by the server command `reset-mfa`.
8. **Legal:** children's personal data must be stored on servers **in Uzbekistan** (personal data law). Confirm with the provider and a lawyer before entering real data.

## Recommended server and domain (Uzbekistan)

Choose a provider whose **VPS is physically in Tashkent**, and ask them to confirm it in writing.

| Provider | What to buy | Link |
|---|---|---|
| **aHOST** (recommended): VPS and `.uz` domain in one place; data center on TAS-IX | **VDS/VPS** plan (not "shared hosting"; some shared plans are in Germany), plus a `.uz` domain | https://ahost.uz |
| **Hostmaster**: VPS and `.uz` domains | "VDS" plan, plus a `.uz` domain | https://hostmaster.uz |
| **UZCLOUD (Uzbektelekom)**: Tier III data center in Tashkent | cloud server; ask Uzbektelekom for UZCLOUD (no official page confirmed) | https://uztelecom.uz |
| `.uz` registry (Uzinfocom): list of accredited registrars, and a free/taken domain check | domain only | https://cctld.uz |

**Server size for the pilot:** 2 vCPU, 4 GB RAM, 60 GB SSD, **Ubuntu 24.04 LTS**, a public IP, root access by SSH key, provider backups switched on.
**Domain:** e.g. `individ.uz`; check that it's free at cctld.uz.

Before paying, ask: (1) is the VPS physically in Tashkent? (2) do I get root access with an SSH key? (3) are backups included? (4) do you provide SMTP for sending email?
