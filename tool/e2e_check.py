"""End-to-end check of every user journey against the local preview server
(tool/local_preview.py on http://127.0.0.1:8780: real API, fresh database,
dev mail written to build/local_preview/dev-mail.txt). Restart the preview
before each run: it expects the seeded accounts in their initial state.
Each step prints OK or FAIL with the reason. Run with the server's venv."""
import json
import re
import sys
import time
from pathlib import Path

import httpx

BASE = "http://127.0.0.1:8780"
MAIL = Path(__file__).resolve().parent.parent / "build" / "local_preview" / "dev-mail.txt"
PW = "Individ-Lokal-Sinov-2026"
NEW_PW = "Yangi-Mustahkam-Parol-2026"
RESULTS = []


def check(name, cond, detail=""):
    RESULTS.append((name, bool(cond), detail))
    print(("OK   " if cond else "FAIL ") + name + ("" if cond else f"  <- {detail}"))
    return cond


def mails_to(email):
    out = []
    for line in MAIL.read_text(encoding="utf-8").splitlines():
        to, code, subject = line.split("\t", 2)
        if to == email:
            out.append((code, subject))
    return out


def last_code(email):
    time.sleep(0.3)
    codes = [c for c, _ in mails_to(email) if c != "-"]
    return codes[-1] if codes else None


class Actor:
    def __init__(self, email, password=PW):
        self.email, self.password = email, password
        self.c = httpx.Client(base_url=BASE, timeout=20)
        self.csrf = ""

    def _h(self):
        h = {"X-Requested-With": "XMLHttpRequest", "Content-Type": "application/json"}
        if self.csrf:
            h["X-CSRF-Token"] = self.csrf
        return h

    def req(self, method, path, body=None):
        r = self.c.request(method, path, headers=self._h(), content=json.dumps(body) if body is not None else None)
        try:
            j = r.json()
            if isinstance(j, dict) and j.get("csrf_token"):
                self.csrf = j["csrf_token"]
        except ValueError:
            pass
        return r

    def login(self, password=None):
        r = self.req("POST", "/api/auth/login", {"email": self.email, "password": password or self.password})
        if r.status_code != 200:
            return r
        if r.json().get("state") == "email_code_required":
            r = self.req("POST", "/api/auth/email-code/verify", {"code": last_code(self.email)})
        return r

    def put(self, *ops):
        return self.req("POST", "/api/records/batch",
                        {"ops": [{"op": "put", "kind": k, "id": i, "data": d} for k, i, d in ops]})

    def items(self, kind):
        return self.req("GET", "/api/records").json()["items"][kind]


