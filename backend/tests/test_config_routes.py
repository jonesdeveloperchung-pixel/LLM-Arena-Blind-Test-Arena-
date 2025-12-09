import pytest
from fastapi.testclient import TestClient
from unittest.mock import MagicMock, patch, mock_open
from fastapi import FastAPI, HTTPException
import yaml

# Adjust path to import routers and dependencies
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

from routers.config_routes import router, _create_config_backup, _restore_config_backup
from dependencies import reload_pipeline, get_config_path
import config_presets # For PRESETS

# Create a dummy FastAPI app to include the router
test_app = FastAPI()
test_app.include_router(router)

# Create a TestClient for the dummy app
client = TestClient(test_app)

# Fixture for a mock config file path
@pytest.fixture
def mock_config_path():
    with patch('routers.config_routes.get_config_path') as mock_get_config_path:
        mock_path_instance = MagicMock(spec=Path)
        mock_path_instance.parent = MagicMock(spec=Path)
        mock_path_instance.parent.exists.return_value = True
        mock_path_instance.parent.mkdir.return_value = None
        mock_path_instance.exists.return_value = True # Assume config file exists by default
        mock_get_config_path.return_value = mock_path_instance
        yield mock_path_instance

# Fixture to mock Path object methods for backups
@pytest.fixture
def mock_path_methods(mock_config_path):
    # Mock for backup_dir.iterdir()
    mock_config_path.parent.iterdir.return_value = []
    # Mock for Path.exists() for backup_file_path
    mock_config_path.exists.return_value = True # For initial config
    # Mock the Path.exists() when checking backup files
    type(mock_config_path.parent).__call__ = MagicMock(side_effect=lambda *args, **kwargs: MagicMock(spec=Path, exists=True, name=args[0].name if args else "mock_file.yaml"))
    yield

# Mock the reload_pipeline dependency
@pytest.fixture(autouse=True)
def mock_reload_pipeline():
    with patch('routers.config_routes.reload_pipeline') as mock_reload:
        yield mock_reload

# --- Tests for /config (GET) ---
def test_get_config_success(mock_config_path):
    mock_config_path.read_text.return_value = yaml.dump({'test': 'config'})
    with patch('builtins.open', mock_open(read_data=yaml.dump({'test': 'config'}))):
        response = client.get("/config")
        assert response.status_code == 200
        assert response.json() == {"test": "config"}

def test_get_config_not_found(mock_config_path):
    mock_config_path.exists.return_value = False
    with patch('builtins.open', side_effect=FileNotFoundError):
        response = client.get("/config")
        assert response.status_code == 404
        assert "Configuration file not found." in response.json()['detail']

def test_get_config_exception(mock_config_path):
    mock_config_path.exists.return_value = True
    with patch('builtins.open', side_effect=Exception("Read error")):
        response = client.get("/config")
        assert response.status_code == 500
        assert "Read error" in response.json()['detail']

# --- Tests for /config (POST) ---
def test_update_config_success(mock_config_path, mock_reload_pipeline):
    mock_config_path.exists.return_value = True # Original config exists
    mock_config_path.read_text.return_value = yaml.dump({'old': 'value', 'nested': {'a': 1}})
    
    written_data = [] # Use a list to store all written chunks
    mock_file_handle = MagicMock()
    mock_file_handle.write.side_effect = lambda content: written_data.append(content)

    with patch('builtins.open', return_value=mock_file_handle, create=True):
        with patch('routers.config_routes._create_config_backup') as mock_backup:
            response = client.post("/config", json={'new': 'value', 'nested': {'b': 2}})
            assert response.status_code == 200
            assert response.json() == {"message": "Configuration updated successfully."}
            mock_backup.assert_called_once_with(mock_config_path)
            mock_reload_pipeline.assert_called_once()
            # Verify merged content
            loaded_written_config = yaml.safe_load("".join(written_data)) # Join chunks for full content
            assert loaded_written_config['new'] == 'value'
            assert loaded_written_config['nested']['b'] == 2

def test_update_config_no_original_config(mock_config_path, mock_reload_pipeline):
    mock_config_path.exists.return_value = False # Original config does not exist
    with patch('builtins.open', mock_open()) as mocked_open:
        with patch('routers.config_routes._create_config_backup') as mock_backup:
            response = client.post("/config", json={'new': 'value'})
            assert response.status_code == 200
            mock_backup.assert_not_called() # No backup if original file doesn't exist
            mock_reload_pipeline.assert_called_once()

