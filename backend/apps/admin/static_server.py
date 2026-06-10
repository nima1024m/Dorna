"""Static file serving for admin panel frontend."""
from fastapi import APIRouter
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pathlib import Path

router = APIRouter()

# Get the static files directory
STATIC_DIR = Path(__file__).parent / "static"


@router.get("/panel")
async def serve_admin_panel():
    """Serve the admin panel HTML."""
    return FileResponse(STATIC_DIR / "index.html")


def get_static_files():
    """Get StaticFiles instance for mounting."""
    return StaticFiles(directory=str(STATIC_DIR))
