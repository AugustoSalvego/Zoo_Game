# Marin audio checklist

The final Zoo-Game audio is defined by `audio/marin/manifest.json`.

## Why this exists

The project previously mixed remote NinoEdu/Ligue-as-Sílabas recordings, locally generated words,
system TTS, and interface phrases. That made narrator, pacing, volume, and sometimes wording change
between screens.

The final target is one narrator for the entire game: **OpenAI Marin**.

## Required coverage

The manifest contains every spoken semantic element used by the current game:

- menu title and menu buttons;
- top-bar controls;
- complete tutorial narration;
- correct/wrong feedback;
- final-screen title, completion message and actions;
- all seven animal names;
- all ten syllables used by the current seven phases.

The current manifest has 36 semantic entries and 34 unique audio files because identical phrases
such as “Como jogar” and “Voltar ao menu” intentionally reuse the same recording.

## Generate locally

Do not paste an API key into source code or chat.

PowerShell:

```powershell
$env:OPENAI_API_KEY="YOUR_KEY"
python tools/generate_marin_audio.py --force
python tools/generate_marin_audio.py --check
```

The generator uses the model, voice, speed, wording and style directly from the manifest.

## Generate with GitHub Actions

Add a repository Actions secret named `OPENAI_API_KEY`, select the desired branch in GitHub Actions,
and run **Generate Marin Voice Pack** manually. The workflow generates the complete set, validates it,
commits the MP3 assets, and pushes them back to the selected branch.

## All-or-nothing activation

The Godot audio manager validates the Marin pack on startup. Marin is used only when every required
manifest file exists. This prevents a partially generated pack from mixing Marin with another narrator.

When the complete pack is present, all words, syllables, instructions and interface speech are loaded
locally from the repository. No network request is needed during gameplay.
