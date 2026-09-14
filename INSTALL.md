# Instalação e teste — Edição de Apresentação

Versão: **v1.1.0-rc.1**. Esta é uma versão candidata, ainda sujeita a ajustes.

## Executar o jogo

1. Clone o repositório ou atualize sua cópia da branch `main`.
2. Abra `project.godot` no Godot **4.7.2**.
3. Aguarde a importação dos recursos.
4. Pressione **F5** para executar o projeto a partir do menu.

Os 34 MP3 da voz brasileira `pt-BR-FranciscaNeural` já estão versionados. Não é necessário gerar os áudios novamente para jogar.

## Gerar áudios com Edge TTS

Requer Python 3.14 e internet. Execute os comandos na raiz do projeto:

```powershell
python -m pip install --upgrade edge-tts
python tools/generate_edge_tts_audio.py --test
```

Ouça as cinco amostras em `audio_test/`. O modo de teste não altera o pacote do jogo.

Para substituir todos os MP3 definidos em `audio/marin/manifest.json`:

```powershell
python tools/generate_edge_tts_audio.py
```

O script cria uma cópia completa de `audio/marin/` em `audio/marin_backup/` antes de substituir os áudios. Um backup existente é preservado. O manifest e os nomes dos arquivos permanecem intactos; arquivos compartilhados são gerados uma única vez.

As velocidades são `-18%` para sílabas, `-12%` para palavras e `-10%` para as demais categorias, com volume `+0%` e pitch `+0Hz`.

## Conferência antes da apresentação

- Menu: Jogar e Como jogar.
- Tutorial completo, incluindo uma resposta errada e uma correta.
- Clique/toque no animal e nas sílabas para ouvir a narração.
- Todas as sete fases.
- Repetir áudio e ajustar volume.
- Abrir Como jogar e voltar ao menu durante a partida.
- Tela final: jogar novamente e voltar ao menu.

Confira se as falas correspondem ao texto exibido e se o volume está adequado no equipamento da apresentação.

## Validação automática

```powershell
python tools/validate_voice_contract.py
```

O workflow **Export Godot Web** valida o contrato das falas, importa os recursos e exporta a versão Web com Godot 4.7.2. Em pushes para `main`, ele atualiza os arquivos `index.*` no repositório.
