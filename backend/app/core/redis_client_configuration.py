import os
import logging
import redis
import fakeredis

logger = logging.getLogger(__name__)

REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))

try:
    redis_client = redis.Redis(
        host=REDIS_HOST, 
        port=REDIS_PORT, 
        db=0, 
        socket_connect_timeout=2
    )
    redis_client.ping()
    logger.info("Connected to standalone Redis server.")
except Exception:
    logger.warning("Redis server unavailable. Fallback to in-memory Fakeredis client.")
    redis_client = fakeredis.FakeStrictRedis()