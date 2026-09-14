# Como preparamos a voz e a versão de apresentação do Zoológico das Sílabas

Este tutorial explica a troca da narração do jogo, como repetir o processo no Windows e como organizamos a versão **v1.1.0-rc.1 — Edição de Apresentação**.

O jogo já existia em Godot e usava áudios gerados com Kokoro. Nesta etapa, substituímos esses áudios por uma voz brasileira do Microsoft Edge TTS. TTS significa transformar texto em fala. Nosso objetivo foi obter uma narração clara, com velocidades ajustadas para palavras e sílabas.

1. **Entender de onde vêm as falas**

   O arquivo [audio/marin/manifest.json](audio/marin/manifest.json) funciona como uma lista das falas do jogo. Cada entrada informa o texto e o arquivo que deve ser reproduzido.

   Por exemplo, a mensagem de boas-vindas do tutorial contém:

   ```json
   {
     "display": "Vamos aprender a jogar!",
     "speech": "Vamos aprender a jogar!",
     "synthesis": "Vamos aprender a jogar!",
     "file": "res://audio/marin/tutorial_welcome.mp3",
     "category": "instruction"
   }
   ```

   `display` representa o texto mostrado; `speech`, a fala prevista; `synthesis`, o texto enviado ao gerador; `file`, o destino do MP3; e `category`, o tipo de fala usado para escolher a velocidade.

   No Godot, `res://` significa a raiz do projeto. Portanto, o arquivo desse exemplo fica em `audio/marin/tutorial_welcome.mp3`.

   A pasta continua se chamando `marin` por compatibilidade com os caminhos existentes. Esse nome não identifica a voz atual. O bloco `profile` do manifest também mantém informações históricas do Kokoro; o novo script define sua própria voz e suas velocidades.

2. **Conhecer o script que criamos**

   Criamos [tools/generate_edge_tts_audio.py](tools/generate_edge_tts_audio.py), usando a biblioteca Python `edge_tts` e a voz `pt-BR-FranciscaNeural`.

   Ele lê o manifest automaticamente, usa exatamente o campo `synthesis` e grava cada MP3 no caminho indicado em `file`. A troca de voz preservou os nomes dos arquivos e o manifest, sem exigir mudanças nos scripts GDScript do jogo.

   As configurações usadas são:

   | Tipo de fala | Categoria no manifest | Velocidade |
   | --- | --- | --- |
   | Sílabas | `syllable` | `-18%` |
   | Palavras | `word` | `-12%` |
   | Instruções, botões e demais falas | Demais categorias | `-10%` |

   Esses valores reduzem a velocidade em relação à padrão da voz. O volume é `+0%` e o pitch, que controla a altura da voz, é `+0Hz`.

   Existem **36 entradas e 34 arquivos distintos**: algumas entradas compartilham o mesmo MP3. O script identifica esses casos e gera cada arquivo uma única vez por execução.

3. **Preparar o computador**

   Para repetir a geração, tenha uma cópia atualizada deste projeto, Python 3.14 e conexão com a internet. Para abrir o jogo, usamos Godot 4.7.2.

   Abra a pasta `Zoo_Game` no Explorador de Arquivos e abra um terminal PowerShell nessa pasta. Ela deve conter `project.godot` e as pastas `tools` e `audio`.

   Confira o Python e instale a biblioteca:

   ```powershell
   python --version
   python -m pip install --upgrade edge-tts
   ```

   Validamos a geração no Windows com **Python 3.14.3 e edge-tts 7.2.8**. Se o comando `python` não estiver disponível e o inicializador `py` estiver instalado, use `py -3.14` no lugar de `python` nos comandos.

   Quem só vai jogar com os MP3 prontos não precisa executar o gerador nem instalar a biblioteca Python.

4. **Testar a voz antes de trocar os áudios do jogo**

   Execute:

   ```powershell
   python tools/generate_edge_tts_audio.py --test
   ```

   O script cria cinco amostras na pasta `audio_test/`:

   | Arquivo | Texto enviado para geração |
   | --- | --- |
   | `tutorial_welcome.mp3` | Vamos aprender a jogar! |
   | `word_cachorro.mp3` | Cachorro |
   | `syllable_ca.mp3` | cá |
   | `syllable_ga.mp3` | gá |
   | `syllable_ta.mp3` | tá |

   Abra os MP3 e ouça a pronúncia e o ritmo. Preste atenção especialmente às sílabas isoladas. Os acentos desses testes são enviados como escritos; no modo completo, o texto vem do manifest.

   O modo de teste grava apenas as amostras, sem substituir os áudios reais nem criar o backup do pacote do jogo. Ao terminar com sucesso, mostra `Arquivos gerados: 5/5`.

