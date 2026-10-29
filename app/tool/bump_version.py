"""Bump the visible version and the Android build number.

Every release should call this before building. By default it increments the
last number (1.0.0 -> 1.0.1) and the build code (1 -> 2).
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PUBSPEC = ROOT / "pubspec.yaml"
APP_INFO = ROOT / "lib" / "core" / "app_info.dart"

PATTERN = re.compile(
    r"^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$", re.MULTILINE
)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--part", choices=("patch", "minor", "major"), default="patch"
    )
    args = parser.parse_args()

    text = PUBSPEC.read_text(encoding="utf-8")
    match = PATTERN.search(text)
    if not match:
        raise SystemExit("No version found in pubspec.yaml.")

    major, minor, patch, build = (int(value) for value in match.groups())
    if args.part == "major":
        major += 1
        minor = 0
        patch = 0
    elif args.part == "minor":
        minor += 1
        patch = 0
    else:
        patch += 1
    build += 1

    version = f"{major}.{minor}.{patch}"
    replacement = f"version: {version}+{build}"
    text = PATTERN.sub(replacement, text, count=1)
    PUBSPEC.write_text(text, encoding="utf-8")

    info = APP_INFO.read_text(encoding="utf-8")
    info = re.sub(
        r"const String nadaVersion = '[^']*';",
        f"const String nadaVersion = '{version}';",
        info,
    )
    info = re.sub(
        r"const int nadaBuild = \d+;",
        f"const int nadaBuild = {build};",
        info,
    )
    APP_INFO.write_text(info, encoding="utf-8")
    print(f"nada! {version}+{build}")


if __name__ == "__main__":
    main()
