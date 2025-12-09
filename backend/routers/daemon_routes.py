from fastapi import APIRouter, HTTPException
import logging

from dependencies import get_daemon

router = APIRouter()
logger = logging.getLogger("BackendAPI")

@router.post("/daemon/start")
async def start_daemon():
    daemon = get_daemon()
    if daemon.is_running():
        return {"message": "Daemon is already running.", "status": "running"}
    try:
        daemon.start()
        return {"message": "Daemon started successfully.", "status": "running"}
    except Exception as e:
        logger.error(f"Failed to start daemon: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to start daemon: {e}")

@router.post("/daemon/stop")
async def stop_daemon():
    daemon = get_daemon()
    if not daemon.is_running():
        return {"message": "Daemon is not running.", "status": "stopped"}
    try:
        daemon.stop()
        return {"message": "Daemon stopped successfully.", "status": "stopped"}
    except Exception as e:
        logger.error(f"Failed to stop daemon: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to stop daemon: {e}")

@router.get("/daemon/status")
async def get_daemon_status():
    daemon = get_daemon()
    status = "running" if daemon.is_running() else "stopped"
    return {"status": status}
