#!/usr/bin/env python3
"""Generate the complete Zoo-Game voice pack using OpenAI Marin.

The manifest is the single source of truth for visible text, spoken text, file
paths, model, voice, speed, and style. The script intentionally generates the
whole pack as one set so the game never mixes narrators.

Usage:
    python tools/generate_marin_audio.py --check
    python tools/generate_marin_audio.py
    python tools/generate_marin_audio.py --force

Environment:
    OPENAI_API_KEY must be set for generation. It is not needed for --check.
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import sys
import time
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "audio" / "marin" / "manifest.json"
API_URL = "https://api.openai.com/v1/audio/speech"


def load_manifest() -> dict:
    with MANIFEST_PATH.open("r", encoding="utf-8") as handle:
        data = json.load(handle)

    if data.get("schema_version") != 1:
        raise RuntimeError("Unsupported voice manifest schema_version.")

    clips = data.get("clips")
    if not isinstance(clips, dict) or not clips:
        raise RuntimeError("Voice manifest has no clips.")

    return data


def project_path_to_local(project_path: str) -> Path:
    if not project_path.startswith("res://"):
        raise ValueError(f"Expected res:// path, got: {project_path}")
    return ROOT / project_path.removeprefix("res://")


def normalize_semantic_text(text: str) -> str:
    kept = []
    for char in text.casefold():
        if char.isalnum() or char.isspace():
            kept.append(char)
    return " ".join("".join(kept).split())


def validate_manifest(data: dict) -> None:
    clips: dict = data["clips"]
    same_file: dict[str, str] = {}

    for key, entry in clips.items():
        if not isinstance(entry, dict):
            raise RuntimeError(f"{key}: entry must be an object.")

        display = str(entry.get("display", "")).strip()
        speech = str(entry.get("speech", "")).strip()
        synthesis = str(entry.get("synthesis", speech)).strip()
        file_path = str(entry.get("file", "")).strip()
        category = str(entry.get("category", "")).strip()

        if not all((display, speech, synthesis, file_path, category)):
            raise RuntimeError(f"{key}: missing required manifest field.")

        if normalize_semantic_text(display) != normalize_semantic_text(speech):
            raise RuntimeError(
                f"{key}: visible text and spoken text differ semantically: "
                f"{display!r} != {speech!r}"
            )

        previous_speech = same_file.get(file_path)
        if previous_speech is not None and previous_speech != speech:
            raise RuntimeError(
                f"{key}: file {file_path} is shared by entries with different speech."
            )
        same_file[file_path] = speech


def missing_files(data: dict) -> list[Path]:
    paths = {
        project_path_to_local(str(entry["file"]))
        for entry in data["clips"].values()
    }
    return sorted(path for path in paths if not path.is_file())


def category_instructions(data: dict, category: str) -> str:
    base = str(data["profile"].get("base_instructions", "")).strip()
    category_text = str(data.get("category_instructions", {}).get(category, "")).strip()
    return " ".join(part for part in (base, category_text) if part)


def create_speech(
    *,
    api_key: str,
    model: str,
    voice: str,
    text: str,
    instructions: str,
    response_format: str,
    speed: float,
    attempts: int = 5,
) -> bytes:
    payload = json.dumps(
        {
            "model": model,
            "voice": voice,
            "input": text,
            "instructions": instructions,
            "response_format": response_format,
            "speed": speed,
        },
        ensure_ascii=False,
    ).encode("utf-8")

    request = urllib.request.Request(
        API_URL,
        data=payload,
        method="POST",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "User-Agent": "Zoo-Game-Marin-Voice-Generator/1.0",
        },
    )

    for attempt in range(1, attempts + 1):
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                return response.read()
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="replace")
            if exc.code in (429, 500, 502, 503, 504) and attempt < attempts:
                wait = min(2 ** attempt, 20)
                print(f"API returned HTTP {exc.code}; retrying in {wait}s...")
                time.sleep(wait)
                continue
            raise RuntimeError(f"OpenAI API HTTP {exc.code}: {body}") from exc
        except urllib.error.URLError as exc:
            if attempt < attempts:
                wait = min(2 ** attempt, 20)
                print(f"Network error; retrying in {wait}s: {exc}")
                time.sleep(wait)
                continue
            raise RuntimeError(f"Network error while generating speech: {exc}") from exc

    raise RuntimeError("Speech generation failed after all retries.")


def generate(data: dict, force: bool) -> None:
    api_key = os.getenv("OPENAI_API_KEY", "").strip()
    if not api_key:
        raise RuntimeError(
            "OPENAI_API_KEY is not set. Do not paste the key into the project or chat; "
            "set it as an environment variable or GitHub Actions secret."
        )

    profile = data["profile"]
    model = str(profile["model"])
    voice = str(profile["voice"])
    response_format = str(profile.get("response_format", "mp3"))
    speed = float(profile.get("speed", 1.0))

    jobs: dict[str, dict] = {}
    for key, entry in data["clips"].items():
        path = str(entry["file"])
        jobs.setdefault(path, {"key": key, "entry": entry})

    generated = 0
    skipped = 0

    for index, (project_path, job) in enumerate(sorted(jobs.items()), start=1):
        entry = job["entry"]
        local_path = project_path_to_local(project_path)

        if local_path.exists() and not force:
            print(f"[{index}/{len(jobs)}] KEEP  {local_path.relative_to(ROOT)}")
            skipped += 1
            continue

        local_path.parent.mkdir(parents=True, exist_ok=True)
        category = str(entry["category"])
        synthesis_text = str(entry.get("synthesis", entry["speech"]))

        print(
            f"[{index}/{len(jobs)}] GEN   {local_path.relative_to(ROOT)} "
            f"<- {entry['speech']}"
        )

        audio_bytes = create_speech(
            api_key=api_key,
            model=model,
            voice=voice,
            text=synthesis_text,
            instructions=category_instructions(data, category),
            response_format=response_format,
            speed=speed,
        )

        temp_path = local_path.with_suffix(local_path.suffix + ".tmp")
        temp_path.write_bytes(audio_bytes)
        temp_path.replace(local_path)
        generated += 1
        time.sleep(0.12)

    print(f"Done. Generated: {generated}; kept: {skipped}; unique clips: {len(jobs)}.")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--force",
        action="store_true",
        help="Regenerate and overwrite every existing Marin clip.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Validate manifest and report missing Marin audio files without API calls.",
    )
    args = parser.parse_args()

    data = load_manifest()
    validate_manifest(data)

    if args.check:
        missing = missing_files(data)
        if missing:
            print(f"Manifest is valid, but {len(missing)} audio files are missing:")
            for path in missing:
                print(f" - {path.relative_to(ROOT)}")
            return 2
        print(
            f"Voice pack OK: {len(data['clips'])} semantic entries, "
            f"{len({entry['file'] for entry in data['clips'].values()})} unique audio files."
        )
        return 0

    generate(data, args.force)

    missing = missing_files(data)
    if missing:
        print(f"ERROR: generation finished with {len(missing)} files still missing.")
        return 3

    print("Complete Marin voice pack is present.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
