#!/usr/bin/env python3
"""
備份系統 (Backup System)
Phase 5: 資料保護
"""
import shutil
from pathlib import Path
from datetime import datetime

def backup_database():
    """備份資料庫"""
    db_path = Path("./db/pipeline.db")
    backup_dir = Path("./db/backups")
    backup_dir.mkdir(exist_ok=True)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = backup_dir / f"pipeline_{timestamp}.db"
    
    shutil.copy(db_path, backup_path)
    print(f"✅ 資料庫已備份: {backup_path}")
    
    # 保留最近 7 天
    for old_backup in sorted(backup_dir.glob("*.db"))[:-7]:
        old_backup.unlink()
        print(f"🗑️  刪除舊備份: {old_backup.name}")

if __name__ == "__main__":
    backup_database()
