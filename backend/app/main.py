from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from starlette.middleware.cors import CORSMiddleware

from app.api.v1.routes_health import router as health_router
from app.api.v1.routes_llm import router as llm_router
from app.middlewares.timeouts import timeout_middleware
from app.middlewares.errors import error_handler_middleware

import os
app = FastAPI(title="AI for Science API", version="0.1.0", root_path=os.getenv("API_ROOT_PATH", ""))

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.middleware("http")(timeout_middleware(timeout_ms=9000))
app.middleware("http")(error_handler_middleware)

app.include_router(health_router, prefix="/api/v1")
app.include_router(llm_router, prefix="/api/v1")

@app.get("/")
async def root():
    return {"status": "ok"}
