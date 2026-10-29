"""Generate brand assets through OpenRouter's dedicated Images API.

The OpenRouter key is read from the local OpenCode auth file; it is never
printed or written into the repository.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
from pathlib import Path

import requests
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
AUTH = Path.home() / ".local" / "share" / "opencode" / "auth.json"
API = "https://openrouter.ai/api/v1/images"


def api_key() -> str:
    key = os.environ.get("OPENROUTER_API_KEY")
    if key:
        return key
    data = json.loads(AUTH.read_text(encoding="utf-8"))
    return data["openrouter"]["key"]


def generate(
    prompt: str,
    model: str,
    out: Path,
    *,
    resolution: str | None = None,
    aspect_ratio: str = "1:1",
    output_format: str | None = None,
    quality: str | None = None,
    n: int = 1,
) -> None:
    payload: dict[str, object] = {
        "model": model,
        "prompt": prompt,
        "n": n,
        "aspect_ratio": aspect_ratio,
    }
    if resolution:
        payload["resolution"] = resolution
    if output_format:
        payload["output_format"] = output_format
    if quality:
        payload["quality"] = quality

    response = requests.post(
        API,
        headers={
            "Authorization": f"Bearer {api_key()}",
            "Content-Type": "application/json",
            "HTTP-Referer": "https://nada.isdose.com",
            "X-Title": "nada!",
        },
        json=payload,
        timeout=300,
    )
    if not response.ok:
        print(response.status_code, response.text[:1000])
        response.raise_for_status()

    result = response.json()
    out.parent.mkdir(parents=True, exist_ok=True)
    for index, image in enumerate(result.get("data", [])):
        media = image.get("media_type", "image/png")
        extension = "svg" if "svg" in media else "png"
        suffix = f"-{index}" if n > 1 else ""
        path = out.with_name(f"{out.stem}{suffix}.{extension}")
        path.write_bytes(base64.b64decode(image["b64_json"]))
        print(f"saved {path} ({path.stat().st_size} bytes, {media})")
        if extension == "png":
            with Image.open(path) as bitmap:
                print(f"  {bitmap.size[0]}x{bitmap.size[1]} {bitmap.mode}")
    print("usage", json.dumps(result.get("usage"), ensure_ascii=False))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", default="google/gemini-nano-banana-2.1")
    parser.add_argument("--resolution", default="2K")
    parser.add_argument("--aspect", default="1:1")
    parser.add_argument("--format", default=None)
    parser.add_argument("--quality", default=None)
    parser.add_argument("--n", type=int, default=1)
    parser.add_argument("--out", required=True)
    parser.add_argument("--prompt", required=True)
    args = parser.parse_args()

    generate(
        args.prompt,
        args.model,
        ROOT / args.out,
        resolution=args.resolution or None,
        aspect_ratio=args.aspect,
        output_format=args.format,
        quality=args.quality,
        n=args.n,
    )


if __name__ == "__main__":
    main()
