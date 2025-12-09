from datetime import datetime
from typing import List, Dict, Optional
import json
import uuid
import random
import time
from pathlib import Path
import logging

from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import PlainTextResponse

from models import BenchmarkRunResponse, BenchmarkRunRequest, CompareRequest, CompareResponse, BlindTestResult
from dependencies import get_pipeline
from api import OllamaClient
from benchmark import run_benchmark as execute_benchmark, CATEGORIES

router = APIRouter()
logger = logging.getLogger("BackendAPI")

@router.post("/benchmark/run", response_model=BenchmarkRunResponse)
async def run_benchmark(request: BenchmarkRunRequest):
    """
    Runs a real LLM benchmark for a given category and saves to DB.
    """
    logger.info(f"API: Benchmark run requested for category: {request.category}, model: {request.model}")
    
    category_key = request.category.lower()
    # Mapping for UI consistency
    if category_key == "language":
        category_key = "general"

    if category_key not in CATEGORIES:
         raise HTTPException(status_code=400, detail=f"Invalid category. Available: {', '.join(CATEGORIES.keys())}")

    pipeline = get_pipeline()
    
    # Mapping for UI model names to Ollama tags
    model_name = request.model
    if model_name == "Llama 3.2":
        model_name = "gemma3:4b"
    
    # Run the actual benchmark
    try:
        # Use pipeline.config which is already loaded
        result = execute_benchmark(model_name, category_key, pipeline.config, language=request.language or "en")
        
        score = float(result['score'])
        breakdown = {k: float(v) for k, v in result['breakdown'].items()}
        reasoning = result['reasoning']
        run_timestamp = result['timestamp']
        
        run_id = str(uuid.uuid4())
        
        # Record to DB
        pipeline._record_benchmark_result(
            run_id=run_id,
            category=category_key,
            model=request.model, # Store original name for consistency
            score=score,
            breakdown_json=json.dumps(breakdown),
            reasoning=reasoning,
            run_timestamp=run_timestamp
        )
        
        return BenchmarkRunResponse(
            category=request.category,
            model=request.model,
            score=score,
            breakdown=breakdown,
            reasoning=reasoning,
            run_timestamp=run_timestamp,
            message="Benchmark completed successfully."
        )
    except Exception as e:
        logger.error(f"Benchmark run failed: {e}")
        raise HTTPException(status_code=500, detail=f"Benchmark execution failed: {e}")

