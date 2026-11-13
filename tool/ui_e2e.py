"""Browser end-to-end test of the main journeys on the local preview
(tool/local_preview.py on http://127.0.0.1:8780, fresh database). Drives a
real Chromium like a person: types into fields, presses buttons, reads what
the screen says. Screenshots of every step go to build/ui_e2e/.

    python tool/ui_e2e.py              all journeys
    python tool/ui_e2e.py --probe      also print each screen's elements

Restart the preview before a run: the journeys expect its seeded state.
"""
import asyncio
import re
import sys
import time
from pathlib import Path

from playwright.async_api import async_playwright

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

BASE = "http://127.0.0.1:8780"
REPO = Path(__file__).resolve().parent.parent
MAIL = REPO / "build" / "local_preview" / "dev-mail.txt"
SHOTS = REPO / "build" / "ui_e2e"
PW = "Individ-Lokal-Sinov-2026"
NEW_PW = "Tiklangan-Parol-Brauzer-2026"
PROBE = "--probe" in sys.argv
RESULTS = []
# A new person each run: the server refuses a second account for one email/phone.
RUN = int(time.time()) % 10_000_000
REG_EMAIL = f"gulnora{RUN}@maktab.uz"
REG_PHONE = f"+998 94 {RUN:07d}"


def last_code(email, after=0.0):
    for _ in range(30):
        lines = MAIL.read_text(encoding="utf-8").splitlines() if MAIL.exists() else []
        codes = [l.split("\t")[1] for l in lines if l.startswith(email + "\t") and l.split("\t")[1] != "-"]
        if codes:
            return codes[-1]
        time.sleep(0.3)
    return None


def mail_count(email):
    if not MAIL.exists():
        return 0
    return sum(1 for l in MAIL.read_text(encoding="utf-8").splitlines() if l.startswith(email + "\t"))


