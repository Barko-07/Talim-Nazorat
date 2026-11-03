"""Individ API application factory and security middleware."""
from __future__ import annotations

import logging
from urllib.parse import urlsplit

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.middleware.trustedhost import TrustedHostMiddleware

from . import crypto
from .config import Settings, load_settings
from .context import AppContext
from .db import Database
from .deps import SAFE_METHODS, client_ip
from .mailer import Mailer
from .routes import admin, auth, students
from .security import audit

log = logging.getLogger("individ")

SECURITY_HEADERS = {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Referrer-Policy": "no-referrer",
    "Permissions-Policy": "camera=(), microphone=(), geolocation=(), payment=()",
    "Cross-Origin-Opener-Policy": "same-origin",
    "Cross-Origin-Resource-Policy": "same-origin",
    # The API only returns JSON: nothing in a response may ever execute.
    "Content-Security-Policy": "default-src 'none'; frame-ancestors 'none'; base-uri 'none'",
    "Cache-Control": "no-store",
}


def _allowed_origins(s: Settings) -> set[str]:
    allowed = set(s.allowed_origins)
    if s.public_base_url:
        parts = urlsplit(s.public_base_url)
        allowed.add(f"{parts.scheme}://{parts.netloc}")
    return allowed


class SecurityMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        ctx: AppContext = request.app.state.ctx
        s = ctx.settings
        ip = client_ip(request)
        path = request.url.path

        def deny(status: int, code: str, message: str, action: str | None = None):
            # Throttled: a flood of rejected requests must not become a flood of DB writes.
            if action and ctx.mem_limiter.hit(f"audit:{action}:{ip}", 5, 60):
                db = ctx.db.sessionmaker()
                try:
                    audit.record(db, action, severity="warning", ip=ip,
                                 detail=f"{request.method} {path}"[:200], webhook_url=s.alert_webhook_url)
                finally:
                    db.close()
            return self._headers(JSONResponse({"code": code, "message": message}, status_code=status), s)

        # 1. HTTPS only (nginx terminates TLS and tells us the original scheme).
        if s.is_production:
            peer = request.client.host if request.client else ""
            proto = request.headers.get("x-forwarded-proto", "") if peer in s.trusted_proxies else request.url.scheme
            if proto != "https":
                return deny(400, "https_required", "Faqat HTTPS orqali ulaning")

        # 2. Request size limit.
        length = request.headers.get("content-length")
        if length and (not length.isdigit() or int(length) > s.max_body_bytes):
            return deny(413, "too_large", "So‘rov hajmi juda katta", "REQUEST_TOO_LARGE")

        # 3. General API rate limit per client IP.
        if path.startswith("/api/") and not ctx.mem_limiter.hit(f"api:{ip}", s.api_per_minute):
            return deny(429, "rate_limited", "Juda ko‘p so‘rov. Birozdan so‘ng urinib ko‘ring", "RATE_LIMITED")

        # 4. CSRF defence for state-changing requests: a custom header (forces a
        #    CORS preflight, which foreign sites fail) and an Origin allowlist.
        if path.startswith("/api/") and request.method not in SAFE_METHODS:
            if request.headers.get("x-requested-with") != "XMLHttpRequest":
                return deny(403, "csrf", "So‘rov rad etildi", "CSRF_REJECTED")
            origin = request.headers.get("origin")
            allowed = _allowed_origins(s)
            if origin and allowed and origin not in allowed:
                return deny(403, "csrf", "So‘rov rad etildi", "CSRF_REJECTED")
            if origin and not allowed and s.is_production:
                return deny(403, "csrf", "So‘rov rad etildi", "CSRF_REJECTED")

        response = await call_next(request)
        return self._headers(response, s)

    @staticmethod
    def _headers(response, s: Settings):
        for k, v in SECURITY_HEADERS.items():
            response.headers.setdefault(k, v)
        if s.is_production:
            response.headers["Strict-Transport-Security"] = "max-age=63072000; includeSubDomains; preload"
        if "server" in response.headers:
            del response.headers["server"]
        return response


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or load_settings()
    crypto.configure(settings.data_encryption_key, settings.secret_key)
    database = Database(settings.database_url)
    if not settings.is_production:
        database.create_all()  # production schema is created by `python -m app.cli init-db`

    app = FastAPI(
        title="Individ API",
        # No public API documentation in production (less attack surface).
        docs_url=None if settings.is_production else "/api/docs",
        redoc_url=None,
        openapi_url=None if settings.is_production else "/api/openapi.json",
    )
    app.state.ctx = AppContext(settings=settings, db=database, mailer=Mailer(settings))

    if settings.allowed_origins:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=settings.allowed_origins,
            allow_credentials=True,
            allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
            allow_headers=["Content-Type", "X-CSRF-Token", "X-Requested-With"],
            max_age=600,
        )
    app.add_middleware(SecurityMiddleware)
    if settings.is_production and settings.public_base_url:
        app.add_middleware(TrustedHostMiddleware, allowed_hosts=[urlsplit(settings.public_base_url).hostname])

    @app.exception_handler(StarletteHTTPException)
    async def http_error(request: Request, exc: StarletteHTTPException):
        detail = exc.detail if isinstance(exc.detail, dict) else {"code": "error", "message": "Xatolik"}
        if exc.status_code == 404 and not isinstance(exc.detail, dict):
            detail = {"code": "not_found", "message": "Topilmadi"}
        return JSONResponse(detail, status_code=exc.status_code)

    @app.exception_handler(RequestValidationError)
    async def validation_error(request: Request, exc: RequestValidationError):
        # Field names and reasons only - the submitted values (e.g. passwords)
        # are never echoed back.
        errors = [{"field": ".".join(str(x) for x in e["loc"][1:]), "message": e["msg"]} for e in exc.errors()]
        return JSONResponse({"code": "validation", "message": "Ma’lumotlar noto‘g‘ri", "errors": errors[:20]},
                            status_code=422)

    @app.exception_handler(Exception)
    async def unhandled(request: Request, exc: Exception):
        log.exception("unhandled error on %s %s", request.method, request.url.path)
        return JSONResponse({"code": "server_error", "message": "Serverda xatolik"}, status_code=500)

    @app.get("/api/health")
    def health():
        return {"status": "ok"}

    app.include_router(auth.router)
    app.include_router(admin.router)
    app.include_router(students.router)
    return app
