"""Lists what a screen reader (and so a browser test) sees on a screen of the
local preview: buttons, text fields and labels. Used to write ui_e2e.py.

    python tool/ui_probe.py            (landing -> login -> register -> reset)
"""
import asyncio

from playwright.async_api import async_playwright

BASE = "http://127.0.0.1:8780"


async def dump(page, title):
    nodes = await page.evaluate("""() => [...document.querySelectorAll('flt-semantics, input, textarea')]
        .map(e => ({tag: e.tagName.toLowerCase(), role: e.getAttribute('role') || '',
                    label: (e.getAttribute('aria-label') || e.innerText || e.getAttribute('placeholder') || '').trim().slice(0, 70)}))
        .filter(n => n.label || n.tag !== 'flt-semantics')""")
    print(f"\n=== {title}")
    seen = set()
    for n in nodes:
        key = (n["tag"], n["role"], n["label"])
        if key in seen:
            continue
        seen.add(key)
        print(f"  {n['tag']:14} {n['role']:10} {n['label']}")


async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch()
        page = await b.new_page(viewport={"width": 1280, "height": 900})
        await page.goto(BASE + "/", wait_until="networkidle")
        await page.wait_for_timeout(2500)
        await page.evaluate("document.querySelector('flt-semantics-placeholder')?.click()")
        await page.wait_for_timeout(800)
        await dump(page, "landing")
        await page.get_by_role("button", name="Kirish").first.click()
        await page.wait_for_timeout(1500)
        await dump(page, "login")
        await page.get_by_role("button", name="Parolni unutdingizmi?").click()
        await page.wait_for_timeout(1500)
        await dump(page, "password reset")
        await page.go_back()
        await page.wait_for_timeout(1500)
        await page.get_by_role("button", name="Ro‘yxatdan o‘tish").last.click()
        await page.wait_for_timeout(1500)
        await dump(page, "register")
        await b.close()


asyncio.run(main())
