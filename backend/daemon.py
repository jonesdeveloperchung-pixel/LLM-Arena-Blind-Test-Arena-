import time
import logging
from pathlib import Path
import sys
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import threading
import yaml

# Add parent directory to path to allow imports if run from backend/
sys.path.append(str(Path(__file__).parent))

from pipeline import ImagePipeline

# Setup Logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("logs/daemon.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("OllamaDaemon")

class PipelineEventHandler(FileSystemEventHandler):
    def __init__(self, pipeline: ImagePipeline):
        self.pipeline = pipeline
        self.config = pipeline.config
        self.lock = threading.Lock() # To prevent multiple threads processing same file

    def on_created(self, event):
        if not event.is_directory:
            file_path = Path(event.src_path)
            # Check if file has a supported extension
            allowed_exts = set(self.config['security']['allowed_extensions'])
            if file_path.suffix.lower() in allowed_exts:
                logger.info(f"Detected new file: {file_path}")
                # Use a lock to prevent race conditions if multiple files are created quickly
                with self.lock:
                    self.pipeline.process_image(file_path)
            else:
                logger.info(f"Ignored file (unsupported extension): {file_path}")

class Daemon:
    def __init__(self, config_path: str = None):
        self.pipeline = ImagePipeline(config_path=config_path)
        self.observer = Observer()
        self.event_handler = PipelineEventHandler(self.pipeline)
        self.watch_path = self.pipeline.input_dir
        self._running = False

    def start(self):
        if self._running:
            logger.info("Daemon is already running.")
            return

        logger.info(f"Starting daemon, watching directory: {self.watch_path}")
        self.observer.schedule(self.event_handler, self.watch_path, recursive=False)
        self.observer.start()
        self._running = True
        logger.info("Daemon started successfully.")

    def stop(self):
        if not self._running:
            logger.info("Daemon is not running.")
            return

        logger.info("Stopping daemon...")
        self.observer.stop()
        self.observer.join()
        self._running = False
        logger.info("Daemon stopped.")

    def is_running(self) -> bool:
        return self._running

if __name__ == "__main__":
    # Example usage:
    # This will run as a standalone daemon in the background.
    # For FastAPI integration, the daemon instance will be managed by the API server.
    daemon = Daemon()
    daemon.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        daemon.stop()