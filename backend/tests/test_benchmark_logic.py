import pytest
from unittest.mock import MagicMock, patch
import requests
import json
from datetime import datetime

# Adjust path to import benchmark.py
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

from benchmark import call_ollama, call_gemini_judge, run_benchmark, CATEGORIES

# Mock configuration for tests
MOCK_CONFIG = {
    'ollama': {
        'url': 'http://mock-ollama:11434',
        'enabled': True,
        'timeout_seconds': 5,
        'retry_attempts': 1,
        'retry_delay_seconds': 0.1
    },
    'gemini': {
        'api_key': 'mock_gemini_key',
        'enabled': True,
        'fallback_on_ollama_failure': False
    }
}

MOCK_CONFIG_NO_GEMINI = {
    'ollama': {
        'url': 'http://mock-ollama:11434',
        'enabled': True,
        'timeout_seconds': 5,
        'retry_attempts': 1,
        'retry_delay_seconds': 0.1
    },
    'gemini': {
        'api_key': '', # No API Key
        'enabled': False,
        'fallback_on_ollama_failure': False
    }
}

# --- Tests for call_ollama ---

def test_call_ollama_success():
    with patch('requests.post') as mock_post:
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"response": "Ollama response text"}
        mock_post.return_value = mock_response

        response_text = call_ollama("mock_model", "mock_prompt", MOCK_CONFIG)
        assert response_text == "Ollama response text"
        mock_post.assert_called_once()

def test_call_ollama_api_error():
    with patch('requests.post') as mock_post:
        mock_response = MagicMock()
        mock_response.status_code = 404
        mock_response.text = "Model not found"
        mock_post.return_value = mock_response

        response_text = call_ollama("mock_model", "mock_prompt", MOCK_CONFIG)
        assert "API 錯誤: 404 - Model not found" in response_text
        mock_post.assert_called_once()

def test_call_ollama_connection_error():
    with patch('requests.post') as mock_post:
        mock_post.side_effect = requests.exceptions.RequestException("Connection refused")
        response_text = call_ollama("mock_model", "mock_prompt", MOCK_CONFIG)
        assert "連接失敗: Connection refused" in response_text
        mock_post.assert_called_once() # Should still try once even with retries=0

def test_call_ollama_disabled():
    config_disabled = MOCK_CONFIG.copy()
    config_disabled['ollama']['enabled'] = False
    response_text = call_ollama("mock_model", "mock_prompt", config_disabled)
    assert "Ollama 未啟用" in response_text

# --- Tests for call_gemini_judge ---

@patch('google.generativeai.GenerativeModel')
@patch('google.generativeai.configure')
def test_call_gemini_judge_with_key_success(mock_configure, mock_model_class):
    mock_judge_instance = MagicMock()
    mock_judge_instance.generate_content.return_value.text = '{"score": 5, "reasoning": "Good"}'
    mock_model_class.return_value = mock_judge_instance

    result = call_gemini_judge("Model output", "reasoning", MOCK_CONFIG['gemini']['api_key'])
    assert result['score'] == 5
    assert "Good" in result['reasoning']
    mock_configure.assert_called_once_with(api_key=MOCK_CONFIG['gemini']['api_key'])
    mock_judge_instance.generate_content.assert_called_once()

def test_call_gemini_judge_no_key_simple_scoring_success():
    result = call_gemini_judge("This is a long model output, over 50 characters long.", "reasoning", MOCK_CONFIG_NO_GEMINI['gemini']['api_key'])
    assert result['score'] == 3
    assert "簡單評分" in result['reasoning']

def test_call_gemini_judge_no_key_simple_scoring_short():
    result = call_gemini_judge("Short output.", "reasoning", MOCK_CONFIG_NO_GEMINI['gemini']['api_key'])
    assert result['score'] == 2
    assert "簡單評分" in result['reasoning']

def test_call_gemini_judge_no_key_simple_scoring_fail_keywords():
    result = call_gemini_judge("模型回應失敗", "reasoning", MOCK_CONFIG_NO_GEMINI['gemini']['api_key'])
    assert result['score'] == 0
    assert "模型回應失敗" in result['reasoning']

@patch('google.generativeai.GenerativeModel')
@patch('google.generativeai.configure')
def test_call_gemini_judge_parsing_error(mock_configure, mock_model_class):
    mock_judge_instance = MagicMock()
    mock_judge_instance.generate_content.return_value.text = '{"score": "invalid", "reasoning": "Bad"}' # Invalid JSON
    mock_model_class.return_value = mock_judge_instance

    result = call_gemini_judge("Model output", "reasoning", MOCK_CONFIG['gemini']['api_key'])
    assert result['score'] == 3 # Default score on parsing failure
    assert "Bad" in result['reasoning']

