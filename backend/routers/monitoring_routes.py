from fastapi import APIRouter, HTTPException
import psutil
import logging
from typing import Dict

router = APIRouter()
logger = logging.getLogger("BackendAPI")

@router.get("/monitoring/resources", response_model=Dict[str, float])
async def get_system_resources():
    """
    Returns current system resource (CPU and RAM) usage.
    """
    try:
        cpu_percent = psutil.cpu_percent(interval=None)
        ram_percent = psutil.virtual_memory().percent
        
        return {
            "cpu_percent": cpu_percent,
            "ram_percent": ram_percent
        }
    except Exception as e:
        logger.error(f"Failed to retrieve system resources: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve system resources: {e}")