def main():
    admin = Actor("admin@maktab.uz")
    r = admin.login()
    check("Admin: parol + emaildagi kod bilan kirish", r.status_code == 200 and r.json()["state"] == "ok", r.text[:200])
    ids = {u["email"]: u["id"] for u in admin.req("GET", "/api/admin/users").json()}
    inst = admin.req("GET", "/api/admin/institutions").json()[0]["id"]

    # --- sign-up
    anon = Actor("yangi.xodim@maktab.uz")
    r = anon.req("POST", "/api/auth/register", {
        "first_name": "Nodira", "last_name": "Saidova", "email": "yangi.xodim@maktab.uz",
        "phone": "+998 91 222 33 44", "role": "PSYCHOLOGIST", "institution_name": "14-sonli maktab",
        "password": PW})
    check("Ro‘yxatdan o‘tish: so‘rov qabul qilindi", r.status_code == 202, r.text[:200])
    code = last_code("yangi.xodim@maktab.uz")
    check("Ro‘yxatdan o‘tish: emailga kod keldi", code is not None)
    r = anon.req("POST", "/api/auth/register/verify", {"registration_id": r.json()["registration_id"], "code": code})
    check("Ro‘yxatdan o‘tish: kod tasdiqlandi", r.status_code == 200, r.text[:200])
    r = anon.req("POST", "/api/auth/login", {"email": anon.email, "password": PW})
    check("Tasdiqlanmagan hisob kira olmaydi", r.status_code == 403 and r.json()["code"] == "pending_approval", r.text[:200])
    check("Adminga ro‘yxatdan o‘tish haqida email bordi",
          any("ro‘yxatdan o‘tish" in s for _, s in mails_to("admin@maktab.uz")))
    bell = [n for n in admin.items("notification") if n["recipientUserId"] == ids["admin@maktab.uz"]]
    check("Adminning qo‘ng‘iroqchasiga xabar tushdi", any(n["type"] == "SIGNUP" for n in bell))

    pending = [u for u in admin.req("GET", "/api/admin/users").json()
               if u["pending_approval"] and u["email"] == "yangi.xodim@maktab.uz"]
    r = admin.req("POST", f"/api/admin/users/{pending[0]['id']}/approve", {"institution_id": inst})
    check("Admin ro‘yxatdan o‘tganni tasdiqladi", r.status_code == 200, r.text[:200])
    r = anon.login()
    check("Tasdiqlangan xodim kod bilan kirdi", r.status_code == 200 and r.json()["state"] == "ok", r.text[:200])

    # --- duplicates
    dup = Actor("x@maktab.uz")
    r = dup.req("POST", "/api/auth/register", {
        "first_name": "Ikki", "last_name": "Nusxa", "email": "boshqa@maktab.uz", "phone": "91 222 33 44",
        "role": "TEACHER", "institution_name": "14-sonli maktab", "password": PW})
    check("Bir xil telefon bilan ikkinchi hisob ochilmaydi", r.status_code == 409, r.text[:200])

    # --- children and teams
    t = Actor("oqituvchi@maktab.uz"); t.login()
    psy = Actor("psixolog@maktab.uz"); psy.login()
    log = Actor("logoped@maktab.uz"); log.login()
    kid = {"firstName": "Bobur", "lastName": "Karimov", "dateOfBirth": "2016-03-01", "gender": "Erkak",
           "grade": "2-sinf", "status": "Faol", "primaryNeed": "Nutq", "supportLevel": "1-daraja",
           "createdAt": "2026-11-01T09:00:00"}
    r = t.put(("student", "e2e1", kid))
    check("O‘qituvchi bola qo‘shdi (serverga saqlandi)", r.status_code == 200, r.text[:200])
    check("Begona mutaxassis bolani ko‘rmaydi", all(s["id"] != "e2e1" for s in log.items("student")))
    team = sorted([ids["oqituvchi@maktab.uz"], ids["psixolog@maktab.uz"]])
    r = t.put(("student", "e2e1", {**kid, "assignedSpecialistIds": team}))
    check("Hamkasbni jamoaga bog‘lash", r.status_code == 200, r.text[:200])
    check("Bog‘langan psixolog bolani ko‘radi", any(s["id"] == "e2e1" for s in psy.items("student")))
    r = psy.put(("observation", "obs1", {"studentId": "e2e1", "isConfidential": True, "text": "maxfiy"}))
    check("Psixolog maxfiy kuzatuv yozdi", r.status_code == 200, r.text[:200])
    check("O‘qituvchi maxfiy kuzatuvni ko‘rmaydi", all(o["id"] != "obs1" for o in t.items("observation")))
    check("Admin maxfiy kuzatuvni ko‘radi", any(o["id"] == "obs1" for o in admin.items("observation")))
    r = t.put(("session", "ses1", {"studentId": "e2e1", "date": "2026-11-05", "topic": "Nutq"}))
    check("Mashg‘ulot qo‘shildi", r.status_code == 200, r.text[:200])
    ch = admin.req("GET", "/api/admin/changes").json()
    check("Admin tarixda o‘zgarishlarni ko‘radi", any(c["kind"] == "student" for c in ch) and any(c["kind"] == "session" for c in ch))

    # --- profile
    r = t.req("PATCH", "/api/auth/profile", {"specialization": "Matematika", "phone": "+998 93 777 66 55"})
    check("Profilni tahrirlash", r.status_code == 200, r.text[:200])
    r = psy.req("PATCH", "/api/auth/profile", {"phone": "93 777 66 55"})
    check("Boshqa xodimning telefonini olib bo‘lmaydi", r.status_code == 409, r.text[:200])

    # --- admin creates staff: temporary password by email, must change it
    r = admin.req("POST", "/api/admin/users", {"email": "yangi.oqituvchi@maktab.uz", "full_name": "Yangi O‘qituvchi",
                                               "role": "TEACHER", "institution_id": inst})
    check("Admin xodim yaratdi", r.status_code == 201, r.text[:200])
    temp = [s for _, s in mails_to("yangi.oqituvchi@maktab.uz")]
    check("Yangi xodimga hisob xati bordi", any("hisobingiz yaratildi" in s for s in temp), temp)

    # --- password change while signed in
    r = log.req("POST", "/api/auth/password/change/request", {})
    code = last_code("logoped@maktab.uz") if r.status_code == 200 else None
    r = log.req("POST", "/api/auth/password/change", {"current_password": PW, "new_password": NEW_PW,
                                                       **({"code": code} if code else {})})
    check("Parolni almashtirish (kirgan holda)", r.status_code == 200, r.text[:200])
    time.sleep(6)
    log2 = Actor("logoped@maktab.uz", NEW_PW)
    r = log2.login()
    check("Yangi parol bilan kirish", r.status_code == 200 and r.json().get("state") == "ok", r.text[:200])

    # --- password reset (forgot password)
    before = len(mails_to("psixolog@maktab.uz"))
    r = Actor("x").req("POST", "/api/auth/password/reset/request", {"email": "psixolog@maktab.uz"})
    check("Parolni tiklash: so‘rov qabul qilindi", r.status_code in (200, 202), r.text[:200])
    after = mails_to("psixolog@maktab.uz")
    check("Parolni tiklash: emailga kod keldi", len(after) > before, after[-1:] if after else "xat yo‘q")
    code = last_code("psixolog@maktab.uz")
    r = Actor("x").req("POST", "/api/auth/password/reset/confirm",
                       {"email": "psixolog@maktab.uz", "code": code, "new_password": NEW_PW})
    check("Parolni tiklash: yangi parol o‘rnatildi", r.status_code == 200, r.text[:200])
    time.sleep(6)
    r = Actor("psixolog@maktab.uz", NEW_PW).login()
    check("Parolni tiklash: yangi parol bilan kirish", r.status_code == 200 and r.json().get("state") == "ok", r.text[:200])
    r = Actor("x").req("POST", "/api/auth/password/reset/request", {"email": "PsiXolog@Maktab.uz"})
    check("Parolni tiklash: email katta harf bilan yozilsa ham ishlaydi", r.status_code in (200, 202), r.text[:200])

    # --- wrong password message
    r = Actor("oqituvchi@maktab.uz").req("POST", "/api/auth/login", {"email": "oqituvchi@maktab.uz", "password": "Xato-123456"})
    check("Noto‘g‘ri parol: oddiy xabar", r.status_code == 401 and r.json()["message"] == "Login yoki parol noto‘g‘ri", r.text[:200])

    # --- account deletion
    r = anon.req("POST", "/api/auth/account/delete", {"password": PW})
    check("Hisobni o‘chirish", r.status_code == 200, r.text[:200])
    r = Actor("yangi.xodim@maktab.uz").req("POST", "/api/auth/login", {"email": "yangi.xodim@maktab.uz", "password": PW})
    check("O‘chirilgan hisob kira olmaydi", r.status_code == 401, r.text[:200])

    # --- web pages
    for path in ("/", "/account-deletion.html", "/robots.txt", "/sitemap.xml"):
        r = httpx.get(BASE + path)
        check(f"Sahifa ochiladi: {path}", r.status_code == 200, r.status_code)

    failed = [n for n, ok, _ in RESULTS if not ok]
    print(f"\n{len(RESULTS) - len(failed)}/{len(RESULTS)} OK")
    sys.exit(1 if failed else 0)


main()
