"""Fetch and standardise the Queen studio album covers.

The covers are *not* redistributed with this package: they are copyrighted
artwork, used here only as input to the palette derivation in
`build_palettes.py`. This script re-creates `data-raw/covers/` locally from
Wikipedia's low-resolution fair-use files, standardised to 600x600 RGB PNG.

Run with:  python3 data-raw/download_covers.py
"""

from __future__ import annotations

import io
import os
import sys
import time
import urllib.parse
import urllib.request

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "covers")
API = "https://en.wikipedia.org/w/api.php"
SIZE = (600, 600)
UA = "killerPals/0.1 (https://github.com/noahweidig/killerpals)"

# Local key -> the English Wikipedia file page for that album's cover.
COVER_FILES = {
    "queen": "File:Queen Queen.png",
    "queen_ii": "File:Queen II (album cover).jpg",
    "sheer_heart_attack": "File:Queen Sheer Heart Attack.png",
    "night_at_the_opera": "File:Queen A Night At The Opera.png",
    "day_at_the_races": "File:A Day at the Races (Queen).jpg",
    "news_of_the_world": "File:Queen News Of The World.png",
    "jazz": "File:Queen Jazz.png",
    "the_game": "File:Queen The Game.png",
    "flash_gordon": "File:Queen Flash Gordon.png",
    "hot_space": "File:Queen Hot Space.png",
    "the_works": "File:Queen The Works.png",
    "a_kind_of_magic": "File:Queen A Kind Of Magic.png",
    "the_miracle": "File:Queen The Miracle.png",
    "innuendo": "File:Queen Innuendo.png",
    "made_in_heaven": "File:Madeinheaven.jpg",
}


def get(url: str, tries: int = 5) -> bytes:
    """GET with a descriptive User-Agent and exponential backoff."""
    last: Exception | None = None
    for attempt in range(tries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=30) as resp:
                return resp.read()
        except Exception as exc:  # transient proxy/network failures are common
            last = exc
            time.sleep(2**attempt)
    raise RuntimeError(f"giving up on {url}") from last


def image_url(title: str, width: int = 1400) -> str:
    """Resolve a File: page to a direct image URL at up to `width` pixels."""
    import json

    query = urllib.parse.urlencode({
        "action": "query", "format": "json", "prop": "imageinfo",
        "iiprop": "url", "iiurlwidth": width, "titles": title,
    })
    page = list(json.loads(get(f"{API}?{query}"))["query"]["pages"].values())[0]
    info = page["imageinfo"][0]
    return info.get("thumburl") or info["url"]


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    for key, title in COVER_FILES.items():
        dest = os.path.join(OUT, f"{key}.png")
        if os.path.exists(dest):
            print(f"have {key}")
            continue
        img = Image.open(io.BytesIO(get(image_url(title)))).convert("RGB")
        img.resize(SIZE, Image.LANCZOS).save(dest, optimize=True)
        print(f"got  {key}  {title}")

    missing = [k for k in COVER_FILES if not os.path.exists(os.path.join(OUT, f"{k}.png"))]
    if missing:
        print(f"missing: {', '.join(missing)}", file=sys.stderr)
        raise SystemExit(1)
    print(f"\n{len(COVER_FILES)} covers standardised to {SIZE[0]}x{SIZE[1]} in {OUT}")


if __name__ == "__main__":
    main()