# --- Tests for /config/backup (POST) ---
def test_create_config_backup_endpoint_success(mock_config_path):
    with patch('routers.config_routes._create_config_backup') as mock_create_backup:
        mock_create_backup.return_value = MagicMock(name="jade_config_20231201_100000.yaml")
        response = client.post("/config/backup")
        assert response.status_code == 200
        assert "Configuration backup created successfully" in response.json()['message']
        mock_create_backup.assert_called_once_with(mock_config_path)

def test_create_config_backup_endpoint_config_not_found(mock_config_path):
    mock_config_path.exists.return_value = False
    response = client.post("/config/backup")
    assert response.status_code == 404
    assert "Current configuration file not found." in response.json()['detail']

def test_create_config_backup_endpoint_exception(mock_config_path):
    with patch('routers.config_routes._create_config_backup', side_effect=Exception("Backup error")):
        response = client.post("/config/backup")
        assert response.status_code == 500
        assert "Backup error" in response.json()['detail']

# --- Tests for /config/rollback (POST) ---
def test_rollback_config_endpoint_success(mock_config_path, mock_reload_pipeline):
    mock_config_path.parent.__truediv__.return_value.exists.return_value = True # Backup dir exists
    mock_config_path.parent.__truediv__.return_value.iterdir.return_value = [MagicMock(name="jade_config_20231201_100000.yaml", is_file=lambda: True, suffix=".yaml")]
    
    with patch('routers.config_routes._restore_config_backup') as mock_restore:
        response = client.post("/config/rollback", json={"backup_filename": "jade_config_20231201_100000.yaml"})
        assert response.status_code == 200
        assert "Configuration restored from jade_config_20231201_100000.yaml." in response.json()['message']
        mock_restore.assert_called_once()
        mock_reload_pipeline.assert_called_once()

def test_rollback_config_endpoint_backup_not_found(mock_config_path):
    mock_config_path.parent.__truediv__.return_value = MagicMock(spec=Path, exists=True)
    mock_config_path.parent.__truediv__.return_value.__truediv__.return_value.exists.return_value = False # Specific backup file not found
    with patch('routers.config_routes._restore_config_backup', side_effect=FileNotFoundError):
        response = client.post("/config/rollback", json={"backup_filename": "non_existent.yaml"})
        assert response.status_code == 404
        assert "Backup file not found: non_existent.yaml" in response.json()['detail']

# --- Tests for /config/backups (GET) ---
def test_list_config_backups_success(mock_config_path, mock_path_methods):
    mock_config_path.parent.__truediv__.return_value.exists.return_value = True # Backup dir exists
    mock_config_path.parent.__truediv__.return_value.iterdir.return_value = [
        MagicMock(name="jade_config_20231202_100000.yaml", is_file=lambda: True, suffix=".yaml"),
        MagicMock(name="jade_config_20231201_100000.yaml", is_file=lambda: True, suffix=".yaml"),
        MagicMock(name="non_yaml_file.txt", is_file=lambda: True, suffix=".txt")
    ]
    response = client.get("/config/backups")
    assert response.status_code == 200
    assert response.json() == ["jade_config_20231202_100000.yaml", "jade_config_20231201_100000.yaml"]

def test_list_config_backups_no_backups(mock_config_path, mock_path_methods):
    mock_config_path.parent.__truediv__.return_value.exists.return_value = True # Backup dir exists
    mock_config_path.parent.__truediv__.return_value.iterdir.return_value = [] # Empty dir
    response = client.get("/config/backups")
    assert response.status_code == 200
    assert response.json() == []

def test_list_config_backups_dir_not_found(mock_config_path, mock_path_methods):
    mock_config_path.parent.__truediv__.return_value.exists.return_value = False # Backup dir does not exist
    response = client.get("/config/backups")
    assert response.status_code == 200
    assert response.json() == []

# --- Tests for /config/presets (GET) ---
def test_list_config_presets_success():
    response = client.get("/config/presets")
    assert response.status_code == 200
    assert response.json() == config_presets.PRESETS