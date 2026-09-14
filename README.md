# Zoo Game — Zoológico das Sílabas

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

A versão final usa uma única identidade de voz para todo o produto: **OpenAI Marin**.

O arquivo `audio/marin/manifest.json` é a fonte da verdade para cada conteúdo falado. Ele registra:

- texto exibido;
- texto falado;
- texto usado na síntese;
- arquivo de áudio;
- categoria de entonação.

O pacote Marin é ativado de forma **all-or-nothing**: o jogo só passa para Marin quando todos os arquivos exigidos pelo manifesto estiverem presentes. Isso impede uma versão parcialmente migrada de misturar narradores.

A geração é reproduzível com:

```bash
python tools/generate_marin_audio.py --force
python tools/generate_marin_audio.py --check
```

É necessário definir `OPENAI_API_KEY` no ambiente. A chave nunca deve ser adicionada ao código ou ao repositório.

Também existe o workflow manual **Generate Marin Voice Pack**, que usa o secret `OPENAI_API_KEY` do GitHub Actions para gerar e versionar o pacote completo.

Consulte `VOICE_AUDIT.md` para o contrato completo de texto ↔ áudio e `AUDIO_CHECKLIST.md` para o procedimento de geração.

## Tecnologias

- Godot Engine 4.6
- GDScript
- OpenAI Text-to-Speech para a biblioteca final de voz
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
│   └── generate_marin_audio.py
├── VOICE_AUDIT.md
├── AUDIO_CHECKLIST.md
├── project.godot
└── README.md
```

## Executando o projeto

1. Instale o Godot 4.6.
2. Clone o repositório.
3. Abra `project.godot` no editor.
4. Aguarde a importação dos recursos.
5. Execute o projeto com **F6/F5**.

A branch de desenvolvimento também é validada pelo GitHub Actions com importação headless e exportação Web no Godot 4.6.

## Author

**Danilo Augusto Salvego dos Santos**

GitHub: [AugustoSalvego](https://github.com/AugustoSalvego)
