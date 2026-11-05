"""Rate limiting.

- DbRateLimiter: fixed-window counters in the database, shared by all server
  workers and kept across restarts. Used for login, MFA and one-time codes.
- MemoryRateLimiter: fast per-process limiter for general API traffic
  (nginx limit_req in deploy/ is the outer layer).
"""
from __future__ import annotations

import random
import threading
import time
from collections import defaultdict, deque

from sqlalchemy import delete, select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..models import RateCounter

MAX_WINDOW_SECONDS = 25 * 3600  # longest window is one day


class DbRateLimiter:
    def hit(self, db: Session, key: str, limit: int, window_seconds: int) -> bool:
        """Counts one attempt; returns False when the limit is exceeded."""
        now = int(time.time())
        # Window start in epoch seconds: comparable across different window sizes.
        window = now - now % window_seconds
        key = key[:160]
        res = db.execute(
            update(RateCounter)
            .where(RateCounter.key == key, RateCounter.window == window)
            .values(count=RateCounter.count + 1)
        )
        if res.rowcount == 0:
            try:
                db.add(RateCounter(key=key, window=window, count=1))
                db.commit()
            except IntegrityError:
                db.rollback()
                db.execute(
                    update(RateCounter)
                    .where(RateCounter.key == key, RateCounter.window == window)
                    .values(count=RateCounter.count + 1)
                )
                db.commit()
        else:
            db.commit()
        count = db.scalar(
            select(RateCounter.count).where(RateCounter.key == key, RateCounter.window == window)
        )
        if random.random() < 0.02:  # occasional cleanup of windows that have ended
            db.execute(delete(RateCounter).where(RateCounter.window < now - MAX_WINDOW_SECONDS))
            db.commit()
        return (count or 0) <= limit


    def count(self, db: Session, key: str, window_seconds: int) -> int:
        """Attempts so far in the current window, without counting a new one."""
        now = int(time.time())
        window = now - now % window_seconds
        return db.scalar(
            select(RateCounter.count).where(RateCounter.key == key[:160], RateCounter.window == window)
        ) or 0


class MemoryRateLimiter:
    def __init__(self) -> None:
        self._hits: dict[str, deque[float]] = defaultdict(deque)
        self._lock = threading.Lock()

    def hit(self, key: str, limit: int, window_seconds: int = 60) -> bool:
        now = time.monotonic()
        with self._lock:
            q = self._hits[key]
            while q and q[0] <= now - window_seconds:
                q.popleft()
            if len(q) >= limit:
                return False
            q.append(now)
            if len(self._hits) > 50_000:  # bound memory under attack
                self._hits.clear()
            return True
