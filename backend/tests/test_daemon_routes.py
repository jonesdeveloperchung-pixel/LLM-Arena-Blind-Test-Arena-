import pytest
from fastapi.testclient import TestClient
from unittest.mock import MagicMock, patch
from fastapi import FastAPI

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

from routers import daemon_routes # Import the module containing the router
import dependencies # Import the dependencies module to patch its components

# Fixture to provide a mock Daemon instance
@pytest.fixture
def mock_daemon_instance():
    return MagicMock(spec=dependencies.Daemon) # Use spec=dependencies.Daemon

# Fixture to patch global state and Daemon class for each test
@pytest.fixture
def client_with_global_mock(mock_daemon_instance):
    # Patch the Daemon class within the dependencies module
    with patch.object(dependencies, 'Daemon', return_value=mock_daemon_instance) as MockDaemonClass:
        # Patch the global _daemon_instance within the dependencies module
        # Note: If _daemon_instance is accessed before this patch, it might be the real one.
        # This setup assumes get_daemon is always called, and _daemon_instance might be set to None.
        with patch.object(dependencies, '_daemon_instance', new=mock_daemon_instance): # Patch the global _daemon_instance itself
            # Patch the get_daemon function within the dependencies module
            with patch.object(dependencies, 'get_daemon', return_value=mock_daemon_instance) as MockGetDaemon:
                app_with_global_mock = FastAPI()
                app_with_global_mock.include_router(daemon_routes.router)
                with TestClient(app_with_global_mock) as client:
                    yield client

# --- Tests for get_daemon_status ---
def test_get_daemon_status_running(client_with_global_mock, mock_daemon_instance):
    mock_daemon_instance.is_running.return_value = True
    response = client_with_global_mock.get("/daemon/status")
    assert response.status_code == 200
    assert response.json() == {"status": "running"}

def test_get_daemon_status_stopped(client_with_global_mock, mock_daemon_instance):
    mock_daemon_instance.is_running.return_value = False
    response = client_with_global_mock.get("/daemon/status")
    assert response.status_code == 200
    assert response.json() == {"status": "stopped"}

# --- Tests for start_daemon ---
def test_start_daemon_success(client_with_global_mock, mock_daemon_instance):
    mock_daemon_instance.is_running.return_value = False
    response = client_with_global_mock.post("/daemon/start")
    assert response.status_code == 200
    assert response.json() == {"message": "Daemon started successfully.", "status": "running"}
    mock_daemon_instance.start.assert_called_once()

def test_start_daemon_already_running(client_with_global_mock, mock_daemon_instance):
    mock_daemon_instance.is_running.return_value = True
    response = client_with_global_mock.post("/daemon/start")
    assert response.status_code == 200
    assert response.json() == {"message": "Daemon is already running.", "status": "running"}
    mock_daemon_instance.start.assert_not_called()

def test_start_daemon_exception(client_with_global_mock, mock_daemon_instance):
    mock_daemon_instance.is_running.return_value = False
    mock_daemon_instance.start.side_effect = Exception("Daemon init error")
    response = client_with_global_mock.post("/daemon/start")
    assert response.status_code == 500
    assert "Daemon init error" in response.json()['detail']
    mock_daemon_instance.start.assert_called_once()

# --- Tests for stop_daemon ---
def test_stop_daemon_success(client_with_global_mock, mock_daemon_instance):
    mock_daemon_instance.is_running.return_value = True
    response = client_with_global_mock.post("/daemon/stop")
    assert response.status_code == 200
    assert response.json() == {"message": "Daemon stopped successfully.", "status": "stopped"}
    mock_daemon_instance.stop.assert_called_once()

def test_stop_daemon_not_running(client_with_global_mock, mock_daemon_instance):
    mock_daemon_instance.is_running.return_value = False
    response = client_with_global_mock.post("/daemon/stop")
    assert response.status_code == 200
    assert response.json() == {"message": "Daemon is not running.", "status": "stopped"}
    mock_daemon_instance.stop.assert_not_called()

def test_stop_daemon_exception(client_with_global_mock, mock_daemon_instance):
    mock_daemon_instance.is_running.return_value = True
    mock_daemon_instance.stop.side_effect = Exception("Daemon stop error")
    response = client_with_global_mock.post("/daemon/stop")
    assert response.status_code == 500
    assert "Daemon stop error" in response.json()['detail']
    mock_daemon_instance.stop.assert_called_once()