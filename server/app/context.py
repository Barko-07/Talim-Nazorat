from __future__ import annotations

from dataclasses import dataclass, field

from .config import Settings
from .db import Database
from .mailer import Mailer
from .security.ratelimit import DbRateLimiter, MemoryRateLimiter


@dataclass
class AppContext:
    settings: Settings
    db: Database
    mailer: Mailer
    db_limiter: DbRateLimiter = field(default_factory=DbRateLimiter)
    mem_limiter: MemoryRateLimiter = field(default_factory=MemoryRateLimiter)
