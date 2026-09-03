extends Node
class_name GameMetrics

## Camada de métricas do jogo — DESACOPLADA de qualquer plataforma.
##
## O que este script faz hoje:
##   - conta acertos, tentativas e erros por fase e no total;
##   - mede a duração da sessão;
##   - salva um resumo local em user://zoo_metrics.json ao final da sessão
##     (arquivo apenas local, no dispositivo/navegador de quem está jogando).
##
## O que este script explicitamente NÃO faz:
##   - não envia nada para nenhum servidor;
##   - não conhece nenhuma API da APAE/Nino Edu ou de terceiros;
##   - não inventa nenhum endpoint ou contrato de integração.
##
## Quando houver um contrato oficial de integração com a plataforma,
## implemente o envio dentro de `_reportar_para_plataforma()` (hoje vazia
## de propósito) — o resto do jogo não precisa mudar.

const METRICS_PATH := "user://zoo_metrics.json"

var session_start_ms: int = 0
var session_end_ms: int = 0
var total_attempts: int = 0
var total_correct: int = 0
var total_incorrect: int = 0
var completed: bool = false
var per_phase: Dictionary = {}  # nome_do_animal -> {"attempts": n, "correct": n}

func iniciar_sessao() -> void:
	session_start_ms = Time.get_ticks_msec()
	session_end_ms = 0
	total_attempts = 0
	total_correct = 0
	total_incorrect = 0
	completed = false
	per_phase.clear()

func registrar_tentativa(nome_fase: String, acertou: bool) -> void:
	total_attempts += 1
	if not per_phase.has(nome_fase):
		per_phase[nome_fase] = {"attempts": 0, "correct": 0}
	per_phase[nome_fase]["attempts"] += 1
	if acertou:
		total_correct += 1
		per_phase[nome_fase]["correct"] += 1
	else:
		total_incorrect += 1

func finalizar_sessao() -> void:
	session_end_ms = Time.get_ticks_msec()
	completed = true
	_salvar_localmente()
	_reportar_para_plataforma(resumo())

func duracao_segundos() -> float:
	var fim: int = session_end_ms if session_end_ms > 0 else Time.get_ticks_msec()
	return float(fim - session_start_ms) / 1000.0

func resumo() -> Dictionary:
	return {
		"completed": completed,
		"duration_seconds": duracao_segundos(),
		"total_attempts": total_attempts,
		"total_correct": total_correct,
		"total_incorrect": total_incorrect,
		"per_phase": per_phase,
		"timestamp_unix": Time.get_unix_time_from_system(),
	}

## Salva um resumo local em disco (só no dispositivo do jogador).
## Falha silenciosamente se não for possível escrever (ex.: alguns
## navegadores restringem persistência) — métricas nunca podem travar
## o jogo em si.
func _salvar_localmente() -> void:
	var file := FileAccess.open(METRICS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(resumo(), "\t"))
	file.close()

## Ponto único de integração futura com uma plataforma externa
## (ex.: APAE/Nino Edu). Propositalmente vazio: só deve ser preenchido
## quando existir um contrato oficial (endpoint, autenticação, formato
## de payload). Até lá, os dados ficam só localmente em METRICS_PATH.
func _reportar_para_plataforma(_dados: Dictionary) -> void:
	pass
