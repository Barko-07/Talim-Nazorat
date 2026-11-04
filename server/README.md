# Individ API (server)

Secure backend for Individ: login with two-factor authentication, server-side
sessions, permission checks and encrypted storage of children's sensitive data.
Security design and test results: [../docs/security/SECURITY_REPORT.md](../docs/security/SECURITY_REPORT.md).

## Local development

```bash
cd server
python -m venv .venv
.venv/Scripts/pip install -r requirements-dev.txt     # Windows (Linux: .venv/bin/pip)
.venv/Scripts/python -m pytest                         # security test suite
INDIVID_ENV=development .venv/Scripts/uvicorn app.main:create_app --factory --reload
```

Development uses SQLite and prints one-time codes to the console instead of emailing them.
API docs (development only): http://127.0.0.1:8000/api/docs

## Deploying to the server (Ubuntu 24.04)

1. `sudo bash deploy/scripts/provision.sh`: firewall, SSH keys only, fail2ban, automatic updates, PostgreSQL on localhost only.
2. Database: `sudo -u postgres psql < deploy/postgres/setup.sql` (stdin, because the postgres user can't read your home folder), then set both role passwords with `\password`.
3. Environment: copy `.env.example` to `/etc/individ/individ.env`, fill in the secrets generated on the server, then `chown root:individ` and `chmod 640`. Check it with `python -m app.cli check-config`; the app refuses to start with unsafe values.
4. App: copy `server/` to `/srv/individ/server`, then create the venv and `pip install -r requirements.txt`.
5. Tables: `DATABASE_URL=<owner DSN> python -m app.cli init-db`, then `sudo -u postgres psql -d individ < deploy/postgres/grants.sql`.
6. Your admin account: `python -m app.cli create-admin --email you@domain --name "Ism Familiya"`. The password is typed, never stored in plain text. At first login, two-factor authentication must be set up.
7. Service: install `deploy/systemd/individ-api.service`, then `systemctl enable --now individ-api`.
8. Web: `flutter build web --release --pwa-strategy=none --no-web-resources-cdn`, then copy `build/web/*` to `/srv/individ/web` and precompress it for `gzip_static` (about 10 MB down to 3.5 MB): `find /srv/individ/web -type f \( -name '*.js' -o -name '*.wasm' -o -name '*.json' -o -name '*.otf' -o -name '*.ttf' \) -exec gzip -k -9 -f {} \;`
9. nginx: `individ.conf` needs the certificate to exist, so get it first through a temporary HTTP-only site that serves `/.well-known/acme-challenge/` from `/var/www/certbot`: `certbot certonly --webroot -w /var/www/certbot -d individ.uz -d www.individ.uz`. Then remove the temporary site and the `default` site, install `individ.conf` in `sites-enabled` and `individ_proxy.conf` plus `individ_headers.conf` in `/etc/nginx/`, then `nginx -t && systemctl reload nginx`. Renewals use the same webroot, which `individ.conf` keeps serving.
10. Backups: create an age key pair on your own computer, put only the public key on the server at `/etc/individ/backup.pub`, and install `deploy/scripts/backup.sh` as a daily cron job. Test a restore.

11. Mail: a send-only Postfix bound to 127.0.0.1 with OpenDKIM signing, so codes are sent from the server itself (`SMTP_HOST=127.0.0.1`, `SMTP_PORT=25`; the app skips TLS only for a loopback relay). Publish SPF (`v=spf1 ip4:<server IP> -all`), the DKIM key from `/etc/opendkim/keys/<domain>/mail.txt` and DMARC (`v=DMARC1; p=quarantine; adkim=s; aspf=s`), and ask the VDS provider to set the PTR of the server IP to the domain.

Lost your phone? On the server, run `python -m app.cli reset-mfa --email you@domain`.
