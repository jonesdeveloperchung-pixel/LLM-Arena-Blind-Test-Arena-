from fastapi import APIRouter, HTTPException
import logging

from dependencies import get_pipeline

router = APIRouter()
logger = logging.getLogger("BackendAPI")

@router.get("/app/version")
async def get_app_version():
    """
    Returns the current version of the backend application.
    """
    return {"version": "1.0.0", "build_date": "2025-12-06"}

