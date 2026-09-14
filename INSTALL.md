# Instalação e teste — Zoológico das Sílabas

## 1. Atualizar a branch de desenvolvimento

```powershell
git switch fix/preserve-original-polish
git pull origin fix/preserve-original-polish
```

## 2. Abrir no Godot

Use Godot 4.6, abra `project.godot`, aguarde a importação dos recursos e execute o projeto.

O jogo permanece funcional enquanto o pacote Marin ainda não foi gerado. Nessa fase, o gerenciador de áudio entra automaticamente em modo de compatibilidade. A migração final para Marin só é ativada quando o conjunto inteiro estiver presente.

## 3. Gerar o pacote final Marin

O arquivo `audio/marin/manifest.json` define todas as falas e deve ser tratado como fonte da verdade.

### Opção A — localmente

Defina sua chave como variável de ambiente. Nunca coloque a chave em arquivo versionado.

PowerShell:

```powershell
$env:OPENAI_API_KEY="SUA_CHAVE"
python tools/generate_marin_audio.py --force
python tools/generate_marin_audio.py --check
```

Quando `--check` concluir sem arquivos ausentes, o Godot usará Marin automaticamente na próxima execução.

### Opção B — GitHub Actions

1. No repositório, configure um secret de Actions chamado `OPENAI_API_KEY`.
2. Abra **Actions**.
3. Escolha **Generate Marin Voice Pack**.
4. Selecione a branch `fix/preserve-original-polish`.
5. Execute o workflow manualmente.
6. Ao concluir, faça `git pull` novamente.

O workflow gera o pacote inteiro e faz commit dos arquivos de áudio na branch selecionada.

## 4. Teste funcional obrigatório

Teste o fluxo completo, sem pular etapas:

- Menu → Jogar.
- Menu → Como jogar.
- Tutorial completo, incluindo uma resposta errada e uma correta.
- Clique/toque no animal durante tutorial e jogo.
- Todas as sete fases.
- Todas as sílabas possíveis ao menos uma vez.
- Repetir áudio.
- Abrir e ajustar volume.
- Como jogar a partir da partida.
- Voltar ao menu a partir da partida.
- Tela final.
- Jogar de novo.
- Voltar ao menu na tela final.

Em cada estado, confira que o texto visível representa exatamente o conteúdo falado. A referência completa está em `VOICE_AUDIT.md`.

## 5. Validação automática

Pull requests executam a importação do projeto e a exportação Web com Godot 4.6. Uma alteração só deve ser considerada tecnicamente pronta depois que esse workflow concluir com sucesso.
