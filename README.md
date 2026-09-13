# Zoológico das Sílabas

Jogo educacional em Godot 4.6 voltado à alfabetização inicial. A criança observa um animal, identifica a sílaba inicial que está faltando no nome e recebe feedback visual sem punição por erro.

## Estado atual

A versão atual foi reconstruída para substituir o protótipo anterior e priorizar jogabilidade, acessibilidade e estabilidade no navegador.

### Fluxo

1. Menu inicial simples e com botões grandes.
2. Tutorial interativo na primeira execução.
3. Sete animais em ordem aleatória por partida.
4. Três opções de sílaba por rodada.
5. Feedback imediato; após duas tentativas, a resposta correta recebe destaque visual.
6. A criança controla o ritmo pelo botão **Próximo animal**.
7. Tela de conclusão com opção de jogar novamente ou voltar ao menu.

## Acessibilidade e usabilidade

- Botões grandes e alto contraste.
- Interface responsiva baseada em `Container`, sem posições absolutas fixas.
- Mouse, toque e teclado (`1`, `2`, `3` para responder; `Enter` para avançar).
- Erros não removem progresso e não geram pontuação negativa.
- Som pode ser ligado/desligado e a preferência é salva em `user://zoo_settings.cfg`.
- O sistema de áudio é opcional: a ausência de gravações nunca impede o jogo de funcionar.

## Conteúdo e NinoEdu

O conteúdo local em `scripts/game_data.gd` segue o núcleo do contrato usado pelo NinoEdu em `/api/recursos/silabas`:

- `palavra`
- `silaba`
- `complemento_silaba`
- `imagem`

Isso mantém o jogo funcionando offline e deixa a estrutura pronta para substituir o banco local por conteúdo vindo da API do NinoEdu futuramente.

O adaptador de áudio procura gravações locais em `audio/syllables/`, mas o projeto não incorpora automaticamente assets de terceiros. Assim, gravações próprias/licenciadas podem ser adicionadas posteriormente sem alterar a lógica do jogo.

## Executar

Abra o projeto com **Godot 4.6.x** e pressione `F5` para executar a cena principal.

O projeto usa o renderizador **Compatibility**, necessário para exportação Web no Godot 4.

## Exportação Web

O preset `Web` exporta para `index.html`. O workflow `.github/workflows/export-web.yml` valida a exportação em pull requests e, após alterações no `main`, recompila os arquivos Web publicados.

## Estrutura principal

```text
scenes/
  Menu.tscn
  Tutorial.tscn
  Jogo.tscn
scripts/
  menu.gd
  tutorial.gd
  jogo.gd
  game_data.gd
  accessibility_audio.gd
img/
  ...
audio/
  syllables/   # opcional: gravações próprias/licenciadas
```

## Author

Danilo Augusto Salvego dos Santos  
GitHub: https://github.com/AugustoSalvego
