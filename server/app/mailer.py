"""Delivery of one-time codes and security notices by email.

Production: SMTP over STARTTLS (required by config), or a local relay on
127.0.0.1 such as the send-only Postfix in deploy/. Development/test:
messages are kept in memory (and printed in development) - never in production.
"""
from __future__ import annotations

import logging
import smtplib
import ssl
from dataclasses import dataclass
from email.message import EmailMessage

from .config import Settings

log = logging.getLogger("individ.mail")

LOOPBACK_HOSTS = {"127.0.0.1", "::1", "localhost"}


class MailError(RuntimeError):
    """The message could not be handed to the mail server."""


@dataclass
class SentMail:
    to: str
    subject: str
    body: str


class Mailer:
    def __init__(self, settings: Settings):
        self.settings = settings
        self.outbox: list[SentMail] = []  # only filled outside production

    def send(self, to: str, subject: str, body: str) -> None:
        s = self.settings
        if not s.is_production and not s.smtp_host:
            self.outbox.append(SentMail(to, subject, body))
            if s.environment == "development":
                log.warning("DEV MAIL to %s: %s\n%s", to, subject, body)
            return
        msg = EmailMessage()
        msg["From"] = s.smtp_from
        msg["To"] = to
        msg["Subject"] = subject
        msg.set_content(body)
        try:
            with smtplib.SMTP(s.smtp_host, s.smtp_port, timeout=15) as smtp:
                # A relay on this machine (loopback-only Postfix) never leaves the
                # host, so TLS adds nothing; any other host must use STARTTLS.
                if s.smtp_host not in LOOPBACK_HOSTS:
                    smtp.starttls(context=ssl.create_default_context())
                    if s.smtp_user:
                        smtp.login(s.smtp_user, s.smtp_password)
                smtp.send_message(msg)
        except (smtplib.SMTPException, OSError) as exc:
            log.error("mail to %s failed: %s", to.split("@")[-1], type(exc).__name__)
            raise MailError(str(exc)) from exc
