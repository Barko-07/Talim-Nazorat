#!/usr/bin/env bash
# Daily encrypted database backup. Install as root:
#   cp backup.sh /usr/local/bin/individ-backup && chmod 700 /usr/local/bin/individ-backup
#   echo '30 2 * * * root /usr/local/bin/individ-backup' > /etc/cron.d/individ-backup
# The backup is encrypted with the PUBLIC key in /etc/individ/backup.pub (age).
# Keep the matching private key OFF the server - then a stolen server cannot read backups.
set -euo pipefail
umask 077

OUT=/var/backups/individ
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
FILE="$OUT/individ-$STAMP.sql.gz.age"

sudo -u postgres pg_dump --no-owner --format=plain individ \
  | gzip -9 \
  | age -R /etc/individ/backup.pub > "$FILE"

# Sanity check: a backup that cannot be read back is worse than none.
[ -s "$FILE" ] && head -c 40 "$FILE" | grep -q "age-encryption.org" || { echo "backup is empty or not encrypted" >&2; exit 1; }

# Offsite copy: the owner's computer pulls this folder every day over SSH
# (deploy/scripts/pull-backups.ps1). It holds only encrypted files.
OFFSITE=/home/mistaker0908/offsite
install -d -o mistaker0908 -g mistaker0908 -m 700 "$OFFSITE"
install -o mistaker0908 -g mistaker0908 -m 600 "$FILE" "$OFFSITE/"
find "$OFFSITE" -name 'individ-*.sql.gz.age' -mtime +14 -delete

# Keep 30 days on the server.
find "$OUT" -name 'individ-*.sql.gz.age' -mtime +30 -delete
echo "backup written: $FILE"