@router.get("/benchmark/results/{category}", response_model=BenchmarkRunResponse)
async def get_benchmark_results(category: str):
    """
    Retrieves the last simulated benchmark result for a given category from DB.
    """
    pipeline = get_pipeline()
    conn = None
    try:
        conn = pipeline._get_db_connection()
        cursor = conn.cursor()
        
        search_category = category.lower()
        if search_category == "language":
            search_category = "general"

        cursor.execute("""
            SELECT id, category, model, score, breakdown_json, reasoning, run_timestamp 
            FROM benchmark_results 
            WHERE category = ? 
            ORDER BY run_timestamp DESC 
            LIMIT 1
        """, (search_category,))
        row = cursor.fetchone()
        
        if not row:
            raise HTTPException(status_code=404, detail="No benchmark results found for this category.")
        
        breakdown = {}
        if row[4]:
            try:
                breakdown = json.loads(row[4])
            except Exception:
                logger.warning(f"Failed to parse breakdown JSON for result {row[0]}")
                breakdown = {}

        return BenchmarkRunResponse(
            category=category,
            model=row[2],
            score=row[3],
            breakdown=breakdown,
            reasoning=row[5],
            run_timestamp=row[6]
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to retrieve benchmark results from DB for category {category}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve benchmark results: {e}")
    finally:
        if conn:
            conn.close()

@router.get("/benchmark/history/{category}", response_model=List[BenchmarkRunResponse])
async def get_benchmark_history(category: str):
    """
    Retrieves all historical benchmark results for a given category from DB.
    """
    pipeline = get_pipeline()
    conn = None
    try:
        conn = pipeline._get_db_connection()
        cursor = conn.cursor()
        
        search_category = category.lower()
        if search_category == "language":
            search_category = "general"

        cursor.execute("""
            SELECT id, category, model, score, breakdown_json, reasoning, run_timestamp 
            FROM benchmark_results 
            WHERE category = ? 
            ORDER BY run_timestamp ASC
        """, (search_category,))
        rows = cursor.fetchall()
        
        history = []
        for row in rows:
            breakdown = {}
            if row[4]:
                try:
                    breakdown = json.loads(row[4])
                except:
                    breakdown = {}

            history.append(BenchmarkRunResponse(
                category=category,
                model=row[2],
                score=row[3],
                breakdown=breakdown,
                reasoning=row[5],
                run_timestamp=row[6]
            ))
        return history
    except Exception as e:
        logger.error(f"Failed to retrieve benchmark history from DB for category {category}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve benchmark history: {e}")
    finally:
        if conn:
            conn.close()

@router.get("/benchmark/report", response_class=PlainTextResponse)
async def generate_benchmark_report(
    category: Optional[str] = Query(None, description="Benchmark category to filter by"),
    model: Optional[str] = Query(None, description="Model name to filter by"),
    start_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD) to filter by"),
    end_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD) to filter by")
):
    """
    Generates a Markdown report of benchmark results based on filters.
    """
    pipeline = get_pipeline()
    conn = None
    try:
        conn = pipeline._get_db_connection()
        cursor = conn.cursor()

        query_parts = []
        query_params = []

        if category:
            search_cat = category.lower()
            if search_cat == "language":
                search_cat = "general"
            query_parts.append("category = ?")
            query_params.append(search_cat)
        if model:
            query_parts.append("model = ?")
            query_params.append(model)
        if start_date:
            query_parts.append("run_timestamp >= ?")
            query_params.append(start_date + " 00:00:00")
        if end_date:
            query_parts.append("run_timestamp <= ?")
            query_params.append(end_date + " 23:59:59")

        sql = "SELECT category, model, score, breakdown_json, reasoning, run_timestamp FROM benchmark_results"
        if query_parts:
            sql += " WHERE " + " AND ".join(query_parts)
        sql += " ORDER BY run_timestamp DESC"

        cursor.execute(sql, query_params)
        rows = cursor.fetchall()

        if not rows:
            return "## No Benchmark Results Found\n\nNo results matched your criteria."

        report = "# LLM Benchmark Report\n\n"
        report += f"**Generated On:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
        report += "**Filters:**\n"
        report += f"- Category: {category if category else 'All'}\n"
        report += f"- Model: {model if model else 'All'}\n"
        report += f"- Date Range: {start_date if start_date else 'All'} to {end_date if end_date else 'All'}\n\n"
        
        for row in rows:
            category, model, score, breakdown_json, reasoning, run_timestamp = row
            breakdown = {}
            if breakdown_json:
                try:
                    breakdown = json.loads(breakdown_json)
                except:
                    pass

            report += f"## {category.capitalize()} Benchmark - {model}\n"
            report += f"- **Score:** {score:.1f}\n"
            report += f"- **Run Timestamp:** {run_timestamp}\n"
            report += "- **Breakdown:**\n"
            for k, v in breakdown.items():
                report += f"  - {k}: {v:.1f}\n"
            report += f"- **Reasoning:** {reasoning}\n\n"
        
        return report

    except Exception as e:
        logger.error(f"Failed to generate benchmark report: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to generate report: {e}")
    finally:
        if conn:
            conn.close()