@patch('google.generativeai.GenerativeModel')
@patch('google.generativeai.configure')
def test_call_gemini_judge_gemini_exception(mock_configure, mock_model_class):
    mock_judge_instance = MagicMock()
    mock_judge_instance.generate_content.side_effect = Exception("Gemini API error")
    mock_model_class.return_value = mock_judge_instance

    result = call_gemini_judge("Model output", "reasoning", MOCK_CONFIG['gemini']['api_key'])
    assert result['score'] == 0
    assert "評審失敗: Gemini API error" in result['reasoning']

# --- Tests for run_benchmark ---

@patch('benchmark.call_gemini_judge')
@patch('benchmark.call_ollama')
def test_run_benchmark_success(mock_call_ollama, mock_call_gemini_judge):
    mock_call_ollama.return_value = "Ollama test output for reasoning."
    mock_call_gemini_judge.return_value = {
        'score': 4, 
        'reasoning': "Mock Gemini reasoning", 
        'breakdown': {'accuracy': 4.5, 'step_clarity': 3.5}
    }

    model_name = "llama3.2:latest"
    category = "reasoning"
    
    result = run_benchmark(model_name, category, MOCK_CONFIG)

    assert result['model'] == model_name
    assert result['category'] == category
    assert result['output'] == "Ollama test output for reasoning."
    assert result['score'] == 4
    assert result['reasoning'] == "Mock Gemini reasoning"
    assert result['breakdown']['accuracy'] == 4.5
    assert 'timestamp' in result
    mock_call_ollama.assert_called_once_with(model_name, CATEGORIES[category]['prompt'], MOCK_CONFIG)
    mock_call_gemini_judge.assert_called_once_with("Ollama test output for reasoning.", category, MOCK_CONFIG['gemini']['api_key'])

@patch('benchmark.call_gemini_judge')
@patch('benchmark.call_ollama')
def test_run_benchmark_ollama_failure(mock_call_ollama, mock_call_gemini_judge):
    mock_call_ollama.return_value = "API 錯誤: 500 - Internal Server Error"
    mock_call_gemini_judge.return_value = {
        'score': 0, 
        'reasoning': "模型回應失敗", 
        'breakdown': {}
    } # call_gemini_judge should score 0 if ollama fails

    model_name = "llama3.2:latest"
    category = "coding"
    
    result = run_benchmark(model_name, category, MOCK_CONFIG)

    assert result['model'] == model_name
    assert result['category'] == category
    assert "API 錯誤: 500" in result['output']
    assert result['score'] == 0
    assert "模型回應失敗" in result['reasoning']
    mock_call_ollama.assert_called_once()
    mock_call_gemini_judge.assert_called_once()

@patch('benchmark.call_gemini_judge')
@patch('benchmark.call_ollama')
def test_run_benchmark_gemini_failure(mock_call_ollama, mock_call_gemini_judge):
    mock_call_ollama.return_value = "Ollama test output."
    mock_call_gemini_judge.return_value = {
        'score': 0, 
        'reasoning': "評審失敗", 
        'breakdown': {}
    }

    model_name = "llama3.2:latest"
    category = "vision"
    
    result = run_benchmark(model_name, category, MOCK_CONFIG)

    assert result['model'] == model_name
    assert result['category'] == category
    assert result['output'] == "Ollama test output."
    assert result['score'] == 0
    assert "評審失敗" in result['reasoning']
    mock_call_ollama.assert_called_once()
    mock_call_gemini_judge.assert_called_once()

# Test all categories
@patch('benchmark.call_gemini_judge')
@patch('benchmark.call_ollama')
def test_run_benchmark_all_categories(mock_call_ollama, mock_call_gemini_judge):
    mock_call_ollama.return_value = "Mock Ollama output."
    mock_call_gemini_judge.return_value = {'score': 3, 'reasoning': 'Mocked', 'breakdown': {}}

    model_name = "llama3.2:latest"
    for category_key in CATEGORIES.keys():
        result = run_benchmark(model_name, category_key, MOCK_CONFIG)
        assert result['category'] == category_key
        assert result['score'] == 3
        mock_call_ollama.assert_called_with(model_name, CATEGORIES[category_key]['prompt'], MOCK_CONFIG)
        mock_call_gemini_judge.assert_called_with("Mock Ollama output.", category_key, MOCK_CONFIG['gemini']['api_key'])
    # Check call counts for each category
    assert mock_call_ollama.call_count == len(CATEGORIES)
    assert mock_call_gemini_judge.call_count == len(CATEGORIES)
