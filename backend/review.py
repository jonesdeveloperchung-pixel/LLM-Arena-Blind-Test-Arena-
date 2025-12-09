#!/usr/bin/env python3
"""
審核 CLI 工具 (Review CLI)
Phase 2: 審核隊列管理
"""
import sqlite3
import sys
from pathlib import Path
import shutil

def list_pending():
    """列出待審核項目"""
    conn = sqlite3.connect("./db/pipeline.db")
    cursor = conn.cursor()
    cursor.execute("SELECT id, filename, created_at FROM pipeline_items WHERE status='pending' ORDER BY created_at")
    items = cursor.fetchall()
    conn.close()
    
    if not items:
        print("✅ 無待審核項目")
        return
    
    print(f"\n📋 待審核項目 ({len(items)} 個):\n")
    for id, filename, created_at in items:
        print(f"  [{id}] {filename} - {created_at}")

def show_item(item_id):
    """顯示項目詳情"""
    conn = sqlite3.connect("./db/pipeline.db")
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM pipeline_items WHERE id=?", (item_id,))
    item = cursor.fetchone()
    conn.close()
    
    if not item:
        print(f"❌ 找不到項目: {item_id}")
        return
    
    print(f"\n📄 項目詳情:\n")
    print(f"  ID: {item[0]}")
    print(f"  檔案: {item[1]}")
    print(f"  狀態: {item[3]}")
    print(f"  來源: {item[4]}")
    print(f"  描述: {item[6][:100]}...")

def approve_item(item_id):
    """批准項目"""
    conn = sqlite3.connect("./db/pipeline.db")
    cursor = conn.cursor()
    cursor.execute("UPDATE pipeline_items SET status='approved' WHERE id=?", (item_id,))
    cursor.execute("INSERT INTO approval_history (item_id, action) VALUES (?, 'approve')", (item_id,))
    conn.commit()
    conn.close()
    print(f"✅ 已批准: {item_id}")

def reject_item(item_id):
    """拒絕項目"""
    conn = sqlite3.connect("./db/pipeline.db")
    cursor = conn.cursor()
    cursor.execute("SELECT filepath FROM pipeline_items WHERE id=?", (item_id,))
    result = cursor.fetchone()
    
    if result:
        # 移至失敗目錄
        src = Path(result[0])
        dst = Path("./output/_failed") / src.name
        dst.parent.mkdir(exist_ok=True)
        if src.exists():
            shutil.move(str(src), str(dst))
    
    cursor.execute("UPDATE pipeline_items SET status='rejected' WHERE id=?", (item_id,))
    cursor.execute("INSERT INTO approval_history (item_id, action) VALUES (?, 'reject')", (item_id,))
    conn.commit()
    conn.close()
    print(f"❌ 已拒絕: {item_id}")

def main():
    if len(sys.argv) < 2:
        print("使用方式:")
        print("  python review.py list              - 列出待審核")
        print("  python review.py show <id>         - 顯示詳情")
        print("  python review.py approve <id>      - 批准項目")
        print("  python review.py reject <id>       - 拒絕項目")
        return
    
    cmd = sys.argv[1]
    
    if cmd == "list":
        list_pending()
    elif cmd == "show" and len(sys.argv) > 2:
        show_item(sys.argv[2])
    elif cmd == "approve" and len(sys.argv) > 2:
        approve_item(sys.argv[2])
    elif cmd == "reject" and len(sys.argv) > 2:
        reject_item(sys.argv[2])
    else:
        print("❌ 無效指令")

if __name__ == "__main__":
    main()
