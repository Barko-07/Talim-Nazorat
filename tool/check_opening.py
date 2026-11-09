"""Checks the opening sequence of the site in a real browser: the HTML loading
screen shows at once, the Flutter opening animation follows, then the landing
page; the loading screen is gone. Screenshots to build/opening/.

    python tool/check_opening.py [url]      (default: local preview)
"""
import asyncio
import sys
from pathlib import Path

from playwright.async_api import async_playwright

URL = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8780/"
OUT = Path(__file__).resolve().parent.parent / "build" / "opening"


async def main():
    OUT.mkdir(parents=True, exist_ok=True)
    ok = True
    async with async_playwright() as p:
        b = await p.chromium.launch()
        # A normal visitor (no "reduce motion": then the animation is skipped on purpose).
        ctx = await b.new_context(viewport={"width": 390, "height": 844}, device_scale_factor=2,
                                  reduced_motion="no-preference")
        page = await ctx.new_page()
        await page.add_init_script("""
          window.__t0 = Date.now();
          new MutationObserver(ms => { for (const m of ms) {
            if (m.target.id === 'app-splash' && m.attributeName === 'class' && !window.__hiddenAt)
              window.__hiddenAt = Date.now() - window.__t0; } })
            .observe(document, {subtree: true, attributes: true});
        """)
        errors = []
        page.on("pageerror", lambda e: errors.append(str(e)[:200]))
        # Slow the network a little, like a phone on mobile data.
        cdp = await page.context.new_cdp_session(page)
        await cdp.send("Network.emulateNetworkConditions", {
            "offline": False, "latency": 150, "downloadThroughput": 1_500_000, "uploadThroughput": 500_000})
        await page.goto(URL, wait_until="commit")
        await page.wait_for_timeout(700)
        splash = await page.locator("#app-splash").count()
        await page.screenshot(path=str(OUT / "1_loading.png"))
        print(("OK   " if splash else "FAIL ") + "Yuklanish ekrani darhol ko‘rinadi")
        ok &= bool(splash)
        await page.wait_for_selector("flutter-view, flt-glass-pane", state="attached", timeout=90000)
        await page.wait_for_timeout(900)
        await page.screenshot(path=str(OUT / "2_intro.png"))
        await page.wait_for_timeout(3500)
        await page.screenshot(path=str(OUT / "3_landing.png"))
        shown_ms = await page.evaluate("window.__hiddenAt || 0")
        long_enough = shown_ms >= 2300
        print(("OK   " if long_enough else "FAIL ") + f"Ochilish animatsiyasi to‘liq ko‘rindi ({shown_ms} ms)")
        ok &= long_enough
        gone = await page.locator("#app-splash").count() == 0
        print(("OK   " if gone else "FAIL ") + "Ilova ochilgach yuklanish ekrani olib tashlandi")
        ok &= gone
        print(("OK   " if not errors else "FAIL ") + "JavaScript xatosi yo‘q", errors[:2])
        ok &= not errors
        await b.close()
    print(f"skrinshotlar: {OUT}")
    sys.exit(0 if ok else 1)


asyncio.run(main())
