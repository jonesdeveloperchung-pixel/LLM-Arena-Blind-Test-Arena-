from datetime import datetime
from typing import List, Optional
import uuid
import logging

from fastapi import APIRouter, HTTPException, Query

from models import TelemetryEvent
from dependencies import get_pipeline

router = APIRouter()
logger = logging.getLogger("BackendAPI")

@router.post("/telemetry/log")
async def log_telemetry_event(event: TelemetryEvent):
    """
    Receives telemetry events from the Flutter app and stores them in the database.
    """
    pipeline = get_pipeline()
    conn = None
    try:
        conn = pipeline._get_db_connection()
        cursor = conn.cursor()

        cursor.execute("""
            INSERT INTO telemetry_logs (
                id, timestamp, program, version, command, module, action, args,
                user, host, os, runtime, execution_duration_ms, execution_exit_code,
                execution_error, context_cwd, context_details, tags
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            str(uuid.uuid4()),
            event.timestamp.isoformat(),
            event.program,
            event.version,
            event.command,
            event.module,
            event.action,
            event.args,
            event.user,
            event.host,
            event.os,
            event.runtime,
            event.execution_duration_ms,
            event.execution_exit_code,
            event.execution_error,
            event.context_cwd,
            event.context_details,
            event.tags
        ))
        conn.commit()
        return {"message": "Telemetry event logged successfully."}
    except Exception as e:
        logger.error(f"Failed to log telemetry event: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to log telemetry event: {e}")
    finally:
        if conn:
            conn.close()

@router.get("/telemetry/logs", response_model=List[TelemetryEvent])
async def get_telemetry_logs(
    program: Optional[str] = Query(None),
    module: Optional[str] = Query(None),
    action: Optional[str] = Query(None),
    start_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD)"),
    end_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD)"),
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
):
    """
    Retrieves historical telemetry logs with optional filters.
    """
    pipeline = get_pipeline()
    conn = None
    try:
        conn = pipeline._get_db_connection()
        cursor = conn.cursor()

        query_parts = []
        query_params = []

        if program:
            query_parts.append("program = ?")
            query_params.append(program)
        if module:
            query_parts.append("module = ?")
            query_params.append(module)
        if action:
            query_parts.append("action = ?")
            query_params.append(action)
        if start_date:
            query_parts.append("timestamp >= ?")
            query_params.append(start_date + " 00:00:00")
        if end_date:
            query_parts.append("timestamp <= ?")
            query_params.append(end_date + " 23:59:59")

        sql = "SELECT id, timestamp, program, version, command, module, action, args, user, host, os, runtime, execution_duration_ms, execution_exit_code, execution_error, context_cwd, context_details, tags FROM telemetry_logs"
        if query_parts:
            sql += " WHERE " + " AND ".join(query_parts)
        sql += " ORDER BY timestamp DESC LIMIT ? OFFSET ?"
        query_params.extend([limit, offset])

        cursor.execute(sql, query_params)
        rows = cursor.fetchall()
        
        logs = []
        for row in rows:
            logs.append(TelemetryEvent(
                id=row[0],
                timestamp=datetime.fromisoformat(row[1]),
                program=row[2],
                version=row[3],
                command=row[4],
                module=row[5],
                action=row[6],
                args=row[7],
                user=row[8],
                host=row[9],
                os=row[10],
                runtime=row[11],
                execution_duration_ms=row[12],
                execution_exit_code=row[13],
                execution_error=row[14],
                context_cwd=row[15],
                context_details=row[16],
                tags=row[17],
            ))
        return logs
    except Exception as e:
        logger.error(f"Failed to retrieve telemetry logs: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve telemetry logs: {e}")
    finally:
        if conn:
            conn.close()
