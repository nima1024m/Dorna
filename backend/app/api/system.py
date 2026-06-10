from fastapi import APIRouter
from fastapi.responses import JSONResponse
from app.services.system import SystemService

api_router = APIRouter()


@api_router.get("/api-health", tags=["system"])
async def api_health():
    return {"status": "OK"}


@api_router.get("/ai-health", tags=["system"])
async def ai_health():
    res = await SystemService.ai_health()
    if res:
        return {"status": "OK"}
    else:
        return JSONResponse(
            status_code=503,
            content={"status": "ERROR"}
        )
