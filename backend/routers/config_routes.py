from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import JSONResponse
import yaml
import logging
from pathlib import Path # Import Path
from datetime import datetime # Import datetime
import shutil # Import shutil for file operations

from dependencies import get_config_path, reload_pipeline
from config_presets import PRESETS # Import PRESETS from config_presets.py

router = APIRouter()
logger = logging.getLogger("BackendAPI")

def _create_config_backup(config_path: Path):
    """Creates a timestamped backup of the current config file."""
    backup_dir = config_path.parent / "backups"
    backup_dir.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = backup_dir / f"jade_config_{timestamp}.yaml"
    shutil.copy(config_path, backup_path)
    logger.info(f"Configuration backup created: {backup_path}")
    return backup_path

def _restore_config_backup(backup_path: Path, current_config_path: Path):
    """Restores a config from a backup file."""
    if not backup_path.exists():
        raise FileNotFoundError(f"Backup file not found: {backup_path}")
    shutil.copy(backup_path, current_config_path)
    logger.info(f"Configuration restored from backup: {backup_path}")
    reload_pipeline() # Reload pipeline after restoring config

@router.get("/config")
async def get_config():
    """Retrieves the current application configuration."""
    config_path = get_config_path()
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = yaml.safe_load(f)
        return JSONResponse(content=config)
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="Configuration file not found.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to load configuration: {e}")

@router.post("/config")
async def update_config(request: Request):
    """Updates the application configuration."""
    config_path = get_config_path()
    try:
        # Create a backup before modifying
        if config_path.exists():
            _create_config_backup(config_path)

        new_config = await request.json()
        
        # Load existing config to merge
        current_config = {}
        if config_path.exists():
            with open(config_path, 'r', encoding='utf-8') as f:
                current_config = yaml.safe_load(f)
        
        def deep_merge(a, b):
            for key, value in b.items():
                if key in a and isinstance(a[key], dict) and isinstance(value, dict):
                    a[key] = deep_merge(a[key], value)
                else:
                    a[key] = value
            return a
        
        merged_config = deep_merge(current_config, new_config)

        with open(config_path, 'w', encoding='utf-8') as f:
            yaml.safe_dump(merged_config, f, allow_unicode=True, indent=2, sort_keys=False)
        
        reload_pipeline()
        logger.info("Configuration updated and pipeline reloaded.")

        return JSONResponse(content={"message": "Configuration updated successfully."})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update configuration: {e}")

@router.post("/config/backup")
async def create_config_backup_endpoint():
    """Creates a manual backup of the current configuration."""
    config_path = get_config_path()
    try:
        if not config_path.exists():
            raise HTTPException(status_code=404, detail="Current configuration file not found.")
        backup_path = _create_config_backup(config_path)
        return {"message": f"Configuration backup created successfully at {backup_path.name}"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create config backup: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to create config backup: {e}")

@router.post("/config/rollback")
async def rollback_config_endpoint(backup_filename: str):
    """Restores the configuration from a specified backup file."""
    config_path = get_config_path()
    backup_dir = config_path.parent / "backups"
    backup_file_path = backup_dir / backup_filename
    
    try:
        _restore_config_backup(backup_file_path, config_path)
        return {"message": f"Configuration restored from {backup_filename}."}
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=f"Backup file not found: {backup_filename}")
    except Exception as e:
        logger.error(f"Failed to rollback configuration: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to rollback configuration: {e}")

@router.get("/config/backups")
async def list_config_backups():
    """Lists all available configuration backup files."""
    config_path = get_config_path()
    backup_dir = config_path.parent / "backups"
    
    if not backup_dir.exists():
        return []
    
    backups = []
    for f in backup_dir.iterdir():
        if f.is_file() and f.suffix == ".yaml":
            backups.append(f.name)
    
    backups.sort(reverse=True) # Sort by name (which includes timestamp)
    return backups

@router.get("/config/presets")
async def list_config_presets():
    """Lists available configuration presets."""
    return PRESETS

