from fastapi import FastAPI, Request, HTTPException
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.encoders import jsonable_encoder
from app.core.config import settings
from app.api.system import api_router as system_router
from app.api.v1 import api_router as v1_router
# Admin Panel
from apps.admin.router import admin_router
from apps.admin.static_server import router as admin_static_router, get_static_files

app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(system_router, prefix='/system')
app.include_router(v1_router, prefix='/v1')
app.include_router(admin_router, prefix='/admin')
app.include_router(admin_static_router, prefix='/admin')

# Mount static files for admin panel
app.mount("/admin/static", get_static_files(), name="admin_static")


@app.get("/", include_in_schema=False)
async def root():
    return {"status": "OK", "message": "Dorna API is running. See /docs for OpenAPI UI."}


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    # sanitize exc.errors() -> stringifying ctx values (like ValueError)
    raw_errors = exc.errors()
    safe_errors = []
    for err in raw_errors:
        item = dict(err)
        if "ctx" in item and isinstance(item["ctx"], dict):
            item["ctx"] = {
                k: (str(v) if not isinstance(v, (str, int, float, bool, type(None))) else v)
                for k, v in item["ctx"].items()
            }
        safe_errors.append(item)

    payload = {
        "status": "ERROR",
        "message": "validation error",
        "detail": safe_errors,
    }
    return JSONResponse(status_code=422, content=jsonable_encoder(payload))


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    payload = {
        "status": "ERROR",
        "message": str(exc.detail) if isinstance(exc.detail, str) else "http error",
        "detail": jsonable_encoder(exc.detail),
    }
    return JSONResponse(status_code=exc.status_code, content=payload)


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    payload = {
        "status": "ERROR",
        "message": "internal server error",
        "detail": {
            "path": str(request.url.path),
            "error": str(exc),
        },
    }
    return JSONResponse(status_code=500, content=jsonable_encoder(payload))
