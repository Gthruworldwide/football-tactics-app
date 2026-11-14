"""Redis cache helpers with automatic in-memory fallback (fakeredis)."""

import json
import logging
from functools import lru_cache
from typing import Any, Optional

import redis

from app.core.config import settings

logger = logging.getLogger(__name__)


@lru_cache
def get_redis():
    try:
        r = redis.Redis(
            host=settings.REDIS_HOST,
            port=settings.REDIS_PORT,
            db=settings.REDIS_DB,
            decode_responses=True,
            socket_connect_timeout=1,
        )
        r.ping()
        return r
    except Exception:
        logger.warning("Redis unavailable, using in-memory fakeredis.")
        try:
            import fakeredis

            return fakeredis.FakeStrictRedis(decode_responses=True)
        except ImportError:
            return None


def cache_get(key: str) -> Optional[Any]:
    try:
        r = get_redis()
        value = r.get(key) if r else None
        return json.loads(value) if value else None
    except Exception:
        return None


def cache_set(key: str, value: Any, ttl: int) -> None:
    try:
        r = get_redis()
        if r:
            r.setex(key, ttl, json.dumps(value))
    except Exception:
        pass
