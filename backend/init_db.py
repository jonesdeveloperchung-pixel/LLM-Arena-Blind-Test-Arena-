#!/usr/bin/env python3
"""
資料庫初始化腳本 (Database Initialization Script)
用途：建立 SQLite 資料庫並執行 schema
"""
import sqlite3
import os
from pathlib import Path

def init_database(db_path: Path = Path(__file__).parent / "db" / "pipeline.db", 
                    schema_path: Path = Path(__file__).parent / "db" / "schema.sql",
                    benchmark_schema_path: Path = Path(__file__).parent / "db" / "benchmark_schema.sql",
                    telemetry_schema_path: Path = Path(__file__).parent / "db" / "telemetry_schema.sql"):
    """初始化資料庫"""
    db_dir = Path(db_path).parent
    db_dir.mkdir(parents=True, exist_ok=True)
    
    if Path(db_path).exists():
        print(f"⚠️  資料庫已存在: {db_path}")
        response = input("是否覆蓋？(y/N): ").strip().lower()
        if response != 'y':
            print("❌ 取消初始化")
            return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        with open(schema_path, 'r', encoding='utf-8') as f:
            pipeline_schema_sql = f.read()
        cursor.executescript(pipeline_schema_sql)

        with open(benchmark_schema_path, 'r', encoding='utf-8') as f:
            benchmark_schema_sql = f.read()
        cursor.executescript(benchmark_schema_sql)

        with open(telemetry_schema_path, 'r', encoding='utf-8') as f:
            telemetry_schema_sql = f.read()
        cursor.executescript(telemetry_schema_sql)
        
        conn.commit()
        
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = cursor.fetchall()
        
        print(f"✅ 資料庫初始化成功: {db_path}")
        print(f"📋 已建立表格: {', '.join([t[0] for t in tables])}")
        
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ 初始化失敗: {e}")
        return False

if __name__ == "__main__":
    init_database(
        schema_path=Path(__file__).parent / "db" / "schema.sql",
        benchmark_schema_path=Path(__file__).parent / "db" / "benchmark_schema.sql",
        telemetry_schema_path=Path(__file__).parent / "db" / "telemetry_schema.sql"
    )
