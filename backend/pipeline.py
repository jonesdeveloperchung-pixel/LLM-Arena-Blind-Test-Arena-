import os
import sys
import time
import logging
import shutil
import json
import uuid
import sqlite3
from datetime import datetime
from pathlib import Path
import yaml
from typing import List, Dict, Optional

# Add parent directory to path to allow imports if run from backend/
sys.path.append(str(Path(__file__).parent))

from api import OllamaClient

# Setup Logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("logs/pipeline.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("OllamaPipeline")

class ImagePipeline:
    def __init__(self, config_path: str = None):
        if config_path is None:
            config_path = str(Path(__file__).parent / "config" / "jade_config.yaml")
        
        self.config = self._load_config(config_path)
        self.db_path = str(Path(__file__).parent / Path(self.config['database']['path']))
        self.input_dir = Path(__file__).parent / self.config['paths']['input']
        self.output_dir = Path(__file__).parent / self.config['paths']['output']
        self.failed_dir = Path(__file__).parent / self.config['paths']['failed']
        
        # Ensure directories exist
        self.input_dir.mkdir(parents=True, exist_ok=True)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.failed_dir.mkdir(parents=True, exist_ok=True)

        # Initialize API Client with enhanced configuration
        ollama_conf = self.config.get('ollama', {})
        gemini_conf = self.config.get('gemini', {})
        
        self.api = OllamaClient(
            base_url=ollama_conf.get('url', "http://localhost:11434"),
            model=ollama_conf.get('model', "llama3.2-vision"),
            timeout=ollama_conf.get('timeout_seconds', 60),
            retries=ollama_conf.get('retry_attempts', 3),
            retry_delay=ollama_conf.get('retry_delay_seconds', 1.0),
            use_gemini_fallback=gemini_conf.get('fallback_on_ollama_failure', False),
            gemini_api_key=gemini_conf.get('api_key', "")
        )

    def _load_config(self, path: str) -> Dict:
        try:
            with open(path, 'r', encoding='utf-8') as f:
                return yaml.safe_load(f)
        except Exception as e:
            logger.error(f"Failed to load config: {e}")
            sys.exit(1)

    def _get_db_connection(self) -> sqlite3.Connection:
        return sqlite3.connect(self.db_path)

    def _record_processing_start(self, item_id: str, filename: str, filepath: str):
        try:
            with self._get_db_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    INSERT INTO pipeline_items (id, filename, filepath, status, source, created_at)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (item_id, filename, filepath, 'processing', 'Ollama', datetime.now()))
                conn.commit()
        except Exception as e:
            logger.error(f"DB Insert Error: {e}")

    def _update_processing_status(self, item_id: str, status: str, 
                                  description: Optional[str] = None, 
                                  metadata: Optional[Dict] = None,
                                  error: Optional[str] = None):
        try:
            with self._get_db_connection() as conn:
                cursor = conn.cursor()
                
                update_fields = ["status = ?"]
                params = [status]
                
                if description:
                    update_fields.append("description = ?")
                    params.append(description)
                if metadata:
                    update_fields.append("metadata_json = ?")
                    params.append(json.dumps(metadata, ensure_ascii=False))
                if error:
                    update_fields.append("error_message = ?")
                    params.append(error)
                
                params.append(item_id)
                
                sql = f"UPDATE pipeline_items SET {', '.join(update_fields)} WHERE id = ?"
                cursor.execute(sql, params)
                conn.commit()
        except Exception as e:
            logger.error(f"DB Update Error: {e}")

    def _record_benchmark_result(self, run_id: str, category: str, model: str, score: float, breakdown_json: str, reasoning: str, run_timestamp: str):
        try:
            with self._get_db_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    INSERT INTO benchmark_results (id, category, model, score, breakdown_json, reasoning, run_timestamp)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """, (run_id, category, model, score, breakdown_json, reasoning, run_timestamp))
                conn.commit()
        except Exception as e:
            logger.error(f"DB Insert Error for benchmark result: {e}")

    def scan_input(self) -> List[Path]:
        """Scans input directory for supported images."""
        allowed_exts = set(self.config['security']['allowed_extensions'])
        files = []
        for file in self.input_dir.iterdir():
            if file.is_file() and file.suffix.lower() in allowed_exts:
                files.append(file)
        logger.info(f"Found {len(files)} images in input directory.")
        return files

    def run(self):
        """Main execution loop for a single run."""
        logger.info("Starting Pipeline Run...")

        if not self.api.check_health():
            logger.error(f"Ollama server is not healthy at {self.api.base_url}. Please ensure Ollama is running and accessible.")
            return

        images = self.scan_input()
        
        if not images:
            logger.info("No images found to process.")
            return

        for image_path in images:
            self.process_image(image_path)
            
        logger.info("Pipeline Run Complete.")

    def process_image(self, image_path: Path):
        """Process a single image."""
        item_id = str(uuid.uuid4())
        filename = image_path.name
        logger.info(f"Processing: {filename} (ID: {item_id})")
        
        # 1. Record Start
        self._record_processing_start(item_id, filename, str(image_path))
        
        try:
            # 2. Call API
            start_time = time.time()
            result = self.api.generate_description(str(image_path))
            processing_time = int((time.time() - start_time) * 1000)
            
            if not result:
                raise Exception("API returned no result")

            description = result.get('description', '')
            confidence = result.get('confidence', 0.0)
            
            # 3. Prepare Output Directory
            # Create a folder for this item in output/
            item_output_dir = self.output_dir / image_path.stem
            item_output_dir.mkdir(parents=True, exist_ok=True)
            
            # 4. Move Image
            dest_path = item_output_dir / filename
            shutil.move(str(image_path), str(dest_path))
            
            # 5. Generate Artifacts
            # Metadata
            metadata = {
                "id": item_id,
                "original_filename": filename,
                "timestamp": datetime.now().isoformat(),
                "processing_time_ms": processing_time,
                "model": self.api.model,
                "confidence": confidence
            }
            with open(item_output_dir / "metadata.json", 'w', encoding='utf-8') as f:
                json.dump(metadata, f, ensure_ascii=False, indent=2)
            
            # Markdown Description
            with open(item_output_dir / "description.zh-TW.md", 'w', encoding='utf-8') as f:
                f.write(f"# Image Description\n\n{description}\n")

            # 6. Update DB Success
            self._update_processing_status(
                item_id, 
                status='pending', # Needs manual approval
                description=description, 
                metadata=metadata
            )
            logger.info(f"Successfully processed {filename}")

        except Exception as e:
            logger.error(f"Failed to process {filename}: {e}")
            # Move to failed folder
            try:
                shutil.move(str(image_path), str(self.failed_dir / filename))
            except:
                pass # If move fails, leave it or log it
            
            self._update_processing_status(item_id, status='failed', error=str(e))

if __name__ == "__main__":
    pipeline = ImagePipeline()
    pipeline.run()