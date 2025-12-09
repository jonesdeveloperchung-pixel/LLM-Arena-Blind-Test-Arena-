from fastapi import APIRouter, BackgroundTasks, HTTPException
from fastapi.responses import JSONResponse
import logging
from typing import List
from models import PipelineTriggerResponse, PipelineItem, PipelineItemUpdateRequest

from dependencies import get_pipeline

router = APIRouter()
logger = logging.getLogger("BackendAPI")

@router.post("/pipeline/run", response_model=PipelineTriggerResponse)
async def run_pipeline(background_tasks: BackgroundTasks):
    """
    Triggers a single run of the image processing pipeline.
    Processing happens in the background.
    """
    logger.info("API: Pipeline run requested.")
    pipeline = get_pipeline()
    
    if not pipeline.api.check_health():
        raise HTTPException(
            status_code=503,
            detail="Ollama service is not running or model not available. Please check Ollama server.",
        )

    background_tasks.add_task(pipeline.run)
    logger.info("API: Pipeline run initiated in background.")
    return JSONResponse(content={"message": "Pipeline run initiated.", "status": "processing"})

@router.get("/pipeline/status")
async def get_pipeline_status():
    """
    Returns the current status of the pipeline (e.g., number of pending items, total processed).
    """
    pipeline = get_pipeline()
    
    total_processed = 0
    pending_items = 0
    approved_items = 0
    rejected_items = 0
    avg_processing_time = 0.0
    
    conn = None
    try:
        conn = pipeline._get_db_connection()
        cursor = conn.cursor()

        # Count items by status
        cursor.execute("SELECT status, COUNT(*) FROM pipeline_items GROUP BY status")
        status_counts = dict(cursor.fetchall())
        
        pending_items = status_counts.get('processing', 0) + status_counts.get('pending', 0)
        approved_items = status_counts.get('approved', 0)
        rejected_items = status_counts.get('rejected', 0)
        
        # Total processed items are approved + rejected
        total_processed = approved_items + rejected_items

        # Calculate average processing time
        cursor.execute("SELECT AVG(processing_time_ms) FROM pipeline_items WHERE processing_time_ms IS NOT NULL")
        avg_processing_time = cursor.fetchone()[0] or 0.0

        uptime = "N/A"

        return {
            "status": "ready",
            "pending_items": pending_items,
            "total_processed": total_processed,
            "approved_items": approved_items,
            "rejected_items": rejected_items,
            "avg_processing_time": avg_processing_time,
            "uptime": uptime,
        }
    except Exception as e:
        logger.error(f"Failed to get pipeline status from DB: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve pipeline status: {e}")
    finally:
        if conn:
            conn.close()

@router.get("/pipeline/items", response_model=List[PipelineItem])
async def get_pipeline_items():
    """
    Retrieves all pipeline items from the database.
    """
    pipeline = get_pipeline()
    conn = None
    try:
        conn = pipeline._get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT id, filename, filepath, status, source, created_at, updated_at,
                   processing_time_ms, confidence_score, description,
                   metadata_json, detection_raw_json, error_message
            FROM pipeline_items
            ORDER BY created_at DESC
        """)
        rows = cursor.fetchall()
        
        items = []
        for row in rows:
            items.append(PipelineItem(
                id=row[0],
                filename=row[1],
                filepath=row[2],
                status=row[3],
                source=row[4],
                created_at=row[5],
                updated_at=row[6],
                processing_time_ms=row[7],
                confidence_score=row[8],
                description=row[9],
                metadata_json=row[10],
                detection_raw_json=row[11],
                error_message=row[12],
            ))
        return items
    except Exception as e:
        logger.error(f"Failed to retrieve pipeline items from DB: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve pipeline items: {e}")
    finally:
        if conn:
            conn.close()
@router.get("/pipeline/items/{item_id}", response_model=PipelineItem)
async def get_pipeline_item(item_id: str):
    """
    Retrieves a specific pipeline item by its ID from the database.
    """
    pipeline = get_pipeline()
    conn = None
    try:
        conn = pipeline._get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            SELECT id, filename, filepath, status, source, created_at, updated_at,
                   processing_time_ms, confidence_score, description,
                   metadata_json, detection_raw_json, error_message
            FROM pipeline_items
            WHERE id = ?
        """, (item_id,))
        row = cursor.fetchone()
        
        if not row:
            raise HTTPException(status_code=404, detail=f"Pipeline item with ID {item_id} not found.")

        item = PipelineItem(
            id=row[0],
            filename=row[1],
            filepath=row[2],
            status=row[3],
            source=row[4],
            created_at=row[5],
            updated_at=row[6],
            processing_time_ms=row[7],
            confidence_score=row[8],
            description=row[9],
            metadata_json=row[10],
            detection_raw_json=row[11],
            error_message=row[12],
        )
        return item
    except HTTPException:
        raise # Re-raise HTTPExceptions
    except Exception as e:
        logger.error(f"Failed to retrieve pipeline item {item_id} from DB: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve pipeline item: {e}")
    finally:
        if conn:
            conn.close()

@router.post("/pipeline/items/{item_id}/update")
async def update_pipeline_item(item_id: str, request: PipelineItemUpdateRequest):
    """
    Updates the status or details of a specific pipeline item in the database.
    """
    pipeline = get_pipeline()
    conn = None
    try:
        conn = pipeline._get_db_connection()
        cursor = conn.cursor()
        
        update_fields = []
        update_values = []

        if request.description is not None:
            update_fields.append("description = ?")
            update_values.append(request.description)
        if request.status is not None:
            update_fields.append("status = ?")
            update_values.append(request.status)
        
        if not update_fields:
            raise HTTPException(status_code=400, detail="No fields provided for update.")

        update_values.append(item_id) # Add item_id for WHERE clause

        sql = f"""
            UPDATE pipeline_items
            SET {', '.join(update_fields)}, updated_at = CURRENT_TIMESTAMP
            WHERE id = ?
        """
        cursor.execute(sql, tuple(update_values))
        conn.commit()

        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail=f"Pipeline item with ID {item_id} not found.")

        return {"message": f"Pipeline item {item_id} updated successfully."}
    except HTTPException:
        raise # Re-raise HTTPExceptions
    except Exception as e:
        logger.error(f"Failed to update pipeline item {item_id} in DB: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to update pipeline item: {e}")
    finally:
        if conn:
            conn.close()
