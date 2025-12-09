from fastapi import APIRouter, HTTPException, BackgroundTasks
from typing import List, Dict, Optional, Any
import logging
from datetime import datetime
import uuid # Import uuid
import json # Import json
from dependencies import get_pipeline # Import get_pipeline
from models import Alert # Import Alert model



router = APIRouter()
logger = logging.getLogger("BackendAPI")

@router.post("/alerts/trigger")
async def trigger_alert(
    source: str,
    message: str,
    background_tasks: BackgroundTasks,
    severity: str = "info", # info, warning, error, critical
    details: Optional[Dict] = None, # Add details parameter
):
    """
    Endpoint to programmatically trigger a new alert.
    """
    pipeline = get_pipeline()
    conn = None
    try:
        conn = pipeline._get_db_connection()
        cursor = conn.cursor()
        
        alert_id = str(uuid.uuid4()) # Generate UUID for alert_id
        timestamp = datetime.now().isoformat()
        status = "active"
        
        cursor.execute("""
            INSERT INTO alerts (id, timestamp, source, message, severity, details, status)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            alert_id,
            timestamp,
            source,
            message,
            severity,
            json.dumps(details) if details else None, # Store details as JSON string
            status
        ))
        conn.commit()
        
        logger.info(f"Alert triggered and saved to DB: id={alert_id}, message='{message}'")
        
        return {"message": "Alert triggered successfully", "alert_id": alert_id}
    except Exception as e:
        logger.error(f"Failed to trigger alert and save to DB: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to trigger alert: {e}")
    finally:
        if conn:
            conn.close()

@router.get("/alerts", response_model=List[Alert])
async def list_alerts(status: Optional[str] = None, severity: Optional[str] = None):
    """
    List all active or historical alerts, with optional filtering by status or severity.
    """
    pipeline = get_pipeline()
    conn = None
    try:
        conn = pipeline._get_db_connection()
        cursor = conn.cursor()

        query_parts = []
        query_params = []

        if status:
            query_parts.append("status = ?")
            query_params.append(status)
        if severity:
            query_parts.append("severity = ?")
            query_params.append(severity)

        sql = """
            SELECT id, timestamp, source, message, severity, details, status, dismissed_at, resolved_at
            FROM alerts
        """
        if query_parts:
            sql += " WHERE " + " AND ".join(query_parts)
        sql += " ORDER BY timestamp DESC"

        cursor.execute(sql, query_params)
        rows = cursor.fetchall()
        
        alerts = []
        for row in rows:
            alerts.append(Alert(
                id=row[0],
                timestamp=datetime.fromisoformat(row[1]),
                source=row[2],
                message=row[3],
                severity=row[4],
                details=json.loads(row[5]) if row[5] else None,
                status=row[6],
                dismissed_at=datetime.fromisoformat(row[7]) if row[7] else None,
                resolved_at=datetime.fromisoformat(row[8]) if row[8] else None,
            ))
        return alerts
    except Exception as e:
        logger.error(f"Failed to retrieve alerts from DB: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve alerts: {e}")
    finally:
        if conn:
            conn.close()

@router.post("/alerts/{alert_id}/dismiss")
async def dismiss_alert(alert_id: str): # Change type to str for UUID
    """
    Dismiss an active alert by its ID.
    """
    pipeline = get_pipeline()
    conn = None
    try:
        conn = pipeline._get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            UPDATE alerts
            SET status = ?, dismissed_at = CURRENT_TIMESTAMP
            WHERE id = ? AND status = 'active'
        """, ("dismissed", alert_id))
        conn.commit()

        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail=f"Active alert with ID {alert_id} not found.")
        
        logger.info(f"Alert {alert_id} dismissed.")
        return {"message": f"Alert {alert_id} dismissed successfully."}
    except HTTPException:
        raise # Re-raise HTTPExceptions
    except Exception as e:
        logger.error(f"Failed to dismiss alert {alert_id} in DB: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to dismiss alert: {e}")
    finally:
        if conn:
            conn.close()

@router.post("/alerts/{alert_id}/resolve")
async def resolve_alert(alert_id: str): # Change type to str for UUID
    """
    Mark an active alert as resolved by its ID.
    """
    pipeline = get_pipeline()
    conn = None
    try:
        conn = pipeline._get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            UPDATE alerts
            SET status = ?, resolved_at = CURRENT_TIMESTAMP
            WHERE id = ? AND status = 'active'
        """, ("resolved", alert_id))
        conn.commit()

        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail=f"Active alert with ID {alert_id} not found.")
        
        logger.info(f"Alert {alert_id} resolved.")
        return {"message": f"Alert {alert_id} resolved successfully."}
    except HTTPException:
        raise # Re-raise HTTPExceptions
    except Exception as e:
        logger.error(f"Failed to resolve alert {alert_id} in DB: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to resolve alert: {e}")
    finally:
        if conn:
            conn.close()

# Note: In a real application, alert rules would be configurable via API/UI and stored persistently.
# For MVP, alert rules might be hardcoded or managed externally by the monitoring system.