class Screen:
    """One browser tab with helpers that work on Flutter's accessibility tree."""

    def __init__(self, page, name):
        self.page, self.name, self.step = page, name, 0
        self.errors = []
        page.on("pageerror", lambda e: self.errors.append(str(e)[:200]))

    async def open(self, path="/"):
        await self.page.goto(BASE + path, wait_until="networkidle")
        # The opening animation plays first (about 2.3 s); wait for the page.
        for _ in range(20):
            await self.page.wait_for_timeout(500)
            await self.semantics()
            if await self.page.get_by_role("button", name="Kirish", exact=True).count():
                break

    async def semantics(self):
        await self.page.evaluate("document.querySelector('flt-semantics-placeholder')?.click()")
        await self.page.wait_for_timeout(500)

    async def shot(self, label):
        self.step += 1
        SHOTS.mkdir(parents=True, exist_ok=True)
        await self.page.screenshot(path=str(SHOTS / f"{self.name}_{self.step:02d}_{label}.png"))

    async def probe(self, title):
        if not PROBE:
            return
        nodes = await self.page.evaluate("""() => [...document.querySelectorAll('flt-semantics[role], input, textarea, flt-semantics')]
            .map(e => ((e.getAttribute('role') || e.tagName.toLowerCase()) + '  ' +
                       (e.getAttribute('aria-label') || (e.children.length ? '' : e.innerText) || '').trim().slice(0, 70)))""")
        print(f"\n--- {self.name}: {title}")
        for n in dict.fromkeys(nodes):
            if n.strip() and not n.endswith("  "):
                print("   ", n)

    def field(self, label):
        return self.page.locator(f'input[aria-label="{label}"], textarea[aria-label="{label}"]').first

    async def type(self, label, text):
        """Types like a person, then checks the field really holds the text
        (a keystroke can be lost while Flutter moves the focus) and retries."""
        f = self.field(label)
        for _ in range(3):
            await f.click()
            await self.page.wait_for_timeout(250)
            await self.page.keyboard.press("Control+A")
            await self.page.keyboard.press("Backspace")
            await self.page.keyboard.type(text, delay=25)
            await self.page.wait_for_timeout(200)
            value = await f.input_value()
            # Telefon maydoni raqamni o'zi guruhlaydi ("+998 94 429 73 72"):
            # raqamlar bir xil bo'lsa — to'g'ri yozilgan.
            digits = lambda x: re.sub(r"\D", "", x)
            if value == text or (label == "Telefon" and digits(value).endswith(digits(text)[-9:])):
                return
        raise AssertionError(f"could not type into {label!r}")

    async def press(self, name, last=False):
        exact = isinstance(name, str)
        btn = self.page.get_by_role("button", name=name, exact=exact) if exact else self.page.get_by_role("button", name=name)
        btn = btn.last if last else btn.first
        await btn.click()
        await self.page.wait_for_timeout(1200)
        await self.semantics()

    async def choose(self, item):
        """Picks an entry in an open dropdown menu."""
        await self.page.get_by_role("menuitem", name=item, exact=True).first.click()
        await self.page.wait_for_timeout(900)
        await self.semantics()

    async def sees(self, text, timeout=6000):
        """The text is on screen - as visible text or as an element's label."""
        target = self.page.get_by_text(text, exact=False).or_(
            self.page.locator(f'[aria-label*="{text}"]'))
        try:
            await target.first.wait_for(state="attached", timeout=timeout)
            return True
        except Exception:  # noqa: BLE001
            return False

    async def press_near(self, button, label):
        """Presses the `button` that comes right after the element labelled
        `label` (e.g. "Tasdiqlash" in one person's row of a list)."""
        anchor = self.page.locator(f'[aria-label*="{label}"]').last
        ay = (await anchor.bounding_box())["y"]
        best, best_y = None, None
        btns = self.page.get_by_role("button", name=button, exact=True)
        for i in range(await btns.count()):
            box = await btns.nth(i).bounding_box()
            if box and box["y"] >= ay and (best_y is None or box["y"] < best_y):
                best, best_y = btns.nth(i), box["y"]
        await best.click()
        await self.page.wait_for_timeout(1200)
        await self.semantics()

    async def code(self, email):
        code = last_code(email)
        inp = self.page.locator("input").first
        await inp.click()
        await self.page.keyboard.type(code or "000000", delay=60)
        await self.page.wait_for_timeout(2500)
        await self.semantics()


def check(name, cond, detail=""):
    RESULTS.append((name, bool(cond)))
    print(("OK   " if cond else "FAIL ") + name + ("" if cond else f"  <- {detail}"))
    return cond


async def login(s, email, password=PW):
    await s.open()
    await s.press("Kirish")
    await s.type("Email", email)
    await s.type("Parol", password)
    await s.press("Kirish", last=True)
    # Wait for the server: the code screen appears once the password is checked.
    try:
        await s.page.get_by_role("button", name="Tasdiqlash", exact=True).first.wait_for(
            state="attached", timeout=20000)
    except Exception:
        await s.shot("login_stuck")
        await s.probe("login stuck")
        raise
    await s.probe("after password")
    await s.shot("code")
    await s.code(email)
    await s.page.wait_for_timeout(3000)


async def journey_login(b):
    s = Screen(await b.new_page(viewport={"width": 1280, "height": 900}), "login")
    await login(s, "admin@maktab.uz")
    await s.shot("admin")
    check("Kirish: email + parol + kod -> admin panel", await s.sees("Boshqaruv paneli"))
    await s.press(re.compile("Barkamol Olimov"))
    await s.probe("profile menu")
    await s.press("Tizimdan chiqish")
    await s.probe("logout dialog")
    await s.shot("logout_dialog")
    btns = s.page.get_by_role("button", name="Ha, chiqish", exact=True)
    if await btns.count():
        await btns.last.click()
        await s.page.wait_for_timeout(2000)
    await s.shot("after_logout")
    check("Chiqish: kirish sahifasiga qaytdi", await s.sees("Kirish"))
    check("Kirish/chiqish: sahifada JavaScript xatosi yo‘q", not s.errors, s.errors)


