extends Control
class_name BattleScene

enum Phase { INTRO, MENU, PLAYER_ATK, WILD_ATK, END }

var player_pokemon: Pokemon
var wild_pokemon: Pokemon
var phase: Phase = Phase.INTRO
var message: String = ""
var message_timer: float = 0.0
var result: String = ""  # "defeated" / "fled" / ""
var leveled_up: bool = false
var xp_multiplier: float = 1.0

signal battle_ended(result: String, wild: Pokemon)

func start(party: Array, wild: Pokemon) -> void:
	player_pokemon = party[0] if party.size() > 0 else null
	wild_pokemon = wild
	phase = Phase.INTRO
	message = "A wild %s appeared!" % wild.pokemon_name
	message_timer = 2.0
	result = ""
	leveled_up = false
	xp_multiplier = 1.0
	visible = true
	queue_redraw()

func _process(delta: float) -> void:
	if not visible:
		return
	if message_timer > 0:
		message_timer -= delta
		if message_timer <= 0:
			if phase == Phase.INTRO:
				phase = Phase.MENU
			elif phase == Phase.PLAYER_ATK and wild_pokemon.is_alive():
				_wild_attack()
			elif phase == Phase.WILD_ATK:
				phase = Phase.MENU
			elif phase == Phase.END:
				battle_ended.emit(result, wild_pokemon)
				visible = false
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not visible or phase != Phase.MENU:
		return
	if event is InputEventMouseButton and event.pressed:
		var pos := event.position
		var w := size.x
		var h := size.y
		var btn_y := h - 140
		var btn_w := 130.0
		var btn_h := 36.0
		var buttons := [
			{"label":"FIGHT", "x":20, "action":"fight"},
			{"label":"BALL",  "x":160, "action":"catch"},
			{"label":"BERRY", "x":300, "action":"berry"},
			{"label":"RUN",   "x":440, "action":"flee"},
		]
		for btn in buttons:
			if Rect2(btn["x"], btn_y, btn_w, btn_h).has_point(pos):
				match btn["action"]:
					"fight": _player_attack()
					"catch": battle_ended.emit("catch", wild_pokemon)
					"berry": _use_berry()
					"flee":  _flee()

func _player_attack() -> void:
	if not player_pokemon:
		return
	phase = Phase.PLAYER_ATK
	var result_data := player_pokemon.calc_damage(wild_pokemon)
	wild_pokemon.hp = maxi(0, wild_pokemon.hp - result_data["damage"])
	message = "%s attacked! %d dmg. %s" % [player_pokemon.pokemon_name, result_data["damage"], result_data["text"]]
	message_timer = 1.5
	if not wild_pokemon.is_alive():
		phase = Phase.END
		result = "defeated"
		var base_xp := wild_pokemon.level * 10
		var xp := int(base_xp * xp_multiplier)
		leveled_up = player_pokemon.gain_xp(xp)
		message = "%s fainted! Got %d XP." % [wild_pokemon.pokemon_name, xp]
		message_timer = 2.0

func _wild_attack() -> void:
	phase = Phase.WILD_ATK
	if wild_pokemon.status == "sleep":
		message = "%s is fast asleep..." % wild_pokemon.pokemon_name
		message_timer = 1.5
		return
	if not player_pokemon:
		return
	var result_data := wild_pokemon.calc_damage(player_pokemon)
	player_pokemon.hp = maxi(0, player_pokemon.hp - result_data["damage"])
	message = "%s attacked! %d dmg." % [wild_pokemon.pokemon_name, result_data["damage"]]
	message_timer = 1.5

func _use_berry() -> void:
	wild_pokemon.status = "sleep"
	message = "Used Nanab Berry! %s fell asleep!" % wild_pokemon.pokemon_name
	message_timer = 1.5

func _flee() -> void:
	phase = Phase.END
	result = "fled"
	message = "Got away safely!"
	message_timer = 1.0

func _draw() -> void:
	if not visible:
		return
	var w := size.x
	var h := size.y

	# Background
	draw_rect(Rect2(0, 0, w, h), Color("#0d1b2a"))

	# Wild pokemon (top right)
	if wild_pokemon:
		_draw_pokemon(wild_pokemon, Vector2(w * 0.7, h * 0.25), 40.0)
		_draw_hp_bar(Vector2(w * 0.5, h * 0.08), 150.0, wild_pokemon)

	# Player pokemon (bottom left)
	if player_pokemon:
		_draw_pokemon(player_pokemon, Vector2(w * 0.28, h * 0.6), 36.0)
		_draw_hp_bar(Vector2(w * 0.05, h * 0.7), 150.0, player_pokemon)

	# Message box
	draw_rect(Rect2(10, h - 80, w - 20, 65), Color("#1c3144"))
	draw_rect(Rect2(10, h - 80, w - 20, 65), Color("#4fc3f7"), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(22, h - 52), message, HORIZONTAL_ALIGNMENT_LEFT, w - 44, 14, Color("#e0e0e0"))

	# Buttons
	if phase == Phase.MENU:
		var btn_y := h - 140
		var labels := ["FIGHT", "BALL", "BERRY", "RUN"]
		var xs := [20, 160, 300, 440]
		for i in labels.size():
			draw_rect(Rect2(xs[i], btn_y, 130, 36), Color("#1c3144"))
			draw_rect(Rect2(xs[i], btn_y, 130, 36), Color("#4fc3f7"), false, 1.5)
			draw_string(ThemeDB.fallback_font, Vector2(xs[i] + 10, btn_y + 24), labels[i], HORIZONTAL_ALIGNMENT_LEFT, 110, 13, Color.WHITE)

func _draw_pokemon(pkmn: Pokemon, pos: Vector2, radius: float) -> void:
	draw_circle(pos, radius, pkmn.color)
	draw_arc(pos, radius, 0, TAU, 24, Color.WHITE, 2.0)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-20, radius + 14), pkmn.pokemon_name, HORIZONTAL_ALIGNMENT_CENTER, 40, 10, Color.WHITE)

func _draw_hp_bar(pos: Vector2, width: float, pkmn: Pokemon) -> void:
	draw_string(ThemeDB.fallback_font, pos, "%s Lv.%d" % [pkmn.pokemon_name, pkmn.level], HORIZONTAL_ALIGNMENT_LEFT, width, 12, Color("#ccc"))
	draw_rect(Rect2(pos.x, pos.y + 5, width, 8), Color("#333"))
	var ratio := float(pkmn.hp) / float(pkmn.max_hp)
	var bar_color := Color("#4caf50") if ratio > 0.5 else (Color("#ff9800") if ratio > 0.25 else Color("#f44336"))
	draw_rect(Rect2(pos.x, pos.y + 5, width * ratio, 8), bar_color)
	draw_string(ThemeDB.fallback_font, Vector2(pos.x + width + 4, pos.y + 12), "%d/%d" % [pkmn.hp, pkmn.max_hp], HORIZONTAL_ALIGNMENT_LEFT, 60, 10, Color("#aaa"))
