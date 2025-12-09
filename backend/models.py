from datetime import datetime
from typing import List, Dict, Optional
from pydantic import BaseModel, ConfigDict

# --- Pydantic Models for Ollama Models ---
class OllamaModel(BaseModel):
    name: str
    model: str
    size: Optional[int] = None
    digest: Optional[str] = None
    modified_at: Optional[str] = None
    
class OllamaPullRequest(BaseModel):
    model_config = ConfigDict(protected_namespaces=())
    model_name: str

class OllamaDeleteRequest(BaseModel):
    model_config = ConfigDict(protected_namespaces=())
    model_name: str

# --- Pydantic Models for Pipeline Items ---
class PipelineItem(BaseModel):
    id: str
    filename: str
    filepath: str
    status: str
    source: Optional[str] = None
    created_at: str
    updated_at: str
    processing_time_ms: Optional[int] = None
    confidence_score: Optional[float] = None
    description: Optional[str] = None
    metadata_json: Optional[str] = None
    detection_raw_json: Optional[str] = None
    error_message: Optional[str] = None

class PipelineItemUpdateRequest(BaseModel):
    description: Optional[str] = None
    status: Optional[str] = None

class PipelineTriggerResponse(BaseModel):
    message: str
    status: str

class BenchmarkRunRequest(BaseModel):
    category: str
    model: str = "Llama 3.2"
    language: Optional[str] = None # New language field

class BenchmarkRunResponse(BaseModel):
    category: str
    model: str
    score: float
    breakdown: Dict[str, float]
    reasoning: str
    run_timestamp: str
    message: str = "Benchmark simulated successfully."

class BenchmarkPrompt(BaseModel):
    name: str # e.g., "reasoning_beginner"
    category: str # e.g., "reasoning"
    language: str # e.g., "en", "zh_TW"
    text: str

class ScoringStandard(BaseModel):
    name: str # e.g., "reasoning_standard_v1"
    category: str # e.g., "reasoning"
    language: str # e.g., "en", "zh_TW"
    judge_prompt_template: str # Template for the judge prompt (for Gemini)
    ollama_judge_prompt_template: Optional[str] = None # Template for the judge prompt (for Ollama)
    metrics: List[str] # List of metrics (e.g., "accuracy", "step_clarity")

class CompareRequest(BaseModel):
    model1: str
    model2: str
    image_path: Optional[str] = None
    prompt: Optional[str] = None
    language: Optional[str] = None # New language field

class CompareResponse(BaseModel):
    model1_response: Dict
    model2_response: Dict
    message: str = "Comparison results."

class TelemetryEvent(BaseModel):
    timestamp: datetime
    program: str
    version: str
    command: Optional[str] = None
    module: Optional[str] = None
    action: str
    args: Optional[str] = None
    user: str
    host: str
    os: str
    runtime: str
    execution_duration_ms: Optional[int] = None
    execution_exit_code: Optional[int] = None
    execution_error: Optional[str] = None
    context_cwd: Optional[str] = None
    context_details: Optional[str] = None
    tags: Optional[str] = None

class Alert(BaseModel):
    id: str # Changed from int to str to match UUID
    timestamp: datetime
    source: str
    message: str
    severity: str
    details: Optional[Dict] = None
    status: str
    dismissed_at: Optional[datetime] = None
    resolved_at: Optional[datetime] = None

class BlindTestResult(BaseModel):
    model_config = ConfigDict(protected_namespaces=())
    model_a: str
    model_b: str
    preferred_model: str # Can be model_a, model_b, or "tie"
    prompt_or_image_ref: str # Reference to the content used for testing
    timestamp: datetime = datetime.now()
