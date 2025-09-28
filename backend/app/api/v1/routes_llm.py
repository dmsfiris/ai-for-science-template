from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

router = APIRouter(tags=["llm"])

class GenerateReq(BaseModel):
    prompt: str
    model: str | None = None
    temperature: float = 0.2

@router.post("/llm/generate")
async def generate(req: GenerateReq):
    # Demo behavior for step 1: reverse text and return pseudo token counts
    if not req.prompt or len(req.prompt.strip()) == 0:
        raise HTTPException(status_code=400, detail="prompt required")
    text = req.prompt[::-1]
    return {
        "text": text,
        "tokens_in": max(1, len(req.prompt)//4),
        "tokens_out": max(1, len(text)//4),
    }
