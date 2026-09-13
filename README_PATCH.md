# Zoo Game — revisão de acessibilidade e áudio

Esta branch preserva a identidade visual original do Zoológico das Sílabas e corrige o fluxo para uso educacional inclusivo.

## Implementado

- tutorial visual mostrado automaticamente na primeira execução;
- botão **Como jogar** no menu;
- opção para pular e repetir conteúdo;
- animal contido corretamente no painel;
- cursor-guia com sombra e posição fora do texto da sílaba;
- clique/toque no animal para ouvir seu nome;
- sílabas narradas somente ao clicar/tocar, sem duplicação por hover;
- controle de volume persistente;
- progresso visual das sete fases;
- resposta errada sem embaralhar novamente as opções;
- estilos de botão preservados durante acerto/erro;
- tela final com confetes, jogar novamente e voltar ao menu;
- layout 1920×1080 responsivo em landscape;
- importação/exportação Web validada com Godot 4.6;
- gerenciador de áudio persistente entre cenas;
- contrato central de texto ↔ fala em `audio/marin/manifest.json`;
- pacote final planejado para uma única voz OpenAI Marin;
- ativação all-or-nothing do pacote Marin para impedir mistura de narradores;
- gerador reproduzível em `tools/generate_marin_audio.py`;
- workflow manual para gerar o pacote completo com GitHub Actions.

## Regra editorial de áudio

Nenhuma mensagem de estado pode dizer uma coisa na tela e outra no áudio. O manifesto centraliza o texto exibido e a fala correspondente. Quando uma frase muda, ela deve ser alterada primeiro no manifesto e o pacote de voz inteiro deve ser regenerado.

## Estado da migração Marin

A estrutura de runtime está pronta para Marin, mas os arquivos finais só podem ser sintetizados quando uma `OPENAI_API_KEY` autorizada estiver disponível. Até o pacote estar 100% presente, o projeto mantém os áudios anteriores apenas como compatibilidade temporária para não deixar a branch de teste muda.

Depois que o pacote Marin for gerado e validado, os assets e caminhos de compatibilidade antigos podem ser removidos em uma etapa final de limpeza.
