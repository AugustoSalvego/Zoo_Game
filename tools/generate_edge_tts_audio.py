#!/usr/bin/env python3
"""Gera MP3 com Microsoft Edge TTS (requer internet e Python 3.14).

Instalacao:
    python -m pip install --upgrade edge-tts

Uso, a partir da raiz do projeto:
    python tools/generate_edge_tts_audio.py --test
    python tools/generate_edge_tts_audio.py

O modo normal substitui os MP3 indicados no manifest, preservando uma copia
de audio/marin em audio/marin_backup na primeira execucao. O manifest nunca
e modificado. O modo --test grava apenas cinco amostras em audio_test.
Todos os caminhos sao relativos ao projeto, independentemente do terminal.
"""

from __future__ import annotations

import argparse
import asyncio
from dataclasses import dataclass
import json
from pathlib import Path
import shutil
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
AUDIO_DIR = ROOT / "audio" / "marin"
MANIFEST_PATH = AUDIO_DIR / "manifest.json"
BACKUP_DIR = ROOT / "audio" / "marin_backup"
TEST_DIR = ROOT / "audio_test"

VOICE = "pt-BR-FranciscaNeural"
RATES = {"syllable": "-18%", "word": "-12%"}
DEFAULT_RATE = "-10%"
VOLUME = "+0%"
PITCH = "+0Hz"


@dataclass(frozen=True)
class Clip:
    path: Path
    text: str
    rate: str


def load_clips() -> list[Clip]:
    """Valida todo o manifest antes de criar backup ou substituir arquivos."""
    with MANIFEST_PATH.open(encoding="utf-8-sig") as handle:
        manifest = json.load(handle)

    entries = manifest.get("clips")
    if not isinstance(entries, dict) or not entries:
        raise ValueError("O manifest deve conter um objeto 'clips' nao vazio.")

    unique: dict[Path, Clip] = {}
    for key, entry in entries.items():
        if not isinstance(entry, dict):
            raise ValueError(f"{key}: clip invalido.")
        text = entry.get("synthesis")
        filename = entry.get("file")
        category = entry.get("category", "")
        if not isinstance(text, str) or not text.strip():
            raise ValueError(f"{key}: campo 'synthesis' ausente ou vazio.")
        if not isinstance(filename, str) or not filename:
            raise ValueError(f"{key}: campo 'file' ausente ou vazio.")
        if not isinstance(category, str):
            raise ValueError(f"{key}: categoria invalida.")

        # Os caminhos res:// do Godot partem da raiz do projeto.
        path = (ROOT / filename.removeprefix("res://")).resolve()
        if not path.is_relative_to(AUDIO_DIR.resolve()) or path.suffix.lower() != ".mp3":
            raise ValueError(f"{key}: o destino deve ser um MP3 em audio/marin: {filename}")

        clip = Clip(path, text, RATES.get(category, DEFAULT_RATE))
        previous = unique.get(path)
        if previous is not None and previous != clip:
            raise ValueError(
                f"{key}: arquivo compartilhado com texto ou velocidade diferente: {filename}"
            )
        unique[path] = clip

    return list(unique.values())


def test_clips() -> list[Clip]:
    """Amostras independentes do manifest e dos arquivos reais do jogo."""
    samples = (
        ("tutorial_welcome.mp3", "Vamos aprender a jogar!", "instruction"),
        ("word_cachorro.mp3", "Cachorro", "word"),
        ("syllable_ca.mp3", "cá", "syllable"),
        ("syllable_ga.mp3", "gá", "syllable"),
        ("syllable_ta.mp3", "tá", "syllable"),
    )
    return [
        Clip(TEST_DIR / filename, text, RATES.get(category, DEFAULT_RATE))
        for filename, text, category in samples
    ]


def ensure_backup() -> None:
    """Publica o backup apenas depois de concluir a copia inteira."""
    if BACKUP_DIR.is_dir():
        print(f"Backup existente preservado: {BACKUP_DIR}", flush=True)
        return
    if BACKUP_DIR.exists() or BACKUP_DIR.is_symlink():
        raise ValueError(f"O caminho de backup nao e uma pasta: {BACKUP_DIR}")

    print(f"Criando backup em: {BACKUP_DIR}", flush=True)
    # A pasta temporaria e irma do destino, permitindo renomear no Windows.
    # Se a copia falhar, nenhum backup incompleto fica no caminho definitivo.
    with tempfile.TemporaryDirectory(prefix=".marin_backup_", dir=BACKUP_DIR.parent) as temp:
        staged = Path(temp) / "marin_backup"
        shutil.copytree(AUDIO_DIR, staged)
        staged.rename(BACKUP_DIR)


async def generate(clips: list[Clip], test_mode: bool) -> None:
    try:
        import edge_tts
    except ImportError as exc:
        raise RuntimeError(
            "Instale a dependencia: python -m pip install --upgrade edge-tts"
        ) from exc

    generated = 0
    try:
        if not test_mode:
            ensure_backup()

        for index, clip in enumerate(clips, start=1):
            print(
                f"[{index}/{len(clips)}] {clip.path.relative_to(ROOT)}"
                f" | {clip.rate} | {clip.text}",
                flush=True,
            )
            clip.path.parent.mkdir(parents=True, exist_ok=True)
            # Fecha todos os handles antes de substituir o MP3 no Windows.
            # Uma falha na rede deixa o arquivo anterior intacto.
            with tempfile.TemporaryDirectory(prefix=".edge_tts_", dir=clip.path.parent) as temp:
                temporary_mp3 = Path(temp) / "clip.mp3"
                speech = edge_tts.Communicate(
                    text=clip.text,
                    voice=VOICE,
                    rate=clip.rate,
                    volume=VOLUME,
                    pitch=PITCH,
                )
                await speech.save(str(temporary_mp3))
                if temporary_mp3.stat().st_size == 0:
                    raise RuntimeError(f"Edge TTS retornou audio vazio: {clip.path.name}")
                temporary_mp3.replace(clip.path)
            generated += 1
    finally:
        print(f"Arquivos gerados: {generated}/{len(clips)}", flush=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--test",
        action="store_true",
        help="Gera apenas cinco amostras em audio_test, sem alterar os audios do jogo.",
    )
    args = parser.parse_args()

    try:
        clips = test_clips() if args.test else load_clips()
        asyncio.run(generate(clips, test_mode=args.test))
    except KeyboardInterrupt:
        print("\nGeracao interrompida.", file=sys.stderr)
        return 130
    except Exception as exc:
        print(f"Erro: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())