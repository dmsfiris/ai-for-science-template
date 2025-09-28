import os
import redis.asyncio as redis

REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379/0")
_client: redis.Redis | None = None

def get_client() -> redis.Redis:
    global _client
    if _client is None:
        _client = redis.from_url(REDIS_URL, decode_responses=True)
    return _client

async def ping_redis() -> bool:
    try:
        pong = await get_client().ping()
        return bool(pong)
    except Exception:
        return False
