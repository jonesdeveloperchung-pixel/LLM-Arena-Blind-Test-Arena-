import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import logging
from logging import StreamHandler
import sys
from pathlib import Path

# Add backend directory to sys.path
sys.path.append(str(Path(__file__).parent))

from dependencies import get_pipeline
from routers import (
    pipeline_routes,
    benchmark_routes,
    telemetry_routes,
    config_routes,
    system_routes,
    daemon_routes,
    ollama_routes,
    monitoring_routes,
    alert_routes,
)

# --- Initialize FastAPI app ---
app = FastAPI()

# --- Configure CORS (optional, but often needed) ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # adjust for security
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Setup logging ---
logger = logging.getLogger("uvicorn")
logger.addHandler(StreamHandler(sys.stdout))
logger.setLevel(logging.INFO)

# --- Include Routers ---
app.include_router(pipeline_routes.router)
app.include_router(benchmark_routes.router)
app.include_router(telemetry_routes.router)
app.include_router(config_routes.router)
app.include_router(system_routes.router)
app.include_router(daemon_routes.router)
app.include_router(ollama_routes.router)
app.include_router(monitoring_routes.router)
app.include_router(alert_routes.router)

# --- Startup Event ---
@app.on_event("startup")
async def startup_event():
    logger.info("FastAPI application started.")
    get_pipeline()
    logger.info("ImagePipeline instance initialized.")

# --- Main entry point ---
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)