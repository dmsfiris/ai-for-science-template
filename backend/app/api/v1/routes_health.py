from fastapi import APIRouter
from app.services.cache import ping_redis

router = APIRouter(tags=["health"])

@router.get("/healthz")
async def healthz():
    # Light checks; don't block startup if Redis is down
    redis_ok = await ping_redis()
    return {"ok": True, "redis": redis_ok}
