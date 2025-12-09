import sys
import argparse
from pathlib import Path

# Add parent directory to path to allow imports
sys.path.append(str(Path(__file__).parent.parent))

from api import OllamaClient

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate image description using Ollama.")
    parser.add_argument("--image_path", required=True, help="Path to the image file.")
    parser.add_argument("--prompt", default="Describe this image in detail and identify all objects with their bounding boxes if possible. Focus on key elements.", help="Prompt for generating the description.")
    parser.add_argument("--model", default=None, help="Ollama model to use.")
    args = parser.parse_args()

    client = OllamaClient(model=args.model if args.model else "llama3.2-vision") # Default model if not provided
    result = client.generate_description(args.image_path, args.prompt, model=args.model)

    if result:
        print(result)
        sys.exit(0)
    else:
        print("Failed to generate description.")
        sys.exit(1)