async def journey_wrong_password(b):
    s = Screen(await b.new_page(viewport={"width": 1280, "height": 900}), "wrongpw")
    await s.open()
    await s.press("Kirish")
    await s.type("Email", "oqituvchi@maktab.uz")
    await s.type("Parol", "Notogri-Parol-1")
    await s.press("Kirish", last=True)
    await s.shot("message")
    check("Noto‘g‘ri parol: 'Login yoki parol noto‘g‘ri' ko‘rinadi", await s.sees("Login yoki parol noto‘g‘ri"))


async def journey_reset(b):
    s = Screen(await b.new_page(viewport={"width": 1280, "height": 900}), "reset")
    email = "logoped@maktab.uz"
    await s.open()
    await s.press("Kirish")
    await s.press("Parolni unutdingizmi?")
    before = mail_count(email)
    await s.type("Elektron pochta", email)
    await s.press("Kod yuborish")
    await s.probe("after send")
    await s.shot("code_screen")
    check("Parolni tiklash: emailga kod yuborildi", mail_count(email) > before)
    code = last_code(email)
    fields = s.page.locator("input")
    n = await fields.count()
    check("Parolni tiklash: kod va yangi parol maydonlari bor", n >= 2, n)
    await fields.nth(0).click()
    await s.page.wait_for_timeout(250)
    await s.page.keyboard.type(code, delay=40)
    await s.type("Yangi parol", NEW_PW)
    await s.type("Yangi parolni takrorlang", NEW_PW)
    await s.shot("filled")
    for name in ("Parolni yangilash", "Saqlash", "Tasdiqlash", "Parolni tiklash"):
        btn = s.page.get_by_role("button", name=name, exact=True)
        if await btn.count():
            await btn.last.click()
            break
    await s.page.wait_for_timeout(2500)
    await s.semantics()
    await s.probe("after confirm")
    await s.shot("done")
    check("Parolni tiklash: forma xatosiz qabul qildi",
          not await s.sees("farq qilishi kerak", timeout=1500) and not await s.sees("noto‘g‘ri", timeout=1500))
    s2 = Screen(await b.new_page(viewport={"width": 1280, "height": 900}), "reset_login")
    time.sleep(6)
    await login(s2, email, NEW_PW)
    await s2.shot("in")
    check("Parolni tiklash: yangi parol bilan kirildi", await s2.sees("Bosh sahifa"))


