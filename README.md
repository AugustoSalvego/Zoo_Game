# Zoológico das Sílabas (Zoo_Game)

Jogo educacional desenvolvido em **Godot Engine 4.6** para apoiar a alfabetização inicial de crianças atendidas pela **APAE**, com foco em reconhecimento de sílabas.

## Objetivo

A criança vê um animal e uma palavra incompleta (ex.: `__CHORRO`) e escolhe, entre três alternativas, a sílaba que completa o nome do animal (ex.: `CA`).

Regra de design principal do projeto:

> **A criança deve conseguir entender e jogar sem precisar saber ler.**

Por isso, o texto é conteúdo educacional — não é a interface. A navegação depende de imagens, cores, ícones, animação e (quando os arquivos de áudio forem adicionados) narração.

## Público

Parte das crianças pode ainda não saber ler, ter dificuldade de atenção ou de compreensão, ou limitações motoras. Todas as decisões de UX seguem esses princípios:

- botões grandes e bem separados;
- sem cronômetro, sem sistema de vidas, sem "Game Over";
- erro nunca é punido — apenas "Tente outra vez";
- animações suaves, sem flashes ou movimentos rápidos;
- progresso mostrado visualmente (bolinhas), não só em números.

## Estrutura do projeto

```
Zoo_Game/
├── .github/workflows/
│   ├── export-web.yml       # build e publicação automática do Web (GitHub Pages)
│   └── export-android.yml   # build automático do APK Android (debug)
├── img/                     # artes dos animais e fundos
├── scenes/
│   ├── Menu.tscn
│   ├── Tutorial.tscn
│   └── Jogo.tscn
├── scripts/
│   ├── menu.gd
│   ├── tutorial.gd
│   ├── jogo.gd
│   └── accessibility_audio.gd   # camada central de áudio (voz/música/sfx)
├── audio/                   # (você cria) voice/, music/, sfx/ — ver AUDIO_CHECKLIST.md
├── project.godot
└── export_presets.cfg       # presets Web e Android
```

## Fluxo do jogo

```
MENU  →  TUTORIAL NARRADO (só na 1ª vez)  →  JOGO  →  TELA FINAL
              ↑______________________________________|
     "COMO JOGAR" no menu reabre o tutorial a qualquer momento
```

O tutorial não é uma tela de texto: ele demonstra a mecânica com o cachorro/`__CHORRO`, destaca visualmente os elementos, mostra uma mãozinha (👆) animada indicando onde clicar, e só libera o jogo real depois que a criança acerta. Pode ser pulado a qualquer momento pelo botão **PULAR**.

## Áudio

A arquitetura de áudio (`scripts/accessibility_audio.gd`) separa três canais — **voz**, **música** e **efeitos** — e **funciona normalmente mesmo sem nenhum arquivo de áudio presente** (usa apenas tempo de espera como substituto). Isso significa que você pode testar e publicar o jogo hoje, e adicionar as narrações depois sem tocar em nenhum script.

Formatos aceitos: `.ogg`, `.wav`, `.mp3` (nessa ordem de prioridade), dentro de `audio/voice/` ou `audio/music/`.

A lista completa de arquivos de narração necessários, com o texto exato a ser gravado, está em **[`AUDIO_CHECKLIST.md`](./AUDIO_CHECKLIST.md)**.

O hover (passar o mouse sobre um botão) usa `audio.play_hover_voice()`, que ignora repetições da mesma fala dentro de ~220ms — evita que o áudio seja cortado e reiniciado se o cursor "tremer" sobre o mesmo elemento.

## Métricas (preparado, não conectado a nenhuma plataforma)

`scripts/game_metrics.gd` conta acertos/erros por fase e a duração da sessão, e salva um resumo local em `user://zoo_metrics.json` ao completar o jogo. **Não envia nada para nenhum servidor** — não existe nenhuma integração com API da APAE/Nino Edu hoje. Quando houver um contrato oficial, o único lugar a implementar é a função `_reportar_para_plataforma()` (hoje vazia de propósito) dentro desse script.

## Como rodar localmente

1. Instale o **Godot Engine 4.6** (mesma versão usada no CI).
2. Clone o repositório e abra a pasta com o Godot.
3. Rode a cena `Menu.tscn` (ou aperte F5).

## Publicação Web (GitHub Pages)

O workflow `.github/workflows/export-web.yml` roda automaticamente a cada push em `main` (exceto quando o próprio commit só atualiza os arquivos `index.*` gerados) e também pode ser disparado manualmente em **Actions → Export Godot Web → Run workflow**. Ele baixa o Godot 4.6 headless, importa o projeto, exporta o preset **Web** e faz commit automático de `index.html/js/pck/wasm` na branch `main`, que é o que o GitHub Pages serve.

Para habilitar o GitHub Pages (se ainda não estiver): **Settings → Pages → Source: Deploy from a branch → `main` / `/ (root)`**.

## Gerando o APK Android

Foi adicionado um segundo preset de exportação (`export_presets.cfg`, preset "Android") e um workflow dedicado: `.github/workflows/export-android.yml`.

- Ele roda automaticamente quando `scenes/`, `scripts/`, `img/`, `project.godot` ou `export_presets.cfg` mudam, e também pode ser disparado manualmente em **Actions → Export Godot Android APK → Run workflow**.
- Gera um **APK de debug**, assinado com a keystore de debug padrão do Godot (suficiente para instalar e testar em qualquer aparelho Android com "Fontes desconhecidas" habilitado — não é o mesmo que publicar na Play Store).
- O APK final fica disponível como **artifact** do workflow (aba Actions → a execução → Artifacts → `zoo-silabas-debug-apk`), pronto para baixar e instalar.

### Para gerar um APK de release (assinado para distribuição/loja)

Isso depende de uma keystore própria, que **não deve ir para o repositório**. Passo a passo:

1. Gere uma keystore local: `keytool -genkey -v -keystore release.keystore -alias zoo-silabas -keyalg RSA -keysize 2048 -validity 10000`.
2. Cadastre o conteúdo da keystore (em base64) e as senhas como **Secrets** do repositório (Settings → Secrets and variables → Actions).
3. Me avise e eu adapto o workflow para decodificar a keystore, preencher `keystore/release_*` no `export_presets.cfg` via variável de ambiente, e rodar `--export-release "Android" ...` em vez de `--export-debug`.

Não fiz isso agora porque nenhuma keystore de release existe no repositório — criá-la é uma decisão sua (e a chave privada nunca deve ser compartilhada comigo nem versionada).

## Testando

Veja o passo a passo completo de teste manual no relatório de entrega (mensagem do Claude) ou repita o fluxo: Menu → Como jogar → Tutorial → Pular tutorial → Jogar → acertar → errar → repetir instrução → volume → voltar → completar todas as fases → jogar novamente → voltar ao menu.

## Autor

**Danilo Augusto Salvego dos Santos**
GitHub: [AugustoSalvego](https://github.com/AugustoSalvego)
