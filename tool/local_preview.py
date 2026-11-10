"""Local preview of individ.uz: the real API (development mode, its own SQLite
file) plus the built web app on one origin, with the production CSP.
Nothing here touches the live server.

    server/.venv/Scripts/python tool/local_preview.py [web-build-dir] [port] [--lan]

--lan: also reachable from a phone on the same Wi-Fi / hotspot
(http://<this PC's address>:port). Test data only; stop it when done.

Build the web app first:
    flutter build web --release --no-web-resources-cdn --dart-define=SERVER_MODE=true --output build/web_local

Seeds a school, a system administrator, staff, a few children and one pending
sign-up (so the bell has something). Emailed codes go to build/local_preview/dev-mail.txt and the newest one
alone to Desktop/KOD.txt.
"""
import os
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
LAN = "--lan" in sys.argv
ARGS = [a for a in sys.argv[1:] if a != "--lan"]
WEB = Path(ARGS[0]).resolve() if len(ARGS) > 0 else REPO / "build" / "web_local"
PORT = int(ARGS[1]) if len(ARGS) > 1 else 8780
HERE = REPO / "build" / "local_preview"
HERE.mkdir(parents=True, exist_ok=True)
DB = HERE / "local-preview.db"
MAIL = HERE / "dev-mail.txt"
PASSWORD = "Individ-Lokal-Sinov-2026"

os.environ["INDIVID_ENV"] = "development"
os.environ["DATABASE_URL"] = f"sqlite:///{DB.as_posix()}"
os.environ["CODE_RESEND_SECONDS"] = "5"
sys.path.insert(0, str(REPO / "server"))

if DB.exists():
    DB.unlink()
MAIL.write_text("", encoding="utf-8")

from fastapi.staticfiles import StaticFiles  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

from app import mailer as mailer_mod  # noqa: E402
from app.main import create_app  # noqa: E402
from app.models import Institution, Role, User  # noqa: E402
from app.security import passwords  # noqa: E402

_orig_send = mailer_mod.Mailer.send


def _send(self, to, subject, body):
    _orig_send(self, to, subject, body)
    code = re.search(r"\b(\d{6})\b", subject + " " + body)
    with MAIL.open("a", encoding="utf-8") as f:
        f.write(f"{to}\t{code.group(1) if code else '-'}\t{subject}\n")
    if code:
        # The newest code alone: the file holds just the 6 digits.
        (Path.home() / "Desktop" / "KOD.txt").write_text(code.group(1), encoding="utf-8")


mailer_mod.Mailer.send = _send

app = create_app()
ctx = app.state.ctx

# ---- seed
db = ctx.db.sessionmaker()
school = Institution(name="14-sonli maktab", region="Namangan viloyati")
db.add(school)
db.flush()


def user(email, name, role, inst=None):
    u = User(email=email, full_name=name, role=role.value, institution_id=inst,
             password_hash=passwords.hash_password(PASSWORD), must_change_password=False)
    db.add(u)
    return u


user("admin@maktab.uz", "Barkamol Olimov", Role.SUPER_ADMIN)
user("direktor@maktab.uz", "Karimov Anvar", Role.INSTITUTION_ADMIN, school.id)
t1 = user("oqituvchi@maktab.uz", "Yusupova Malika", Role.TEACHER, school.id)
user("psixolog@maktab.uz", "Rahimova Dilnoza", Role.PSYCHOLOGIST, school.id)
user("logoped@maktab.uz", "Toshmatov Bekzod", Role.SPEECH_THERAPIST, school.id)
db.commit()
db.close()

c = TestClient(app)
H = {"X-Requested-With": "XMLHttpRequest"}


def last_code(email):
    for m in reversed(ctx.mailer.outbox):
        if m.to == email:
            found = re.search(r"\b(\d{6})\b", m.subject + " " + m.body)
            if found:
                return found.group(1)
    raise SystemExit(f"no code for {email}")


r = c.post("/api/auth/login", json={"email": "oqituvchi@maktab.uz", "password": PASSWORD}, headers=H)
assert r.status_code == 200, (r.status_code, r.text)
csrf = r.json()["csrf_token"]
r = c.post("/api/auth/email-code/verify", json={"code": last_code("oqituvchi@maktab.uz")},
           headers={**H, "X-CSRF-Token": csrf})
assert r.status_code == 200, (r.status_code, r.text)
csrf = r.json()["csrf_token"]
kids = [("Ali", "Valiyev", "3-A"), ("Madina", "Qodirova", "2-B"), ("Sardor", "Aliyev", "4-A"),
        ("Zarina", "Nazarova", "1-A")]
ops = []
for i, (first, last, grade) in enumerate(kids):
    ops.append({"op": "put", "kind": "student", "id": f"s{i + 1}", "data": {
        "firstName": first, "lastName": last, "dateOfBirth": "2016-05-0%d" % (i + 1), "gender": "Erkak",
        "grade": grade, "status": "Faol", "primaryNeed": "Nutq rivojlanishi", "supportLevel": "1-daraja",
        "createdAt": "2026-10-0%dT09:00:00" % (i + 1), "institutionName": "14-sonli maktab",
    }})
r = c.post("/api/records/batch", json={"ops": ops}, headers={**H, "X-CSRF-Token": csrf})
assert r.status_code == 200, r.text

# A sign-up waiting for approval -> notifications in the administrators' bell.
r = c.post("/api/auth/register", json={
    "first_name": "Laylo", "last_name": "Ergasheva", "email": "laylo@maktab.uz",
    "phone": "+998 90 555 44 33", "role": "SPECIAL_EDUCATION", "institution_name": "14-sonli maktab",
    "password": PASSWORD,
}, headers=H)
reg = r.json()["registration_id"]
r = c.post("/api/auth/register/verify", json={"registration_id": reg, "code": last_code("laylo@maktab.uz")},
           headers=H)
assert r.status_code == 200, r.text

MAIL.write_text("", encoding="utf-8")  # only codes from the preview from here on


class CSPStatic(StaticFiles):
    CSP = ("default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; "
           "font-src 'self' https://fonts.gstatic.com; connect-src 'self' https://fonts.gstatic.com "
           "https://fonts.googleapis.com; img-src 'self' data: blob:; worker-src 'self' blob:; "
           "manifest-src 'self'; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'")

    async def get_response(self, path, scope):
        resp = await super().get_response(path, scope)
        resp.headers["Content-Security-Policy"] = self.CSP
        resp.headers["Cache-Control"] = "no-cache"
        return resp


app.mount("/", CSPStatic(directory=str(WEB), html=True), name="web")

if __name__ == "__main__":
    import uvicorn

    print(f"READY http://localhost:{PORT}  password={PASSWORD}  codes -> {MAIL}", flush=True)
    if LAN:
        import socket
        addrs = sorted({i[4][0] for i in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET)})
        for a in addrs:
            print(f"PHONE http://{a}:{PORT}", flush=True)
    uvicorn.run(app, host="0.0.0.0" if LAN else "127.0.0.1", port=PORT, log_level="warning")
