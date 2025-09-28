from starlette.requests import Request
from starlette.responses import JSONResponse

async def error_handler_middleware(request: Request, call_next):
    try:
        response = await call_next(request)
        return response
    except Exception as e:
        # Normalize to JSON error; in prod you'd map exception types explicitly
        return JSONResponse({"error": "internal_error", "detail": str(e)}, status_code=500)
