"""Security audit log + suspicious activity detection and alerting."""
from __future__ import annotations

import json
import logging
import threading
import urllib.request
from datetime import timedelta
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..models import AuditEvent, utcnow

log = logging.getLogger("individ.security")

# Detection thresholds: this many warning events from one IP within the window
# raises a SUSPICIOUS_ACTIVITY alert (at most one alert per IP per window).
SUSPICIOUS_THRESHOLD = 10
SUSPICIOUS_WINDOW = timedelta(minutes=10)


def mask_login(value: str) -> str:
    value = (value or "").strip()
    if "@" in value:
        local, _, domain = value.partition("@")
        return (local[:2] + "***@" + domain[:40]) if local else "***@" + domain[:40]
    digits = "".join(c for c in value if c.isdigit())
    if len(digits) >= 4:
        return "***" + digits[-4:]
    return "***"


def _clean(text: str, limit: int) -> str:
    # Strip control characters so log lines cannot be forged (log injection).
    return "".join(c if c.isprintable() else " " for c in (text or ""))[:limit]


def record(
    db: Session,
    action: str,
    *,
    severity: str = "info",
    user_id: str | None = None,
    subject: str = "",
    ip: str = "",
    detail: str = "",
    webhook_url: str = "",
) -> None:
    event = AuditEvent(
        action=action,
        severity=severity,
        user_id=user_id,
        subject=_clean(subject, 120),
        ip=_clean(ip, 64),
        detail=_clean(detail, 500),
    )
    db.add(event)
    db.commit()
    line = json.dumps(
        {"action": action, "severity": severity, "user": user_id, "subject": event.subject,
         "ip": event.ip, "detail": event.detail},
        ensure_ascii=False,
    )
    (log.warning if severity != "info" else log.info)(line)
    if severity == "warning" and ip:
        _detect_burst(db, ip, webhook_url)
    if severity == "alert":
        _send_alert(webhook_url, line)


def _detect_burst(db: Session, ip: str, webhook_url: str) -> None:
    since = utcnow() - SUSPICIOUS_WINDOW
    warnings = db.scalar(
        select(func.count()).select_from(AuditEvent).where(
            AuditEvent.ip == ip, AuditEvent.severity == "warning", AuditEvent.at >= since
        )
    )
    if warnings < SUSPICIOUS_THRESHOLD:
        return
    already = db.scalar(
        select(func.count()).select_from(AuditEvent).where(
            AuditEvent.ip == ip, AuditEvent.action == "SUSPICIOUS_ACTIVITY", AuditEvent.at >= since
        )
    )
    if already:
        return
    record(
        db,
        "SUSPICIOUS_ACTIVITY",
        severity="alert",
        ip=ip,
        detail=f"{warnings} security warnings from this IP in {SUSPICIOUS_WINDOW.seconds // 60} min",
        webhook_url=webhook_url,
    )


def alert_request(webhook_url: str, line: str) -> tuple[str, dict]:
    """Where and what to post. A Telegram bot URL carries the chat in the query
    (https://api.telegram.org/bot<token>/sendMessage?chat_id=<id>); Telegram
    wants it in the body, so it is moved there. Other webhooks get {"text"}."""
    body: dict = {"text": "Individ security alert: " + line}
    parts = urlsplit(webhook_url)
    if parts.hostname == "api.telegram.org":
        query = dict(parse_qsl(parts.query))
        if "chat_id" in query:
            body["chat_id"] = query.pop("chat_id")
        webhook_url = urlunsplit(parts._replace(query=urlencode(query)))
    return webhook_url, body


def _send_alert(webhook_url: str, line: str) -> None:
    if not webhook_url.startswith("https://"):
        return
    url, body = alert_request(webhook_url, line)

    def post() -> None:
        try:
            req = urllib.request.Request(
                url,
                data=json.dumps(body).encode(),
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            urllib.request.urlopen(req, timeout=5).close()  # noqa: S310 (https enforced above)
        except Exception:  # noqa: BLE001 - alerting must never break requests
            # The URL may hold a bot token: never log it.
            log.error("alert webhook failed")

    threading.Thread(target=post, daemon=True).start()
