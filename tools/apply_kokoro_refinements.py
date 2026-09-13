#!/usr/bin/env python3
"""Apply the approved Kokoro pronunciation and pacing refinements.

This script is intentionally idempotent so the voice-pack workflow can run it
before every regeneration without accumulating duplicate timers or edits.
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "audio" / "marin" / "manifest.json"
GENERATOR = ROOT / "tools" / "generate_marin_audio.py"
TUTORIAL = ROOT / "scripts" / "tutorial.gd"
GAME = ROOT / "scripts" / "jogo.gd"

SYLLABLE_SYNTHESIS = {
    "syllable_ca": "cá.",
    "syllable_ba": "bá.",
    "syllable_pa": "pá.",
    "syllable_ga": "gá.",
    "syllable_ma": "má.",
    "syllable_ta": "tá.",
    "syllable_la": "lá.",
    "syllable_sa": "sá.",
    "syllable_ra": "rá.",
    "syllable_fa": "fá.",
}


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if new in text:
        return text
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


def patch_manifest() -> None:
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    data["profile"]["speed"] = 0.90
    data["category_instructions"]["syllable"] = (
        "Pronuncie somente a sílaba como uma unidade sonora em português brasileiro, "
        "com a vogal A aberta e clara; não soletre as letras."
    )
    data["clips"]["tutorial_choose_ca"]["synthesis"] = "Escolha a sílaba cá."

    for key, synthesis in SYLLABLE_SYNTHESIS.items():
        data["clips"][key]["synthesis"] = synthesis

    MANIFEST.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def patch_generator() -> None:
    text = GENERATOR.read_text(encoding="utf-8")

    text = replace_once(
        text,
        "DEFAULT_SPEED = 0.92\n",
        "DEFAULT_SPEED = 0.90\nSYLLABLE_SPEED = 0.83\n",
        "generator speed constants",
    )

    text = replace_once(
        text,
        '        synthesis_text = str(entry.get("synthesis", entry["speech"])).strip()\n'
        '        print(\n'
        '            f"[{index}/{len(jobs)}] GEN   {local_path.relative_to(ROOT)} "\n'
        '            f"<- {entry[\'speech\']}"\n'
        '        )\n'
        '        synthesize_to_mp3(pipeline, synthesis_text, local_path, speed)\n',
        '        synthesis_text = str(entry.get("synthesis", entry["speech"])).strip()\n'
        '        category = str(entry.get("category", "")).strip()\n'
        '        clip_speed = SYLLABLE_SPEED if category == "syllable" else speed\n'
        '        print(\n'
        '            f"[{index}/{len(jobs)}] GEN   {local_path.relative_to(ROOT)} "\n'
        '            f"<- {entry[\'speech\']} @ {clip_speed:.2f}x"\n'
        '        )\n'
        '        synthesize_to_mp3(pipeline, synthesis_text, local_path, clip_speed)\n',
        "category-specific synthesis speed",
    )

    GENERATOR.write_text(text, encoding="utf-8")


def patch_tutorial() -> None:
    text = TUTORIAL.read_text(encoding="utf-8")

    text = replace_once(
        text,
        '\tawait audio.play_word_and_wait("CACHORRO", 1.0)\n\ttutorial_narrating = false\n',
        '\tawait audio.play_word_and_wait("CACHORRO", 1.0)\n\tawait get_tree().create_timer(0.30).timeout\n\ttutorial_narrating = false\n',
        "tutorial animal breathing room",
    )

    text = replace_once(
        text,
        '\tawait audio.speak_and_wait(key, fallback_seconds)\n\ttutorial_narrating = false\n',
        '\tawait audio.speak_and_wait(key, fallback_seconds)\n\tawait get_tree().create_timer(0.30).timeout\n\ttutorial_narrating = false\n',
        "tutorial narration breathing room",
    )

    TUTORIAL.write_text(text, encoding="utf-8")


def patch_game() -> None:
    text = GAME.read_text(encoding="utf-8")

    text = replace_once(
        text,
        '\tinstruction_label.text = audio.get_word_display(animal)\n'
        '\tawait audio.play_word_and_wait(animal, 1.0)\n\n'
        '\tif indice_fase != fase_atual or id != anuncio_id:\n',
        '\tinstruction_label.text = audio.get_word_display(animal)\n'
        '\tawait audio.play_word_and_wait(animal, 1.0)\n'
        '\tawait get_tree().create_timer(0.30).timeout\n\n'
        '\tif indice_fase != fase_atual or id != anuncio_id:\n',
        "phase introduction breathing room",
    )

    text = replace_once(
        text,
        '\t\tawait get_tree().create_timer(0.35).timeout\n',
        '\t\tawait get_tree().create_timer(0.65).timeout\n',
        "correct-answer pacing",
    )

    text = replace_once(
        text,
        '\tawait get_tree().create_timer(0.20).timeout\n',
        '\tawait get_tree().create_timer(0.45).timeout\n',
        "retry pacing",
    )

    text = replace_once(
        text,
        '\t\tawait audio.speak_and_wait("final_title", 0.8)\n'
        '\t\tawait audio.speak_and_wait("final_complete", 2.0)\n',
        '\t\tawait audio.speak_and_wait("final_title", 0.8)\n'
        '\t\tawait get_tree().create_timer(0.30).timeout\n'
        '\t\tawait audio.speak_and_wait("final_complete", 2.0)\n',
        "final-screen breathing room",
    )

    GAME.write_text(text, encoding="utf-8")


def main() -> None:
    patch_manifest()
    patch_generator()
    patch_tutorial()
    patch_game()
    print("Kokoro pronunciation and pacing refinements applied.")


if __name__ == "__main__":
    main()
