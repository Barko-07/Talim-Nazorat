#!/usr/bin/env bash
# One-time hardening of a fresh Ubuntu 24.04 server. Run as root after you can
# log in with your SSH key:   sudo bash provision.sh
set -euo pipefail

apt-get update
apt-get -y upgrade
apt-get -y install nginx postgresql python3-venv python3-pip ufw fail2ban \
    unattended-upgrades certbot python3-certbot-nginx age

# Automatic security updates
dpkg-reconfigure -f noninteractive unattended-upgrades

# Firewall: only SSH and HTTPS/HTTP are reachable. PostgreSQL stays private.
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

# SSH: keys only, no root login, no passwords.
install -d /etc/ssh/sshd_config.d
cat > /etc/ssh/sshd_config.d/10-individ.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
LoginGraceTime 30
X11Forwarding no
AllowAgentForwarding no
EOF
systemctl reload ssh

# Ban IPs that hammer SSH or hit nginx rate limits.
cat > /etc/fail2ban/jail.d/individ.conf <<'EOF'
[sshd]
enabled = true
maxretry = 4
bantime = 1h

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10
bantime = 1h
EOF
systemctl restart fail2ban

# PostgreSQL listens on localhost only.
PGCONF=$(ls /etc/postgresql/*/main/postgresql.conf | head -1)
sed -i "s/^#\?listen_addresses.*/listen_addresses = 'localhost'/" "$PGCONF"
sed -i "s/^#\?password_encryption.*/password_encryption = scram-sha-256/" "$PGCONF"
systemctl restart postgresql

# App user and folders (no login shell).
id individ &>/dev/null || useradd --system --home /srv/individ --shell /usr/sbin/nologin individ
install -d -o individ -g individ -m 750 /srv/individ /srv/individ/web /srv/individ/server
install -d -o root -g individ -m 750 /etc/individ
install -d -o root -g root -m 700 /var/backups/individ

echo "Base hardening done. Next: deploy/README steps (database, env file, app, nginx, certbot)."