async def journey_register(b):
    s = Screen(await b.new_page(viewport={"width": 1280, "height": 900}), "register")
    await s.open()
    await s.press("Ro‘yxatdan o‘tish")
    await s.type("Ism", "Gulnora")
    await s.type("Familiya", "Tursunova")
    await s.press("Keyingisi")
    await s.probe("step 2")
    await s.shot("step2")
    check("Ro‘yxatdan o‘tish: 2-qadamga o‘tdi", await s.sees("QADAM 2"))
    await s.press("Amaliyotchi psixolog")
    await s.press("Chortoq tumani")
    await s.choose("Chortoq tumani")
    await s.probe("step 2 district chosen")
    await s.press(re.compile("Tanlash"))
    # The list comes from the server: the school as the administrator named it.
    await s.press("14-sonli maktab")
    await s.probe("step 2 school chosen")
    await s.shot("step2_filled")
    await s.press("Keyingisi")
    await s.probe("step 3")
    await s.shot("step3")
    await s.type("Telefon", REG_PHONE)
    await s.type("Email", REG_EMAIL)
    await s.press("Keyingisi")
    await s.probe("step 4")
    await s.shot("step4")
    await s.type("Parol", PW)
    await s.type("Parolni takrorlang", PW)
    # Without the privacy consent the form is not sent.
    await s.page.get_by_role("checkbox").last.click()
    await s.page.wait_for_timeout(500)
    await s.shot("consent")
    await s.press("Ro‘yxatdan o‘tish", last=True)
    await s.page.wait_for_timeout(2500)
    await s.semantics()
    await s.probe("registration code")
    await s.shot("reg_code")
    check("Ro‘yxatdan o‘tish: emailga kod keldi", last_code(REG_EMAIL) is not None)
    await s.code(REG_EMAIL)
    await s.page.wait_for_timeout(2000)
    await s.semantics()
    await s.probe("after registration code")
    await s.shot("reg_done")
    # No administrator approval: the code signs the person straight in.
    check("Ro‘yxatdan o‘tish: kod bilan darhol o‘z ish sahifasiga kirdi", await s.sees("Bosh sahifa"))
    check("Ro‘yxatdan o‘tish: tanlangan maktab hisobga yozildi", await s.sees("14-sonli maktab"))

    # The administrator sees the new colleague among the accounts (and could block them).
    a = Screen(await b.new_page(viewport={"width": 1440, "height": 900}), "admin_sees")
    await login(a, "admin@maktab.uz")
    await a.press("Foydalanuvchilar")
    await a.probe("users page")
    await a.shot("users")
    check("Admin: yangi xodim Foydalanuvchilar ro‘yxatida", await a.sees("Tursunova Gulnora"))
    check("Admin: tasdiq kutayotganlar bo‘limi yo‘q", not await a.sees("Tasdiq kutayotganlar", timeout=1500))

    g = Screen(await b.new_page(viewport={"width": 1280, "height": 900}), "newuser")
    await login(g, REG_EMAIL)
    await g.probe("new user home")
    await g.shot("home")
    check("Yangi xodim keyin odatdagidek (parol + kod) kiradi", await g.sees("Bosh sahifa"))


async def journey_add_child(b):
    s = Screen(await b.new_page(viewport={"width": 1280, "height": 900}), "child")
    await login(s, "oqituvchi@maktab.uz")
    await s.probe("teacher home")
    await s.press(re.compile("Bola qo‘shish$"))
    await s.probe("add child form")
    await s.shot("form")
    await s.type("Familiyasi *", "Rustamov")
    await s.type("Ismi *", "Sanjar")
    await s.type("Sinfi *", "1-A")
    check("Bola qo‘shish: maktab o‘qituvchining o‘z maktabi (tanlanmaydi)", await s.sees("14-sonli maktab"))
    await s.press(re.compile("^Ta’lim shakli"))
    await s.choose("Uyda yakka tartibda")
    await s.shot("filled")
    # The save button is at the bottom of a long form: scroll to it and click
    # it where it is drawn, like a person would.
    await s.page.mouse.move(640, 450)
    await s.page.mouse.wheel(0, 4000)
    await s.page.wait_for_timeout(900)
    await s.semantics()
    box = await s.page.get_by_role("button", name="Saqlash", exact=True).first.bounding_box()
    await s.page.mouse.click(box["x"] + box["width"] / 2, box["y"] + box["height"] / 2)
    await s.page.wait_for_timeout(2500)
    await s.semantics()
    await s.probe("after save")
    await s.shot("saved")
    if PROBE:
        texts = await s.page.evaluate("""() => [...document.querySelectorAll('flt-semantics')]
            .map(e => (e.getAttribute('aria-label') || e.innerText || '').trim())
            .filter(t => /kirit|majburiy|xato|ruxsat|to‘ldir|tanlang|noto/i.test(t))""")
        print("   messages:", texts[:10], "errors:", s.errors[:3])
        await s.page.mouse.wheel(0, 3000)
        await s.page.wait_for_timeout(800)
        await s.shot("saved_bottom")
    await s.press(re.compile(r"^Bolalar(\s+\d+)?$"))
    await s.page.wait_for_timeout(1500)
    await s.shot("list")
    check("Bola qo‘shildi va 'Bolalar'da ko‘rinadi", await s.sees("Rustamov Sanjar") or await s.sees("Sanjar"))
    # Saved on the server: another session of the same teacher sees it too.
    s2 = Screen(await b.new_page(viewport={"width": 1280, "height": 900}), "child_again")
    time.sleep(6)
    await login(s2, "oqituvchi@maktab.uz")
    await s2.press(re.compile(r"^Bolalar(\s+\d+)?$"))
    await s2.page.wait_for_timeout(1500)
    check("Bola serverda saqlangan (boshqa brauzerda ham bor)", await s2.sees("Sanjar"))
    await s2.page.get_by_text("Sanjar", exact=False).or_(s2.page.locator('[aria-label*="Sanjar"]')).first.click()
    await s2.page.wait_for_timeout(2000)
    await s2.semantics()
    await s2.probe("child card")
    await s2.shot("card")
    check("Bola kartasida ta’lim shakli ko‘rinadi", await s2.sees("Uyda yakka tartibda"))
    await s2.press("Hamkasb qo‘shish")
    await s2.probe("colleague dialog")
    await s2.shot("colleague_dialog")
    await s2.press("Rahimova Dilnozani jamoaga qo‘shish")
    await s2.page.wait_for_timeout(2500)
    await s2.shot("colleague_added")
    p = Screen(await b.new_page(viewport={"width": 1280, "height": 900}), "psy")
    await login(p, "psixolog@maktab.uz")
    await p.page.wait_for_timeout(1500)
    await p.shot("home")
    await p.press(re.compile(r"^Bolalar(\s+\d+)?$"))
    await p.page.wait_for_timeout(1500)
    await p.shot("children")
    check("Bog‘langan psixolog bolani ko‘radi", await p.sees("Sanjar") or await p.sees("Rustamov"))


