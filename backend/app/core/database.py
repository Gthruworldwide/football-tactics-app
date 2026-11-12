"""Database module for Redis connection management."""

import redis
from typing import Generator

from app.core.config import settings


def get_redis() -> redis.Redis:
    """Get a Redis client instance."""
    r = redis.Redis(
        host=settings.REDIS_HOST,
        port=settings.REDIS_PORT,
        db=settings.REDIS_DB,
        decode_responses=True,
    )
    # Ping to check connection
    try:
        r.ping()
    except redis.ConnectionError:
        raise ConnectionError("Could not connect to Redis")
    return r


# Context manager for Redis connection
def get_redis_connection() -> Generator[redis.Redis, None, None]:
    """Yield a Redis connection, ensuring it's closed after use."""
    r = get_redis()
    try:
        yield r
    finally:
        try:
            r.close()
        except Exception:
            pass