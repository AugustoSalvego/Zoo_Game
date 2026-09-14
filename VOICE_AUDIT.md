# Voice audit — Zoológico das Sílabas

This document defines the final audio contract for the APAE-oriented version of the game.

## Core rule

The game must never mix narrators. The Marin pack is activated only when **every required file**
listed in `audio/marin/manifest.json` exists. Until then, the legacy audio remains active as a
temporary compatibility fallback.

`audio/marin/manifest.json` is the single source of truth for:

- visible text;
- spoken text;
- synthesis input;
- audio file path;
- voice category.

The visible and spoken forms must be semantically identical. Capitalization and terminal punctuation
may differ only when needed for natural speech.

## Screen coverage

| Screen/state | Visible content | Required audio behavior |
| --- | --- | --- |
| Menu | Zoológico das Sílabas | Spoken once when the complete Marin pack is active |
| Menu | JOGAR | Speak “Jogar” when activated, then enter the game/tutorial |
| Menu | COMO JOGAR | Speak “Como jogar” when activated, then open the tutorial |
| Menu | Volume icon | Tooltip uses “Volume”; a matching Marin clip exists |
| Tutorial | Vamos aprender a jogar! | Text and narration use the same phrase |
| Tutorial | Olhe o animal. | Text and narration use the same phrase |
| Tutorial | Uma parte da palavra está faltando. | Text and narration use the same phrase |
| Tutorial | Escolha a sílaba CA. | Text and narration use the same phrase |
| Tutorial | CA / BA / PA | Syllable is spoken only on click/tap, never on hover |
| Tutorial | Você acertou! | Text and narration use the same phrase |
| Tutorial | Tente outra vez. | Text and narration use the same phrase |
| Tutorial | CACHORRO | Animal name is spoken with the same Marin voice |
| Tutorial | Sua vez! | Text and narration use the same phrase |
| Game | Animal name | Spoken at the start of the phase and on animal click/tap |
| Game | Syllable choices | Spoken only when the choice is activated |
| Game | Você acertou! | Text and narration use the same phrase |
| Game | Tente outra vez. | Text and narration use the same phrase |
| Game | No persistent instruction sentence | Avoids repetitive cognitive load after the tutorial |
| Final | PARABÉNS! | Dedicated matching audio |
| Final | Você completou o Zoológico das Sílabas! | Dedicated matching audio |
| Final | JOGAR DE NOVO | Speak before restarting |
| Final | VOLTAR AO MENU | Speak before leaving the final screen |
| Top controls | Voltar ao menu / Como jogar / Ouvir novamente / Volume | Tooltips use the same semantic wording as their audio |

## Interaction policy

Syllables and educational choices never speak on pointer hover. This avoids the desktop-only
“hover speaks, click speaks again” duplication and keeps mouse and touch behavior conceptually aligned.

Animal click/tap temporarily shows the same animal name that is being spoken, then restores the
previous instructional state.

Navigation actions that have visible text are spoken before the scene transition when practical, so
mobile users do not lose the label audio during a scene change.

## Voice profile

The complete pack uses:

- provider: OpenAI;
- model: `gpt-4o-mini-tts-2025-12-15`;
- voice: `marin`;
- locale: Brazilian Portuguese;
- format: MP3;
- global speed: 0.92;
- calm, warm, pedagogical delivery;
- clear syllable articulation without spelling letter names.

Do not hand-edit individual audio files with another narrator. If wording changes, update the manifest
first and regenerate the complete pack.
