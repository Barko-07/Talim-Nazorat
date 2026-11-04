from app import mailer as mailer_mod
from app.config import Settings
from app.mailer import Mailer


class FakeSMTP:
    instances: list["FakeSMTP"] = []

    def __init__(self, host, port, timeout):
        self.host, self.calls = host, []
        FakeSMTP.instances.append(self)

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False

    def starttls(self, context):
        self.calls.append("starttls")

    def login(self, user, password):
        self.calls.append("login")

    def send_message(self, msg):
        self.calls.append(("send", msg["To"], msg["From"]))


def _send(monkeypatch, host, user=""):
    FakeSMTP.instances.clear()
    monkeypatch.setattr(mailer_mod.smtplib, "SMTP", FakeSMTP)
    s = Settings(environment="production", database_url="", secret_key="", data_encryption_key=b"",
                 allowed_origins=[], public_base_url="", smtp_host=host, smtp_user=user,
                 smtp_password="x", smtp_from="noreply@individ.uz")
    Mailer(s).send("a@b.uz", "Kod", "123456")
    return FakeSMTP.instances[-1].calls


def test_local_relay_needs_no_tls(monkeypatch):
    assert _send(monkeypatch, "127.0.0.1") == [("send", "a@b.uz", "noreply@individ.uz")]


def test_remote_smtp_always_uses_starttls(monkeypatch):
    calls = _send(monkeypatch, "smtp.example.uz", user="u")
    assert calls[:2] == ["starttls", "login"]
