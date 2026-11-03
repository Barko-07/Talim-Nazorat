# TA’LIM NAZORAT security

The app stores sensitive data about children with disabilities. This document lists what is **in place now**, and what **must be done when the server is set up**.

## ✅ In place now (in the app)

### Login and accounts
| Measure | Where |
|---|---|
| Passwords are stored only as PBKDF2-SHA256 hashes (20,000 iterations, random salt); plain-text passwords from older versions are converted on startup | `PasswordHasher`, `LocalDbService` |
| Demo password is accepted only in debug builds or when `DEMO_MODE=true`; public demo data is synthetic and local to each browser | `LocalDbService.verifyPassword`, `tool/vercel_build.sh` |
| **Login doesn't reveal whether an account exists**: one message for every failure ("Login yoki parol noto‘g‘ri"); unknown accounts also run a dummy password check, so the response time is the same | `AuthProvider.login` |
| **Brute-force protection:** 5 wrong attempts in 15 minutes locks that login for 15 minutes; restarting the app doesn't reset the counter | `LoginGuard` |
| The role is checked only after the password is confirmed (no role leak) | `AuthProvider.login` |
| **Session expiry:** after 2 hours of inactivity, and at most 12 hours | `AuthSession` |
| No demo-account buttons and no pre-filled credentials on the login page; no visible admin entrance | `login_screen.dart` |
| Blocked users are refused at login and lose access immediately, even mid-session (every action re-reads the account) | `AppProvider._requireUser` |
| Self-registration only for specialist roles; admin, director and coordinator accounts are created only by an admin | `LocalDbService.registerUser` |

### Access (who sees and changes what)
- Every write requires a user and a permission check. Specialists see only children assigned to them. Details: [ARCHITECTURE.md](ARCHITECTURE.md).
- **Admin accounts are locked down:**
  - an admin can't be blocked or deleted, and the last active admin can't lose the admin role
  - a director can't create or manage admins
  - a user can't change their own role
- **The first admin comes from build configuration** (no password in the code):
  ```bash
  dart run tool/hash_password.dart        # asks for the password, prints the PBKDF2 hash
  flutter build apk --release \
    --dart-define=ADMIN_EMAIL=admin@maktab.uz \
    --dart-define=ADMIN_PASSWORD_HASH='pbkdf2$20000$...'
  ```
  It's created only if no active admin exists. An existing account is never overwritten or promoted. `AppConfig.problems()` reports configuration mistakes (missing variables, a plain password instead of a hash, an `http://` API address).

### Logging and monitoring
All of these are recorded in the audit log (entity `Security`):

| Event | Action code |
|---|---|
| Wrong login | `SECURITY_LOGIN_FAILED` |
| Login locked after repeated failures | `SECURITY_LOCKOUT` |
| Attempt on a locked login | `SECURITY_LOCKED_ATTEMPT` |
| Blocked account tried to log in | `SECURITY_BLOCKED_LOGIN` |
| A refused action (who, what) | `SECURITY_ACCESS_DENIED` |
| First admin created from build configuration | `SECURITY_ADMIN_BOOTSTRAP` |

- Logins are masked (`so***@talim.uz`, `***4567`) and passwords are never logged.
- `getSecurityEvents()` returns the last 7 days of events, only to roles that can view the audit log.

### Data
- This build has no server: records live only in the current device/browser profile and do not synchronize between specialists. The public Vercel build is a demo; real children's data must not be entered.
- Local storage is not encrypted. Clearing browser/app data or losing the device can remove records; use the database export and keep backups outside the device.
- **Android cloud backup is disabled** (`allowBackup="false"`), so data isn't copied to Google Drive.
- **Unencrypted HTTP is blocked** on Android (`usesCleartextTraffic="false"`), so HTTPS is required.
- A damaged record is set aside in a backup, so data is never silently lost.

### XSS and injection
- Flutter draws text itself and **never interprets HTML**, so text a user types can't run as a script.
- **CSV formula injection:** values starting with `=`, `+`, `-` or `@` get a `'` in front.
- **No SQL**, so there are no SQL queries to inject into. Search runs in memory.
- No inline scripts in `web/index.html` (moved to `sw_cleanup.js`), so a strict CSP is possible.

### Web server (`serve_web.py`)
- Listens only on `127.0.0.1` by default.
- **CORS** allows only the origins listed in `ALLOWED_ORIGINS` (no `*`).
- **Security headers:** `X-Content-Type-Options`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`, `Permissions-Policy`, `Cross-Origin-Opener-Policy`, `Content-Security-Policy` (report mode by default; `ENFORCE_CSP=1` makes it binding), and `Strict-Transport-Security` behind HTTPS (`BEHIND_HTTPS=1`).
- **Rate limiting:** 300 requests per minute per IP (`RATE_LIMIT`).
- No folder listings, server version hidden, only GET/HEAD accepted.

### Secrets
- `.gitignore` excludes `.env*`, `*.jks`, `*.keystore`, `key.properties`, `*.pem`, `*.p12` and `secrets/`.
- The repository was scanned: no API keys, tokens or private keys.

## ⏳ Not done yet: local database encryption
Data is stored in the app's private storage, which other apps can't read. It is **not encrypted**, though, so it can be read on a rooted phone. Next step:
- AES-256-GCM encryption for each table
- the key kept in Android Keystore / iOS Keychain (`flutter_secure_storage`)
- data saved by older versions encrypted automatically

## 🖥 When the server is set up (required checklist)
The app currently has no server. Once data moves to a server (e.g. self-hosted PocketBase or Supabase in Tashkent), all of these are **required**:

1. **HTTPS only:** a Let's Encrypt certificate; HTTP redirects to HTTPS; HSTS (`max-age=31536000; includeSubDomains`).
2. **Authentication:** handled by the server (PocketBase/Supabase auth), with short-lived access tokens plus refresh tokens. On mobile, tokens go in `flutter_secure_storage`, not SharedPreferences.
3. **Session cookies (web version):** `HttpOnly; Secure; SameSite=Strict`, with a short lifetime.
4. **API keys:** only on the server or in environment variables (`.env`, not in GitHub). No secret key in the mobile app; a public key alone grants nothing, and access rules decide everything. Rotate keys regularly.
5. **Database:**
   - Access rules move to the server (PocketBase API rules or Supabase RLS), applying the same matrix as `AccessControlService`.
   - Only **parameterized queries** or the ORM; never concatenate user input into SQL.
   - Encrypted daily backups to a second server, with restores tested.
   - The database is not reachable from the internet, only from the app server.
6. **CORS:** only the app's own domain (e.g. `https://talimnazorat.uz`), never `*`.
7. **Security headers:** the same set as `serve_web.py`, sent from nginx/Caddy, with CSP enforced.
8. **Server-side rate limiting:** login 5 per minute per IP plus lockout; API 100 per minute per user.
9. **Logging and monitoring:** server logs plus alerts (e.g. many failed logins); the audit log is kept on the server and can't be edited.
10. **Environment variables:** all secrets (DB password, JWT secret, SMTP) in `.env` on the server, readable only by the app's user (`chmod 600`).
11. **Updates:** OS and server software security updates; `flutter pub outdated` checked monthly.
