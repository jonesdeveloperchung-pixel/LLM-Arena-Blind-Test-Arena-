from typing import List, Optional
import logging

from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse

from models import OllamaModel, OllamaPullRequest, OllamaDeleteRequest
from dependencies import get_pipeline
from api import OllamaClient # The client for Ollama itself

router = APIRouter()
logger = logging.getLogger("BackendAPI")

@router.get("/ollama/health")
async def get_ollama_health():
    """
    Checks if the Ollama server is running and accessible.
    """
    pipeline = get_pipeline()
    is_healthy = pipeline.api.check_health()
    if is_healthy:
        return {"status": "healthy", "message": "Ollama server is running."}
    else:
        raise HTTPException(
            status_code=503,
            detail="Ollama service is not running or not accessible.",
        )

@router.get("/ollama/models", response_model=List[OllamaModel])
async def list_ollama_models():
    """
    Lists all installed Ollama models.
    """
    pipeline = get_pipeline()
    try:
        ollama_client = OllamaClient(base_url=pipeline.api.base_url)
        models_raw = ollama_client.get_ollama_models()
        # Convert raw models to OllamaModel Pydantic format
        models = []
        for m in models_raw:
            models.append(OllamaModel(
                name=m.get('name'),
                model=m.get('model'),
                size=m.get('size'),
                digest=m.get('digest'),
                modified_at=m.get('modified_at')
            ))
        return models
    except Exception as e:
        logger.error(f"Failed to list Ollama models: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to list Ollama models: {e}")

@router.post("/ollama/pull")
async def pull_ollama_model(request: OllamaPullRequest):
    """
    Pulls a new Ollama model.
    """
    pipeline = get_pipeline()
    try:
        ollama_client = OllamaClient(base_url=pipeline.api.base_url)
        success = ollama_client.pull_model(request.model_name)
        if success:
            return {"message": f"Model '{request.model_name}' pull initiated successfully."}
        else:
            raise HTTPException(status_code=500, detail=f"Failed to initiate pull for model '{request.model_name}'. Check Ollama server logs.")
    except Exception as e:
        logger.error(f"Failed to pull Ollama model '{request.model_name}': {e}")
        raise HTTPException(status_code=500, detail=f"Failed to pull Ollama model: {e}")

@router.post("/ollama/delete")
async def delete_ollama_model(request: OllamaDeleteRequest):
    """
    Deletes an Ollama model.
    """
    pipeline = get_pipeline()
    try:
        ollama_client = OllamaClient(base_url=pipeline.api.base_url)
        success = ollama_client.delete_model(request.model_name)
        if success:
            return {"message": f"Model '{request.model_name}' deleted successfully."}
        else:
            raise HTTPException(status_code=500, detail=f"Failed to delete model '{request.model_name}'. Check Ollama server logs.")
    except Exception as e:
        logger.error(f"Failed to delete Ollama model '{request.model_name}': {e}")
        raise HTTPException(status_code=500, detail=f"Failed to delete Ollama model: {e}")