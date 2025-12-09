import sys
import json
from pathlib import Path

# Add parent directory to path to allow imports
sys.path.append(str(Path(__file__).parent.parent))

from pipeline import ImagePipeline

if __name__ == "__main__":
    pipeline = ImagePipeline()
    images = pipeline.scan_input()
    # Print a JSON array of image paths
    print(json.dumps([str(image) for image in images]))
    sys.exit(0)