async def journey_admin_pages(b):
    for name, vp in (("desktop", {"width": 1440, "height": 900}), ("phone", {"width": 390, "height": 844})):
        s = Screen(await b.new_page(viewport=vp, is_mobile=name == "phone", has_touch=name == "phone"),
                   f"pages_{name}")
        await login(s, "admin@maktab.uz")
        pages = ["Monitoring markazi", "Tahliliy hisobotlar", "O‘quvchilar reyestri", "Pedagog-mutaxassislar",
                 "Ta’lim muassasalari", "Sinflar va guruhlar", "Yo‘naltirishlar jurnali", "Foydalanuvchilar",
                 "Rollar va ruxsatlar", "Audit jurnali", "Tizim sozlamalari"]
        opened = 0
        for title in pages:
            if name == "phone":
                await s.press("Menyu")
            await s.press(title)
            await s.page.wait_for_timeout(1500)
            await s.shot(title.split()[0])
            opened += 1
        check(f"Admin panel ({name}): {opened} ta sahifa ochildi, JavaScript xatosi yo‘q",
              opened == len(pages) and not s.errors, s.errors[:3])


ALL = {
    "login": journey_login, "wrongpw": journey_wrong_password, "reset": journey_reset,
    "register": journey_register, "child": journey_add_child, "pages": journey_admin_pages,
}
ONLY = [a.split("=", 1)[1] for a in sys.argv if a.startswith("--only=")]


async def main():
    JOURNEYS = [ALL[n] for n in (ONLY[0].split(",") if ONLY else ALL)]
    async with async_playwright() as p:
        b = await p.chromium.launch()
        for j in JOURNEYS:
            try:
                await j(b)
            except Exception as e:  # noqa: BLE001
                check(f"{j.__name__}: tugadi", False, f"{type(e).__name__}: {str(e)[:200]}")
        await b.close()
    failed = [n for n, ok in RESULTS if not ok]
    print(f"\n{len(RESULTS) - len(failed)}/{len(RESULTS)} OK  (skrinshotlar: {SHOTS})")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    asyncio.run(main())