@router.post("/benchmark/compare", response_model=CompareResponse)
async def compare_models(request: CompareRequest):
    """
    Compares two models side-by-side with a given prompt or image.
    """
    pipeline = get_pipeline()
    
    if not pipeline.api.check_health():
        raise HTTPException(
            status_code=503,
            detail="Ollama service is not running or not accessible for comparison.",
        )

    model1_client = OllamaClient(base_url=pipeline.api.base_url, model=request.model1)
    model2_client = OllamaClient(base_url=pipeline.api.base_url, model=request.model2)

    model1_response = {}
    model2_response = {}

    try:
        if request.image_path:
            if not Path(request.image_path).exists():
                raise HTTPException(status_code=400, detail=f"Image path not found: {request.image_path}")
            
            logger.info(f"Comparing models {request.model1} and {request.model2} with image {request.image_path}")
            model1_response = model1_client.generate_description(request.image_path, request.prompt or "Describe this image.", language=request.language) or {"error": f"Model {request.model1} failed."}
            model2_response = model2_client.generate_description(request.image_path, request.prompt or "Describe this image.", language=request.language) or {"error": f"Model {request.model2} failed."}
        elif request.prompt:
            logger.info(f"Comparing models {request.model1} and {request.model2} with prompt '{request.prompt}'")
            model1_response = model1_client.generate_description(prompt=request.prompt, language=request.language) or {"error": f"Model {request.model1} failed."}
            model2_response = model2_client.generate_description(prompt=request.prompt, language=request.language) or {"error": f"Model {request.model2} failed."}
        else:
            raise HTTPException(status_code=400, detail="Either image_path or prompt must be provided for comparison.")
        
        return CompareResponse(
            model1_response=model1_response,
            model2_response=model2_response
        )

    except Exception as e:
        logger.error(f"Error during model comparison: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to compare models: {e}")

@router.get("/blind_test/prompt")
async def get_blind_test_prompt(
    model_exclude: Optional[List[str]] = Query(None)
):
    """
    Provides a prompt/image and two randomly selected model outputs (blinded) for testing.
    """
    pipeline = get_pipeline()
    ollama_models_raw = []
    try:
        ollama_client_temp = OllamaClient()
        ollama_models_raw = ollama_client_temp.get_ollama_models()
        available_models = [m['name'] for m in ollama_models_raw if m['name'] not in (model_exclude or [])]
        
        if len(available_models) < 2:
            raise HTTPException(status_code=400, detail="Not enough models available for blind testing.")

        model_a = random.choice(available_models)
        model_b = random.choice([m for m in available_models if m != model_a])

        test_image_path = "backend/input/sample.jpg"
        test_prompt = "Describe this image."
        
        model_a_response = OllamaClient(base_url=pipeline.api.base_url, model=model_a).generate_description(test_image_path, test_prompt) or {"description": "Model A failed.", "confidence": 0.0}
        model_b_response = OllamaClient(base_url=pipeline.api.base_url, model=model_b).generate_description(test_image_path, test_prompt) or {"description": "Model B failed.", "confidence": 0.0}

        return {
            "prompt_content": test_image_path,
            "prompt_text": test_prompt,
            "response_a": model_a_response['description'],
            "response_b": model_b_response['description'],
            "model_a_id": model_a,
            "model_b_id": model_b,
        }

    except Exception as e:
        logger.error(f"Failed to get blind test prompt: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get blind test prompt: {e}")

@router.post("/blind_test/submit")
async def submit_blind_test_result(result: BlindTestResult):
    """
    Submits the user's preference for a blind test comparison.
    """
    pipeline = get_pipeline()
    conn = None
    try:
        conn = pipeline._get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            INSERT INTO blind_test_results (
                id, model_a, model_b, preferred_model, prompt_or_image_ref, timestamp
            ) VALUES (?, ?, ?, ?, ?, ?)
        """, (
            str(uuid.uuid4()),
            result.model_a,
            result.model_b,
            result.preferred_model,
            result.prompt_or_image_ref,
            result.timestamp.isoformat()
        ))
        conn.commit()
        return {"message": "Blind test result submitted successfully."}
    except Exception as e:
        logger.error(f"Failed to submit blind test result: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to submit blind test result: {e}")
    finally:
        if conn:
            conn.close()