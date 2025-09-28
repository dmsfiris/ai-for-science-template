import asyncio
from starlette.requests import Request
from starlette.responses import JSONResponse

def timeout_middleware(timeout_ms: int = 10000):
    async def _mw(request: Request, call_next):
        try:
            return await asyncio.wait_for(call_next(request), timeout=timeout_ms/1000.0)
        except asyncio.TimeoutError:
            return JSONResponse({"error": "timeout"}, status_code=504)
    return _mw
