"""Reassemble lossless CI screenshots from GitHub's ci-shot check runs.

Requires an authenticated gh CLI. Useful when artifact-download hosts are
unreachable. Usage: python tools/read_ci_screenshots.py --sha <commit>
               --output <review-directory>
"""
import argparse
import base64
from collections import defaultdict
import json
from pathlib import Path
import re
import subprocess

REPO = "rehmaahmed11/MOBILE-SERVICING-TOOLS"


def json_documents(text):
    decoder = json.JSONDecoder()
    while text.strip():
        text = text.lstrip()
        value, end = decoder.raw_decode(text)
        yield value
        text = text[end:]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sha", required=True)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    result = subprocess.run(
        ["gh", "api", f"repos/{REPO}/commits/{args.sha}/check-runs?per_page=100",
         "--paginate"], check=True, text=True, capture_output=True)
    chunks = defaultdict(dict)
    totals = {}
    for document in json_documents(result.stdout):
        for check in document["check_runs"]:
            match = re.fullmatch(r"ci-shot ([a-zA-Z0-9_-]+) (\d+)/(\d+)", check["name"])
            if not match:
                continue
            name, index, total = match.groups()
            index, total = int(index), int(total)
            # A rerun can publish another copy: the latest check wins.
            previous = chunks[name].get(index)
            if previous is None or previous[0] < check["id"]:
                chunks[name][index] = (check["id"], check["output"]["text"])
                totals[name] = total
    if not chunks:
        raise SystemExit("No ci-shot check runs yet for this commit")
    args.output.mkdir(parents=True, exist_ok=True)
    for name in sorted(chunks):
        total = totals[name]
        if any(i not in chunks[name] for i in range(1, total + 1)):
            raise SystemExit(f"Incomplete screenshot: {name}")
        payload = "".join(chunks[name][i][1] for i in range(1, total + 1))
        image = base64.b64decode(payload, validate=True)
        if image.startswith(b"\x89PNG\r\n\x1a\n"):
            extension = ".png"
        elif image[:6] in (b"GIF87a", b"GIF89a"):
            extension = ".gif"  # older CI commits
        else:
            raise SystemExit(f"Unknown screenshot format: {name}")
        path = args.output / (name + extension)
        path.write_bytes(image)
        print(f"{path} ({len(image):,} bytes)")


if __name__ == "__main__":
    main()