5. **Gerar o pacote completo com backup automático**

   Depois de ouvir e aprovar os testes, execute:

   ```powershell
   python tools/generate_edge_tts_audio.py
   ```

   Primeiro, o script valida as entradas. Depois, copia toda a pasta `audio/marin/` para `audio/marin_backup/`, se esse backup ainda não existir. Um backup existente é preservado nas próximas execuções.

   A seguir, gera os MP3. No terminal, aparecem o caminho do arquivo, a velocidade e o texto de cada fala. O resultado esperado para o manifest atual é `Arquivos gerados: 34/34`.

   Cada áudio é salvo primeiro em um arquivo temporário e só substitui o anterior depois que a geração termina. Se houver uma falha, o MP3 que estava sendo gerado permanece com seu conteúdo anterior. Os arquivos concluídos antes da falha já terão sido substituídos: a proteção é por arquivo, sem desfazer automaticamente o lote inteiro.

   Para repetir após corrigir uma falha de conexão, execute novamente o mesmo comando. Ele gera novamente todos os 34 arquivos; não retoma apenas os que faltaram.

   Caso seja necessário voltar à voz anterior, feche o jogo e copie os MP3 de `audio/marin_backup/` para os mesmos locais em `audio/marin/`, substituindo os correspondentes. Preserve o backup e o manifest.

6. **Conferir o resultado dentro do jogo**

   Abra `project.godot` no Godot e aguarde a importação dos recursos. Se o editor já estiver aberto, volte a ele para que reconheça os MP3 atualizados.

   Pressione **F5** para iniciar o projeto pelo menu. **F6** executa apenas a cena que estiver aberta no editor.

   Percorra o menu, o tutorial, as sete fases e a tela final. Ouça os nomes dos animais, as sílabas, as instruções e os retornos de acerto e erro. Confira também os controles de repetir áudio e de volume.

   O jogo reproduz os arquivos gravados. Ele não chama o serviço Edge TTS durante a partida.

7. **Executar a verificação automática**

   No terminal, execute:

   ```powershell
   python tools/validate_voice_contract.py
   ```

   Na nossa verificação, o resultado foi `Voice contract OK`, com 36 entradas, 34 arquivos distintos, sete animais e dez sílabas.

   Esse verificador confere a relação entre o manifest e os scripts, incluindo falas obrigatórias e correspondência dos textos. Ele não ouve os MP3 nem avalia a qualidade da pronúncia. Por isso, também verificamos a presença dos arquivos, geramos as cinco amostras e fizemos a conferência auditiva no jogo.

   A lógica do gerador foi verificada com simulações de falhas, confirmando a preservação do backup, a proteção do MP3 anterior e o isolamento do modo de teste.

8. **Entender a versão de apresentação e o Git**

   Escolhemos **v1.1.0-rc.1 — Edição de Apresentação** porque o repositório já tinha versões até `v1.0.1`. O sufixo `rc.1` significa a primeira candidata à versão `1.1.0`: uma identificação para apresentação e revisão, ainda aberta a ajustes.

   Atualizamos o README e as instruções de instalação para descrever a nova voz. Preparamos também os MP3, o gerador e os arquivos `.import`, que guardam configurações de importação do Godot. A configuração do projeto já ajustada pelo editor para Godot 4.7 foi incluída no commit.

   O arquivo `.gitignore` mantém o backup `audio/marin_backup/`, as amostras `audio_test/` e os caches fora do versionamento. Ignorar essas pastas no Git não as apaga do computador.

   Os termos do Git usados nesta etapa são:

   | Termo | O que significa aqui |
   | --- | --- |
   | Commit | Um registro local das alterações |
   | Branch | Uma linha de trabalho que agrupa alterações |
   | Push | O envio dos commits para o GitHub |
   | Pull request, ou PR | Uma proposta para integrar uma branch à principal |
   | Tag | Uma marca que identifica um commit como determinada versão |

   O trabalho de troca de voz foi registrado no commit `7ab4cd1` e organizado na branch `release/v1.1.0-rc.1`. Este tutorial foi adicionado em um commit posterior. O repositório de publicação é [AugustoSalvego/Zoo_Game](https://github.com/AugustoSalvego/Zoo_Game).

   O fluxo de publicação inclui enviar as alterações para `main`, acompanhar a validação e a exportação Web e criar a tag `v1.1.0-rc.1`. O workflow existente atualiza os arquivos Web quando recebe um push em `main`; a tag deve identificar também essa exportação atualizada.

   Ao obter uma cópia do projeto, confira a versão no README e a presença de `tools/generate_edge_tts_audio.py`. Para acompanhar a exportação Web, abra a aba **Actions** do repositório e confira o resultado do workflow **Export Godot Web**. A publicação da página aparece no workflow **pages build and deployment**.
