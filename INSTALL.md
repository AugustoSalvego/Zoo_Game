# Como aplicar o patch APAE

1. Faça uma cópia da pasta atual do `Zoo_Game`.
2. Abra a pasta do projeto no computador.
3. Copie a pasta `scripts` deste patch para a raiz do projeto e permita substituir `menu.gd` e `jogo.gd`.
4. Copie a pasta `scenes` deste patch para a raiz do projeto e permita substituir `Jogo.tscn`. O arquivo `Tutorial.tscn` será adicionado.
5. Copie a pasta `audio` para a raiz do projeto.
6. Abra o projeto no Godot 4.6.
7. Aguarde a importação dos arquivos.
8. Execute o projeto.

## O que deve acontecer sem nenhum áudio
- Menu abre normalmente.
- O botão JOGAR leva ao tutorial na primeira execução.
- O botão COMO JOGAR abre o tutorial sempre.
- Tutorial demonstra o cachorro e espera o clique em CA.
- Depois do tutorial começa o jogo.
- Há botões de voltar, ajuda, repetir e volume.
- Há indicador visual de progresso.
- Resposta errada permite tentar novamente.
- Resposta correta avança.
- No final aparecem confetes e opções para jogar novamente ou voltar ao menu.

## Depois de testar sem áudio
Adicione os arquivos listados em `AUDIO_CHECKLIST.md` dentro de `audio/voice/`.

Não é necessário alterar o código quando os áudios forem adicionados: os scripts procuram automaticamente por `.ogg`, `.wav` ou `.mp3`.
