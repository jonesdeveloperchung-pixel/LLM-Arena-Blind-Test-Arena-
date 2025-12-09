import sys
from pathlib import Path

# Add parent directory to path to allow imports
sys.path.append(str(Path(__file__).parent.parent))

from api import OllamaClient

if __name__ == "__main__":
    client = OllamaClient()
    if client.check_health():
        print("Ollama server is healthy.")
        sys.exit(0)
    else:
        print("Ollama server is not healthy.")
        sys.exit(1)
