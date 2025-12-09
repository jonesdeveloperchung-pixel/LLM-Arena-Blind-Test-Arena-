import pytest
from fastapi.testclient import TestClient
from unittest.mock import MagicMock, patch
from fastapi import FastAPI

# Adjust path to import routers
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

from routers.monitoring_routes import router

# Create a dummy FastAPI app to include the router
test_app = FastAPI()
test_app.include_router(router)

# Create a TestClient for the dummy app
client = TestClient(test_app)

# Fixture to mock psutil functions
@pytest.fixture
def mock_psutil():
    with patch('routers.monitoring_routes.psutil') as mock_psutil_module:
        yield mock_psutil_module

# --- Tests for get_system_resources ---
def test_get_system_resources_success(mock_psutil):
    mock_psutil.cpu_percent.return_value = 25.5
    mock_psutil.virtual_memory.return_value = MagicMock(percent=50.2)
    
    response = client.get("/monitoring/resources")
    assert response.status_code == 200
    assert response.json() == {"cpu_percent": 25.5, "ram_percent": 50.2}
    mock_psutil.cpu_percent.assert_called_once_with(interval=None)
    mock_psutil.virtual_memory.assert_called_once()

def test_get_system_resources_zero_usage(mock_psutil):
    mock_psutil.cpu_percent.return_value = 0.0
    mock_psutil.virtual_memory.return_value = MagicMock(percent=0.0)
    
    response = client.get("/monitoring/resources")
    assert response.status_code == 200
    assert response.json() == {"cpu_percent": 0.0, "ram_percent": 0.0}

def test_get_system_resources_high_usage(mock_psutil):
    mock_psutil.cpu_percent.return_value = 99.9
    mock_psutil.virtual_memory.return_value = MagicMock(percent=95.0)
    
    response = client.get("/monitoring/resources")
    assert response.status_code == 200
    assert response.json() == {"cpu_percent": 99.9, "ram_percent": 95.0}

def test_get_system_resources_exception(mock_psutil):
    mock_psutil.cpu_percent.side_effect = Exception("CPU error")
    
    response = client.get("/monitoring/resources")
    assert response.status_code == 500
    assert "CPU error" in response.json()['detail']
