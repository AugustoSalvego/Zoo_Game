#!/usr/bin/env python3
"""Static validation for the Zoo-Game narration contract.

This check does not synthesize or play audio. It verifies that the project cannot
quietly drift back into mismatched visible/spoken text or incomplete voice
coverage.
"""

from __future__ import annotations

import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "audio" / "marin" / "manifest.json"
RUNTIME_SCRIPTS = [
    ROOT / "scripts" / "menu.gd",
    ROOT / "scripts" / "tutorial.gd",
    ROOT / "scripts" / "jogo.gd",
]
GAME_SCRIPT = ROOT / "scripts" / "jogo.gd"
TUTORIAL_SCRIPT = ROOT / "scripts" / "tutorial.gd"

REQUIRED_STATIC_KEYS = {
    "menu_title",
    "menu_play",
    "menu_how_to_play",
    "ui_volume",
    "ui_back_menu",
    "ui_help",
    "ui_skip",
    "ui_repeat",
    "tutorial_welcome",
    "tutorial_look_animal",
    "tutorial_word_missing",
    "tutorial_choose_ca",
    "feedback_correct",
    "feedback_try_again",
    "tutorial_your_turn",
    "final_title",
    "final_complete",
    "final_play_again",
    "final_back_menu",
}

AUDIO_CALL_PATTERN = re.compile(
    r"audio\.(?:play_voice|speak_and_wait|get_display_text)\(\s*\"([^\"]+)\""
)
ANIMAL_PATTERN = re.compile(r'\"animal\"\s*:\s*\"([^\"]+)\"')
SYLLABLE_PATTERN = re.compile(r'\"(?:silaba|opcoes)\"[^\n]*')
QUOTED_SYLLABLE_PATTERN = re.compile(r'\"([A-ZÁÉÍÓÚÂÊÔÃÕÇ]{1,3})\"')


def normalized(text: str) -> str:
    return " ".join(
        "".join(char for char in text.casefold() if char.isalnum() or char.isspace()).split()
    )


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def main() -> int:
    errors: list[str] = []

    try:
        data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"VOICE CONTRACT FAILED: cannot read manifest: {exc}", file=sys.stderr)
        return 1

    clips = data.get("clips")
    if not isinstance(clips, dict) or not clips:
        print("VOICE CONTRACT FAILED: manifest has no clips.", file=sys.stderr)
        return 1

    # 1. Every semantic entry is complete and what is displayed matches what is spoken.
    files_to_speech: dict[str, str] = {}
    for key, entry in clips.items():
        if not isinstance(entry, dict):
            fail(errors, f"{key}: manifest entry is not an object")
            continue

        for field in ("display", "speech", "synthesis", "file", "category"):
            if not str(entry.get(field, "")).strip():
                fail(errors, f"{key}: missing {field}")

        display = str(entry.get("display", ""))
        speech = str(entry.get("speech", ""))
        if normalized(display) != normalized(speech):
            fail(errors, f"{key}: display/speech mismatch: {display!r} != {speech!r}")

        audio_file = str(entry.get("file", ""))
        if audio_file:
            old_speech = files_to_speech.get(audio_file)
            if old_speech is not None and normalized(old_speech) != normalized(speech):
                fail(errors, f"{key}: {audio_file} is shared by different spoken phrases")
            files_to_speech[audio_file] = speech

    # 2. Mandatory screen/state phrases must remain represented.
    missing_static = sorted(REQUIRED_STATIC_KEYS - clips.keys())
    if missing_static:
        fail(errors, "missing required semantic keys: " + ", ".join(missing_static))

    # 3. Every literal audio/display key used by runtime UI scripts must exist.
    runtime_keys: set[str] = set()
    for script_path in RUNTIME_SCRIPTS:
        source = script_path.read_text(encoding="utf-8")
        runtime_keys.update(AUDIO_CALL_PATTERN.findall(source))

    missing_runtime = sorted(runtime_keys - clips.keys())
    if missing_runtime:
        fail(errors, "runtime references keys absent from manifest: " + ", ".join(missing_runtime))

    # 4. Every animal and every syllable used by the seven game phases must have a clip.
    game_source = GAME_SCRIPT.read_text(encoding="utf-8")
    animals = set(ANIMAL_PATTERN.findall(game_source))

    syllables: set[str] = set()
    for line in game_source.splitlines():
        if '"silaba"' in line or '"opcoes"' in line:
            for token in QUOTED_SYLLABLE_PATTERN.findall(line):
                if token not in {"animal", "imagem", "incompleto", "silaba", "opcoes"}:
                    syllables.add(token)

    if len(animals) != 7:
        fail(errors, f"expected 7 game animals, found {len(animals)}: {sorted(animals)}")

    for animal in sorted(animals):
        key = "word_" + animal.casefold()
        if key not in clips:
            fail(errors, f"game animal {animal} has no {key} clip")

    for syllable in sorted(syllables):
        key = "syllable_" + syllable.casefold()
        if key not in clips:
            fail(errors, f"game syllable {syllable} has no {key} clip")

    # 5. Accessibility interaction invariants requested for this project.
    tutorial_source = TUTORIAL_SCRIPT.read_text(encoding="utf-8")
    if "mouse_entered.connect(func(): audio.play_syllable" in tutorial_source:
        fail(errors, "tutorial reintroduced syllable speech on mouse hover")
    if "mouse_entered.connect(func(): audio.play_syllable" in game_source:
        fail(errors, "game reintroduced syllable speech on mouse hover")
    if "Escolha a sílaba que completa o nome." in game_source:
        fail(errors, "normal game reintroduced the repetitive instruction sentence")

    if errors:
        print("VOICE CONTRACT FAILED", file=sys.stderr)
        for error in errors:
            print(f" - {error}", file=sys.stderr)
        return 1

    print(
        "Voice contract OK: "
        f"{len(clips)} semantic entries, "
        f"{len(files_to_speech)} unique audio files, "
        f"{len(animals)} animals, "
        f"{len(syllables)} syllables, "
        f"{len(runtime_keys)} literal runtime keys."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
