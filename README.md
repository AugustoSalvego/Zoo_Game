# Zoo Game — Zoológico das Sílabas

**v1.1.0-rc.1 — Edição de Apresentação**

Versão candidata para apresentação, próxima da versão final e aberta a novos ajustes.

Jogo educacional desenvolvido em Godot para apoiar atividades de alfabetização por meio da associação entre animais, palavras e sílabas.

O projeto está sendo preparado para uso em contexto educacional inclusivo, incluindo crianças atendidas pela APAE. Por isso, clareza, previsibilidade, repetição sob demanda, feedback visual/sonoro coerente e funcionamento por mouse ou toque são requisitos do produto — não apenas detalhes de interface.

## Experiência do jogo

O jogador observa um animal e uma palavra incompleta e escolhe a sílaba que completa corretamente o nome. O jogo possui sete fases:

- Cachorro — CA
- Gato — GA
- Macaco — MA
- Baleia — BA
- Cavalo — CA
- Galinha — GA
- Tartaruga — TA

O tutorial é apresentado automaticamente na primeira execução e também pode ser aberto pelo botão **Como jogar**.

## Acessibilidade e interação

- interface em landscape 16:9, preparada para Web e dispositivos móveis;
- botões grandes e alto contraste;
- tutorial visual guiado;
- narração das instruções;
- clique/toque no animal para ouvir seu nome;
- clique/toque em cada sílaba para ouvi-la;
- sílabas não são narradas por hover, evitando repetição involuntária no desktop;
- feedback de acerto e nova tentativa com texto e áudio semanticamente equivalentes;
- botão para repetir conteúdo sonoro;
- controle de volume persistente;
- progresso visual das sete fases;
- tela final com opções para jogar novamente ou voltar ao menu.

## Sistema de voz

A Edição de Apresentação usa **Microsoft Edge TTS**, com a voz brasileira **pt-BR-FranciscaNeural**, em substituição ao pacote Kokoro.

O arquivo `audio/marin/manifest.json` é a fonte da verdade para cada conteúdo falado. Ele registra:

- texto exibido;
- texto falado;
- texto usado na síntese;
- arquivo de áudio;
- categoria de entonação.

Os 34 MP3 já estão incluídos no repositório e atendem às 36 entradas do manifest. A pasta mantém o nome histórico `audio/marin` para preservar os caminhos utilizados pelo Godot. O pacote completo é ativado somente quando todos os arquivos exigidos pelo manifesto estão presentes.

Para gerar novamente, use Python 3.14 e uma conexão com a internet:

```bash
python -m pip install --upgrade edge-tts
python tools/generate_edge_tts_audio.py --test
python tools/generate_edge_tts_audio.py
```

O modo `--test` gera cinco amostras em `audio_test/`, sem alterar os áudios reais. A execução normal cria `audio/marin_backup/` somente se ainda não existir e substitui cada MP3 uma única vez, usando o campo `synthesis`. O manifest permanece intacto. Backup e amostras são locais e não entram no Git.

As velocidades são `-18%` para sílabas, `-12%` para palavras e `-10%` para as demais categorias, com volume `+0%` e pitch `+0Hz`. A reprodução no jogo usa os arquivos locais; não exige Python nem acesso ao serviço TTS.

Consulte `INSTALL.md` para executar e verificar esta edição. Os scripts e workflows antigos de Kokoro permanecem como histórico; a geração desta edição usa `tools/generate_edge_tts_audio.py`.

## Tecnologias

- Godot Engine 4.7.2
- GDScript
- Microsoft Edge TTS para gerar a biblioteca de voz brasileira
- GitHub Actions para validação e exportação Web

## Estrutura principal

```text
Zoo_Game/
├── audio/
│   ├── marin/
│   │   └── manifest.json
│   ├── icons/
│   ├── voice/          # compatibilidade temporária durante a migração
│   └── words/          # compatibilidade temporária durante a migração
├── img/
├── scenes/
│   ├── Menu.tscn
│   ├── Tutorial.tscn
│   └── Jogo.tscn
├── scripts/
│   ├── accessibility_audio.gd
│   ├── menu.gd
│   ├── tutorial.gd
│   └── jogo.gd
├── tools/
│   ├── generate_edge_tts_audio.py
│   └── validate_voice_contract.py
├── VOICE_AUDIT.md
├── AUDIO_CHECKLIST.md
├── project.godot
└── README.md
```

## Executando o projeto

1. Instale o Godot 4.7.2.
2. Clone o repositório.
3. Abra `project.godot` no editor.
4. Aguarde a importação dos recursos.
5. Execute o projeto com **F5**.

A branch `main` também é validada pelo GitHub Actions com importação headless e exportação Web no Godot 4.7.2.

## Author

**Danilo Augusto Salvego dos Santos**

GitHub: [AugustoSalvego](https://github.com/AugustoSalvego)
