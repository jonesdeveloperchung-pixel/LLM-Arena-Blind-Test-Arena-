import sys
from pathlib import Path
from typing import Optional
import logging

# Add backend directory to sys.path to ensure imports work
sys.path.append(str(Path(__file__).parent))

from pipeline import ImagePipeline
from daemon import Daemon

logger = logging.getLogger("BackendAPI")

_pipeline_instance: Optional[ImagePipeline] = None
_daemon_instance: Optional[Daemon] = None

def get_pipeline() -> ImagePipeline:
    global _pipeline_instance
    if _pipeline_instance is None:
        _pipeline_instance = ImagePipeline()
    return _pipeline_instance

def reload_pipeline():
    global _pipeline_instance
    _pipeline_instance = ImagePipeline()
    logger.info("ImagePipeline instance reloaded.")

def get_daemon() -> Daemon:
    global _daemon_instance
    if _daemon_instance is None:
        _daemon_instance = Daemon()
    return _daemon_instance

def get_config_path() -> Path:
    return Path(__file__).parent / "config" / "jade_config.yaml"
