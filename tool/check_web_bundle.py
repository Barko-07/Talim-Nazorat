"""Serves a built web bundle locally with the production Content Security
Policy and checks in headless Chromium that the Flutter app actually starts.

    python tool/check_web_bundle.py build/web_server server/deploy/nginx/individ_headers.conf

Exit code 0 only if the app's view appears with no CSP violations or page errors.
"""
from __future__ import annotations

import asyncio
import functools
import http.server
import re
import sys
import threading

from playwright.async_api import async_playwright


def production_csp(headers_conf: str) -> str:
    text = open(headers_conf, encoding="utf-8").read()
    m = re.search(r'Content-Security-Policy\s+"([^"]+)"', text)
    if not m:
        raise SystemExit("CSP not found in " + headers_conf)
    # upgrade-insecure-requests would turn the local http:// requests into https://.
    return m.group(1).replace("; upgrade-insecure-requests", "")


def serve(root: str, csp: str) -> http.server.ThreadingHTTPServer:
    class Handler(http.server.SimpleHTTPRequestHandler):
        def end_headers(self):
            self.send_header("Content-Security-Policy", csp)
            super().end_headers()

        def log_message(self, *args):
            pass

    httpd = http.server.ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Handler, directory=root))
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    return httpd


async def check(url: str) -> list[str]:
    problems: list[str] = []
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        page = await browser.new_page(viewport={"width": 1280, "height": 800})
        page.on("pageerror", lambda e: problems.append(f"page error: {str(e)[:300]}"))
        page.on("console", lambda m: problems.append(f"console: {m.text[:300]}")
                if m.type == "error" and "Content Security Policy" in m.text else None)
        # A missing file is reported with its address. /api/ is not served here
        # (no backend in this check), so its answers are ignored.
        page.on("response", lambda r: problems.append(f"HTTP {r.status}: {r.url}")
                if r.status >= 400 and "/api/" not in r.url else None)
        await page.goto(url, wait_until="networkidle", timeout=60000)
        try:
            await page.wait_for_selector("flutter-view, flt-glass-pane", state="attached", timeout=30000)
        except Exception:  # noqa: BLE001
            problems.append("the Flutter view never appeared (blank page)")
        await page.wait_for_timeout(3000)
        await browser.close()
    return problems


def main() -> int:
    root, headers_conf = sys.argv[1], sys.argv[2]
    httpd = serve(root, production_csp(headers_conf))
    try:
        problems = asyncio.run(check(f"http://127.0.0.1:{httpd.server_address[1]}/"))
    finally:
        httpd.shutdown()
    if problems:
        print("\n".join(problems), file=sys.stderr)
        return 1
    print("page starts under the production CSP")
    return 0


if __name__ == "__main__":
    sys.exit(main())
