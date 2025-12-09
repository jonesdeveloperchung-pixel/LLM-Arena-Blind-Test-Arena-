import sys
from pathlib import Path

# Add parent directory to path to allow imports
sys.path.append(str(Path(__file__).parent.parent))

from pipeline import ImagePipeline

if __name__ == "__main__":
    pipeline = ImagePipeline()
    pipeline.run()
    sys.exit(0)
