#!/usr/bin/env python3
"""Generate a small Kokoro voice audition pack for Zoo_Game.

The goal is to compare Brazilian Portuguese voices and end-of-word behavior
without touching the production narration pack. Generated files are written to
`audio/audition/` so they can be listened to side by side.
"""

from __future__ import annotations

from pathlib import Path
import subprocess
import tempfile

import numpy as np
import soundfile as sf
from kokoro import KPipeline

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "audio" / "audition"
SAMPLE_RATE = 24000
LANG_CODE = "p"

VOICES = ["pf_dora", "pm_alex", "pm_santa"]

# Keep this intentionally small. We want to identify whether the unwanted
# end-of-word sound comes from the voice, punctuation, or short utterances.
TESTS = [
    ("01_ca_plain", "ca", 0.92),
    ("02_ca_accent", "cá", 0.92),
    ("03_ca_accent_slow", "cá", 0.86),
    ("04_cachorro_plain", "Cachorro", 0.92),
    ("05_cachorro_period", "Cachorro.", 0.92),
    ("06_galinha_plain", "Galinha", 0.92),
    ("07_instruction", "Vamos aprender a jogar!", 0.92),
]


def write_mp3(audio: np.ndarray, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as temp_dir:
        wav = Path(temp_dir) / "clip.wav"
        sf.write(wav, audio, SAMPLE_RATE, subtype="PCM_16")
        subprocess.run(
            [
                "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
                "-i", str(wav),
                "-ar", str(SAMPLE_RATE),
                "-ac", "1",
                "-codec:a", "libmp3lame",
                "-b:a", "96k",
                str(path),
            ],
            check=True,
        )


def synthesize(pipeline: KPipeline, voice: str, text: str, speed: float) -> np.ndarray:
    chunks: list[np.ndarray] = []
    for result in pipeline(text, voice=voice, speed=speed):
        audio = result.audio
        if audio is None:
            continue
        if hasattr(audio, "detach"):
            audio = audio.detach().cpu().numpy()
        chunks.append(np.asarray(audio, dtype=np.float32))
    if not chunks:
        raise RuntimeError(f"No audio returned for {voice}: {text!r}")
    return np.concatenate(chunks)


def write_readme() -> None:
    lines = [
        "# Voice audition",
        "",
        "These files are diagnostic only and are not used by the game.",
        "",
        "Listen for three things: (1) no extra S/SH sound at the end, "
        "(2) a clearly open final A in CA, and (3) natural Brazilian Portuguese prosody.",
        "",
        "Folders:",
        "- `pf_dora`: current female pt-BR Kokoro voice",
        "- `pm_alex`: alternative male pt-BR Kokoro voice",
        "- `pm_santa`: alternative male pt-BR Kokoro voice",
        "",
        "Recommended order: 01, 02, 04, 05, 06, 07 in each folder.",
        "Compare `04_cachorro_plain.mp3` against `05_cachorro_period.mp3` to hear "
        "whether terminal punctuation is causing the unwanted end sound.",
    ]
    (OUT / "README.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    pipeline = KPipeline(lang_code=LANG_CODE)
    write_readme()

    for voice in VOICES:
        for filename, text, speed in TESTS:
            output = OUT / voice / f"{filename}.mp3"
            print(f"GEN {output.relative_to(ROOT)} <- {text!r} @ {speed:.2f}x")
            audio = synthesize(pipeline, voice, text, speed)
            write_mp3(audio, output)

    print(f"Voice audition complete: {len(VOICES) * len(TESTS)} MP3 files.")


if __name__ == "__main__":
    main()
