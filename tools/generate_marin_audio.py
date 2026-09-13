#!/usr/bin/env python3
"""Generate the complete Zoo-Game voice pack with free local Kokoro TTS.

Kokoro runs locally in the GitHub Actions runner, requires no API key and
generates every clip with the same Brazilian Portuguese voice (pm_alex).

Usage:
    python tools/generate_marin_audio.py --check
    python tools/generate_marin_audio.py
    python tools/generate_marin_audio.py --force
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
import tempfile

import numpy as np
import soundfile as sf
from kokoro import KPipeline

ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "audio" / "marin" / "manifest.json"
SAMPLE_RATE = 24000
LANG_CODE = "p"
VOICE = "pm_alex"
DEFAULT_SPEED = 0.90
SYLLABLE_SPEED = 0.83


def load_manifest() -> dict:
    with MANIFEST_PATH.open("r", encoding="utf-8") as handle:
        data = json.load(handle)

    if data.get("schema_version") != 1:
        raise RuntimeError("Unsupported voice manifest schema_version.")

    clips = data.get("clips")
    if not isinstance(clips, dict) or not clips:
        raise RuntimeError("Voice manifest has no clips.")

    data["profile"] = {
        "provider": "Kokoro",
        "model": "hexgrad/Kokoro-82M",
        "voice": VOICE,
        "language": "pt-BR",
        "response_format": "mp3",
        "speed": DEFAULT_SPEED,
        "license": "Apache-2.0",
        "generation": "local/offline"
    }
    return data


def save_manifest(data: dict) -> None:
    with MANIFEST_PATH.open("w", encoding="utf-8") as handle:
        json.dump(data, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


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


def synthesize_to_mp3(
    pipeline: KPipeline,
    text: str,
    output_path: Path,
    speed: float,
) -> None:
    chunks = []
    for result in pipeline(text, voice=VOICE, speed=speed):
        audio = result.audio
        if audio is None:
            continue
        if hasattr(audio, "detach"):
            audio = audio.detach().cpu().numpy()
        chunks.append(np.asarray(audio, dtype=np.float32))

    if not chunks:
        raise RuntimeError(f"Kokoro returned no audio for: {text!r}")

    combined = np.concatenate(chunks)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as temp_dir:
        wav_path = Path(temp_dir) / "clip.wav"
        sf.write(wav_path, combined, SAMPLE_RATE, subtype="PCM_16")
        subprocess.run(
            [
                "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
                "-i", str(wav_path),
                "-ar", str(SAMPLE_RATE),
                "-ac", "1",
                "-codec:a", "libmp3lame",
                "-b:a", "96k",
                str(output_path),
            ],
            check=True,
        )


def generate(data: dict, force: bool) -> None:
    speed = float(data.get("profile", {}).get("speed", DEFAULT_SPEED))
    pipeline = KPipeline(lang_code=LANG_CODE)

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

        synthesis_text = str(entry.get("synthesis", entry["speech"])).strip()
        category = str(entry.get("category", "")).strip()
        clip_speed = SYLLABLE_SPEED if category == "syllable" else speed
        print(
            f"[{index}/{len(jobs)}] GEN   {local_path.relative_to(ROOT)} "
            f"<- {entry['speech']} @ {clip_speed:.2f}x"
        )
        synthesize_to_mp3(pipeline, synthesis_text, local_path, clip_speed)
        generated += 1

    print(
        f"Done. Generated: {generated}; kept: {skipped}; "
        f"unique clips: {len(jobs)}; voice: {VOICE}."
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--force",
        action="store_true",
        help="Regenerate and overwrite every existing voice clip.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Validate manifest and report missing audio files.",
    )
    args = parser.parse_args()

    data = load_manifest()
    validate_manifest(data)
    save_manifest(data)

    if args.check:
        missing = missing_files(data)
        if missing:
            print(f"Manifest is valid, but {len(missing)} audio files are missing:")
            for path in missing:
                print(f" - {path.relative_to(ROOT)}")
            return 2
        print(
            f"Voice pack OK: {len(data['clips'])} semantic entries, "
            f"{len({entry['file'] for entry in data['clips'].values()})} unique audio files, "
            f"voice {VOICE}."
        )
        return 0

    generate(data, args.force)

    missing = missing_files(data)
    if missing:
        print(f"ERROR: generation finished with {len(missing)} files still missing.")
        return 3

    print("Complete free Kokoro voice pack is present.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
