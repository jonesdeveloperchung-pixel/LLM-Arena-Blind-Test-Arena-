import subprocess
import sys
from pathlib import Path
import re

# Assuming init_db.py has been temporarily modified not to prompt for overwrite
# or we handle the overwrite scenario if it's run without user interaction.
# For this integration test, we want it to proceed without user input.

def run_command(command, description):
    print(f"\n--- Running: {description} ---")
    try:
        result = subprocess.run(command, check=True, capture_output=True, text=True, shell=True)
        print(result.stdout)
        if result.stderr:
            print(f"Stderr: {result.stderr}")
        return True, result.stdout + result.stderr
    except subprocess.CalledProcessError as e:
        print(f"❌ Command failed: {e.cmd}")
        print(f"Stdout: {e.stdout}")
        print(f"Stderr: {e.stderr}")
        return False, e.stdout + e.stderr
    except Exception as e:
        print(f"❌ An unexpected error occurred: {e}")
        return False, str(e)

def test_integration_phase0():
    print("--- Starting Phase 0 Integration Test ---")
    all_passed = True
    overall_output = ""

    backend_path = Path(__file__).parent.parent

    # Ensure init_db.py is set to non-interactive mode for this test
    # This modification is temporary for integration testing
    init_db_path = backend_path / "init_db.py"
    with open(init_db_path, 'r', encoding='utf-8') as f:
        init_db_content = f.read()
    
    original_init_db_content = init_db_content
    # Replace interactive prompt with non-interactive return False on existence
    modified_init_db_content = re.sub(
        r'if Path(db_path).exists():\s*print(f"⚠️  資料庫已存在: {db_path}")\s*response = input("是否覆蓋？(y/N): ").strip().lower()\s*if response != \'y\':\s*print("❌ 取消初始化")\s*return False',
        r'if Path(db_path).exists():\n        print(f"⚠️  資料庫已存在: {db_path}")\n        print("❌ 取消初始化 (非互動模式)")\n        return False',
        init_db_content,
        flags=re.DOTALL
    )

    with open(init_db_path, 'w', encoding='utf-8') as f:
        f.write(modified_init_db_content)


    # 1. Execute validate_config.py
    success, output = run_command([sys.executable, str(backend_path / "validate_config.py"), "--config-path", str(backend_path / "config" / "jade_config.yaml")], "Validate Configuration")
    overall_output += output
    if not success or "✅ 配置驗證通過" not in output:
        print("❌ Integration Test Failed at Validate Configuration step.")
        all_passed = False

    # 2. Execute init_db.py (assuming it's safe to overwrite for testing or non-interactive)
    # Ensure any existing db is removed for a clean init
    remove_db_cmd = ["Remove-Item", "-Path", str(backend_path / "db" / "pipeline.db"), "-ErrorAction", "SilentlyContinue"]
    subprocess.run(remove_db_cmd, shell=True) # Use shell=True for Remove-Item to work on Windows

    success, output = run_command([sys.executable, str(init_db_path)], "Initialize Database")
    overall_output += output
    if not success or "✅ 資料庫初始化成功" not in output:
        print("❌ Integration Test Failed at Initialize Database step.")
        all_passed = False

    # 3. Check all directories (re-using logic from TC201)
    if all_passed: # Only if previous steps passed
        print("\n--- Checking Directory Existence ---")
        expected_dirs = [
            "config", "db", "input", "output", "output/_failed", "templates", "logs", "temp", "tests",
        ]
        all_dirs_exist = True
        for d in expected_dirs:
            full_path = backend_path / d
            if not full_path.is_dir():
                print(f"❌ Fail: Directory does not exist: {full_path}")
                all_dirs_exist = False
            else:
                print(f"✅ Pass: Directory exists: {full_path}")
        if not all_dirs_exist:
            print("❌ Integration Test Failed at Directory Existence step.")
            all_passed = False
        else:
            print("✅ Directory Existence Check Passed.")

    # 4. Validate template existence (re-using logic from TC301)
    if all_passed: # Only if previous steps passed
        print("\n--- Checking Template Existence ---")
        template_path = backend_path / "templates" / "description.zh-TW.md"
        if not template_path.is_file():
            print(f"❌ Fail: Template file not found: {template_path}")
            all_passed = False
        else:
            print(f"✅ Pass: Template file exists: {template_path}")
        
        if not all_passed:
            print("❌ Integration Test Failed at Template Existence step.")
        else:
            print("✅ Template Existence Check Passed.")

    if all_passed:
        print("\n✅ Phase 0 Integration Test Passed!")
    else:
        print("\n❌ Phase 0 Integration Test Failed!")

    # Revert init_db.py to original content
    with open(init_db_path, 'w', encoding='utf-8') as f:
        f.write(original_init_db_content)

    return all_passed

if __name__ == "__main__":
    if not test_integration_phase0():
        sys.exit(1)
