extends RefCounted
class_name GameData

# Local fallback content follows the same core shape used by NinoEdu's
# /api/recursos/silabas endpoint: palavra, silaba, complemento_silaba and imagem.
# This keeps the game playable offline and makes a future API adapter simple.

const QUESTION_BANK: Array[Dictionary] = [
	{
		"palavra": "CACHORRO",
		"silaba": "CA",
		"complemento_silaba": "__CHORRO",
		"imagem": "res://img/cachorro.png",
		"opcoes": ["CA", "BA", "PA"]
	},
	{
		"palavra": "GATO",
		"silaba": "GA",
		"complemento_silaba": "__TO",
		"imagem": "res://img/gato.png",
		"opcoes": ["GA", "CA", "PA"]
	},
	{
		"palavra": "MACACO",
		"silaba": "MA",
		"complemento_silaba": "__CACO",
		"imagem": "res://img/macaco.png",
		"opcoes": ["MA", "PA", "TA"]
	},
	{
		"palavra": "BALEIA",
		"silaba": "BA",
		"complemento_silaba": "__LEIA",
		"imagem": "res://img/baleia.png",
		"opcoes": ["BA", "GA", "LA"]
	},
	{
		"palavra": "CAVALO",
		"silaba": "CA",
		"complemento_silaba": "__VALO",
		"imagem": "res://img/cavalo.png",
		"opcoes": ["CA", "SA", "RA"]
	},
	{
		"palavra": "GALINHA",
		"silaba": "GA",
		"complemento_silaba": "__LINHA",
		"imagem": "res://img/galinha.png",
		"opcoes": ["GA", "MA", "TA"]
	},
	{
		"palavra": "TARTARUGA",
		"silaba": "TA",
		"complemento_silaba": "__RTARUGA",
		"imagem": "res://img/tartaruga.png",
		"opcoes": ["TA", "CA", "FA"]
	}
]

static func build_session(round_count: int = -1) -> Array[Dictionary]:
	var session: Array[Dictionary] = []
	for question in QUESTION_BANK:
		session.append(question.duplicate(true))

	session.shuffle()

	if round_count > 0 and round_count < session.size():
		session.resize(round_count)

	return session
