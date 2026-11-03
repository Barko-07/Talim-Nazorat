"""Individ veb-ilovasini (build/web) xavfsiz sozlamalar bilan tarqatish.

Mahalliy sinov va ichki tarmoq uchun. Ishlab chiqarishda HTTPS orqasida (nginx/Caddy)
ishlatiladi — docs/backend/SECURITY.md ga qarang.

    flutter build web
    python serve_web.py [port]

Muhit o'zgaruvchilari:
    HOST             tinglash manzili (standart: 127.0.0.1 — faqat shu kompyuter)
    ALLOWED_ORIGINS  CORS ruxsat etilgan manbalar, vergul bilan (standart: yo'q — faqat o'z manbasi)
    ENFORCE_CSP      1 — CSP majburiy; aks holda faqat hisobot rejimi (Report-Only)
    BEHIND_HTTPS     1 — HTTPS proksi orqasida (HSTS sarlavhasi yuboriladi)
    RATE_LIMIT       bir IP uchun daqiqasiga so'rovlar soni (standart: 300)
"""
import http.server
import os
import socketserver
import sys
import threading
import time
from collections import defaultdict, deque

ROOT = os.path.dirname(os.path.abspath(__file__))
DIRECTORY = os.path.join(ROOT, "build", "web")

HOST = os.environ.get("HOST", "127.0.0.1")
PORT = 8080
ALLOWED_ORIGINS = {o.strip() for o in os.environ.get("ALLOWED_ORIGINS", "").split(",") if o.strip()}
ENFORCE_CSP = os.environ.get("ENFORCE_CSP") == "1"
BEHIND_HTTPS = os.environ.get("BEHIND_HTTPS") == "1"
RATE_LIMIT = int(os.environ.get("RATE_LIMIT", "300"))

# Flutter veb uchun Content-Security-Policy: skriptlar faqat o'zimizdan va CanvasKit CDN'dan,
# shriftlar Google Fonts'dan. Inline skript yo'q (index.html'dan olib tashlangan).
CSP = "; ".join([
    "default-src 'self'",
    "script-src 'self' 'wasm-unsafe-eval' https://www.gstatic.com",
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
    "font-src 'self' data: https://fonts.gstatic.com",
    "img-src 'self' data: blob:",
    "connect-src 'self' https://www.gstatic.com https://fonts.gstatic.com https://fonts.googleapis.com",
    "worker-src 'self' blob:",
    "object-src 'none'",
    "base-uri 'self'",
    "form-action 'self'",
    "frame-ancestors 'none'",
])

_hits = defaultdict(deque)
_hits_lock = threading.Lock()


def _rate_limited(ip):
    """Oddiy sirpanuvchi oyna: bir IP daqiqasiga RATE_LIMIT dan ortiq so'rov yubora olmaydi."""
    now = time.monotonic()
    with _hits_lock:
        q = _hits[ip]
        while q and now - q[0] > 60:
            q.popleft()
        if len(q) >= RATE_LIMIT:
            return True
        q.append(now)
        if len(_hits) > 10000:  # eskirgan IP yozuvlari xotirani to'ldirmasin
            for stale in [k for k, v in _hits.items() if not v or now - v[-1] > 60]:
                del _hits[stale]
        return False


class SecureHandler(http.server.SimpleHTTPRequestHandler):
    server_version = "TalimNazorat"  # server dasturi versiyasi oshkor qilinmaydi
    sys_version = ""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def list_directory(self, path):
        # Papka tarkibi ko'rsatilmaydi
        self.send_error(404, "Not Found")
        return None

    def _guard(self):
        if _rate_limited(self.client_address[0]):
            self.send_response(429)
            self.send_header("Retry-After", "60")
            self.end_headers()
            return False
        return True

    def do_GET(self):
        if self._guard():
            super().do_GET()

    def do_HEAD(self):
        if self._guard():
            super().do_HEAD()

    def _method_not_allowed(self):
        self.send_response(405)
        self.send_header("Allow", "GET, HEAD")
        self.end_headers()

    do_POST = do_PUT = do_DELETE = do_PATCH = _method_not_allowed

    def do_OPTIONS(self):
        # CORS oldindan so'rovi faqat ruxsat etilgan manbalar uchun
        self.send_response(204 if self.headers.get("Origin") in ALLOWED_ORIGINS else 403)
        self.end_headers()

    def end_headers(self):
        # Kesh: index.html va bootstrap har doim yangi; boshqa fayllar ham (sinov rejimi)
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        # Xavfsizlik sarlavhalari
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("X-Frame-Options", "DENY")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("Permissions-Policy", "camera=(), microphone=(), geolocation=(), payment=()")
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Content-Security-Policy" if ENFORCE_CSP else "Content-Security-Policy-Report-Only", CSP)
        if BEHIND_HTTPS:
            self.send_header("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
        # CORS: "*" emas — faqat ro'yxatdagi manbalar
        origin = self.headers.get("Origin")
        if origin and origin in ALLOWED_ORIGINS:
            self.send_header("Access-Control-Allow-Origin", origin)
            self.send_header("Vary", "Origin")
            self.send_header("Access-Control-Allow-Methods", "GET, HEAD")
        super().end_headers()

    def log_message(self, fmt, *args):
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))


class ReusableTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    allow_reuse_address = True
    daemon_threads = True


if __name__ == "__main__":
    if not os.path.isdir(DIRECTORY):
        sys.exit("build/web topilmadi. Avval: flutter build web")
    port = int(sys.argv[1]) if len(sys.argv) > 1 else PORT
    with ReusableTCPServer((HOST, port), SecureHandler) as httpd:
        mode = "majburiy" if ENFORCE_CSP else "hisobot rejimi"
        print(f"http://{HOST}:{port} — xavfsizlik sarlavhalari yoqilgan (CSP: {mode})")
        httpd.serve_forever()
