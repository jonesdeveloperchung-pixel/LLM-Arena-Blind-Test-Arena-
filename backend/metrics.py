#!/usr/bin/env python3
"""
效能指標 (Performance Metrics)
Phase 5: 監控與分析
"""
import sqlite3
from datetime import datetime, timedelta

def get_metrics():
    """取得效能指標"""
    conn = sqlite3.connect("./db/pipeline.db")
    cursor = conn.cursor()
    
    # 總計
    cursor.execute("SELECT COUNT(*) FROM pipeline_items")
    total = cursor.fetchone()[0]
    
    # 狀態統計
    cursor.execute("SELECT status, COUNT(*) FROM pipeline_items GROUP BY status")
    status_counts = dict(cursor.fetchall())
    
    # 平均處理時間
    cursor.execute("SELECT AVG(processing_time_ms) FROM pipeline_items WHERE processing_time_ms IS NOT NULL")
    avg_time = cursor.fetchone()[0] or 0
    
    # 最近 24 小時
    yesterday = (datetime.now() - timedelta(days=1)).isoformat()
    cursor.execute("SELECT COUNT(*) FROM pipeline_items WHERE created_at > ?", (yesterday,))
    last_24h = cursor.fetchone()[0]
    
    conn.close()
    
    return {
        'total': total,
        'pending': status_counts.get('pending', 0),
        'approved': status_counts.get('approved', 0),
        'rejected': status_counts.get('rejected', 0),
        'failed': status_counts.get('failed', 0),
        'avg_processing_time_ms': avg_time,
        'last_24h': last_24h
    }

def print_metrics():
    """列印指標"""
    metrics = get_metrics()
    
    print("\n📊 系統效能指標\n")
    print(f"  總處理數: {metrics['total']}")
    print(f"  待審核: {metrics['pending']}")
    print(f"  已批准: {metrics['approved']}")
    print(f"  已拒絕: {metrics['rejected']}")
    print(f"  失敗: {metrics['failed']}")
    print(f"  平均處理時間: {metrics['avg_processing_time_ms']:.0f} ms")
    print(f"  最近 24 小時: {metrics['last_24h']}")

if __name__ == "__main__":
    print_metrics()
