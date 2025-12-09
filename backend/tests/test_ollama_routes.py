import pytest
from fastapi.testclient import TestClient
from unittest.mock import MagicMock, patch
from fastapi import FastAPI # Import FastAPI

# Adjust path to import routers and dependencies
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

from routers.ollama_routes import router # Import the router to be tested
from dependencies import get_pipeline
from api import OllamaClient # Import the actual OllamaClient
from pydantic import ConfigDict # For Pydantic warnings
from models import OllamaPullRequest, OllamaDeleteRequest, BlindTestResult # To modify these models

# Create a dummy FastAPI app to include the router for testing
test_app = FastAPI()
test_app.include_router(router)

# Create a TestClient for the dummy app
client = TestClient(test_app)

# Fixture to mock the get_pipeline dependency
@pytest.fixture
def mock_pipeline():
    with patch('dependencies.get_pipeline') as mock_get_pipeline:
        mock_pipeline_instance = MagicMock()
        # Ensure that mock_pipeline_instance.api is a mock of OllamaClient
        mock_pipeline_instance.api = MagicMock(spec=OllamaClient)
        mock_get_pipeline.return_value = mock_pipeline_instance
        yield mock_pipeline_instance

# --- Tests for get_ollama_health ---

# Instead of mocking pipeline.api.check_health, we can patch OllamaClient.check_health
# directly which is called by the actual API route function.
@patch('api.OllamaClient.check_health')
def test_get_ollama_health_healthy(mock_check_health, mock_pipeline):
    """Test when Ollama is healthy."""
    mock_check_health.return_value = True
    response = client.get("/ollama/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy", "message": "Ollama server is running."}

@patch('api.OllamaClient.check_health')
def test_get_ollama_health_unhealthy(mock_check_health, mock_pipeline):
    """Test when Ollama is unhealthy."""
    mock_check_health.return_value = False
    response = client.get("/ollama/health")
    assert response.status_code == 503
    assert response.json() == {"detail": "Ollama service is not running or not accessible."}

# --- Tests for list_ollama_models ---

# Mock the OllamaClient that ollama_routes.py will import and instantiate
@patch('routers.ollama_routes.OllamaClient')
def test_list_ollama_models_success(mock_ollama_client_class, mock_pipeline):
    """Test successful retrieval of Ollama models."""
    mock_pipeline.api.base_url = "http://mock-ollama:11434" # Set base_url for OllamaClient init
    
    mock_ollama_client_instance = MagicMock(spec=OllamaClient)
    mock_ollama_client_instance.get_ollama_models.return_value = [
        {"name": "model1", "model": "model1:latest", "size": 1000, "digest": "abc", "modified_at": "now"},
        {"name": "model2", "model": "model2:latest", "size": 2000, "digest": "def", "modified_at": "then"}
    ]
    mock_ollama_client_class.return_value = mock_ollama_client_instance # When OllamaClient() is called, return our mock instance

    response = client.get("/ollama/models")
    assert response.status_code == 200
    assert response.json() == [
        {"name": "model1", "model": "model1:latest", "size": 1000, "digest": "abc", "modified_at": "now"},
        {"name": "model2", "model": "model2:latest", "size": 2000, "digest": "def", "modified_at": "then"}
    ]

@patch('routers.ollama_routes.OllamaClient')
def test_list_ollama_models_empty(mock_ollama_client_class, mock_pipeline):
    """Test retrieval when no Ollama models are found."""
    mock_pipeline.api.base_url = "http://mock-ollama:11434"
    mock_ollama_client_instance = MagicMock(spec=OllamaClient)
    mock_ollama_client_instance.get_ollama_models.return_value = []
    mock_ollama_client_class.return_value = mock_ollama_client_instance

    response = client.get("/ollama/models")
    assert response.status_code == 200
    assert response.json() == []

@patch('routers.ollama_routes.OllamaClient')
def test_list_ollama_models_exception(mock_ollama_client_class, mock_pipeline):
    """Test error handling during Ollama model listing."""
    mock_pipeline.api.base_url = "http://mock-ollama:11434"
    mock_ollama_client_instance = MagicMock(spec=OllamaClient)
    mock_ollama_client_instance.get_ollama_models.side_effect = Exception("Ollama list error")
    mock_ollama_client_class.return_value = mock_ollama_client_instance

    response = client.get("/ollama/models")
    assert response.status_code == 500
    assert "Ollama list error" in response.json()['detail']

# --- Tests for pull_ollama_model ---

def test_pull_ollama_model_not_implemented():
    """Test that pull model endpoint returns 501 Not Implemented."""
    response = client.post("/ollama/pull", json={"model_name": "new_model"})
    assert response.status_code == 501
    assert response.json() == {"detail": "Not Implemented: Ollama model pull functionality."}

# --- Tests for delete_ollama_model ---

def test_delete_ollama_model_not_implemented():
    """Test that delete model endpoint returns 501 Not Implemented."""
    response = client.post("/ollama/delete", json={"model_name": "old_model"})
    assert response.status_code == 501
    assert response.json() == {"detail": "Not Implemented: Ollama model delete functionality."}