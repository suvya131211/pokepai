extends Control

var pokemon = null
var pokemon_index: int = 0

func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

func show_summary(pkmn, index: int = 0):
	pokemon = pkmn
	pokemon_index = index
	visible = true
	GameManager.change_state(GameManager.GameState.PAUSED)
	queue_redraw()

func _unhandled_input(event):
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		get_viewport().set_input_as_handled()
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_C:
			visible = false
			GameManager.change_state(GameManager.GameState.WORLD)
		elif event.keycode == KEY_LEFT or event.keycode == KEY_A:
			pokemon_index = maxi(0, pokemon_index - 1)
			if pokemon_index < GameManager.party.size():
				pokemon = GameManager.party[pokemon_index]
				queue_redraw()
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			pokemon_index = mini(GameManager.party.size() - 1, pokemon_index + 1)
			if pokemon_index < GameManager.party.size():
				pokemon = GameManager.party[pokemon_index]
				queue_redraw()

func _process(_delta):
	if visible:
		queue_redraw()

func _draw():
	if not visible or not pokemon:
		return
	var w = get_viewport_rect().size.x
	var h = get_viewport_rect().size.y

	# Background
	draw_rect(Rect2(0, 0, w, h), Color(0.04, 0.06, 0.12, 0.97))

	# Title
	draw_string(ThemeDB.fallback_font, Vector2(20, 30), "POKEMON SUMMARY", HORIZONTAL_ALIGNMENT_LEFT, w, 18, Color("#4fc3f7"))
	draw_string(ThemeDB.fallback_font, Vector2(w - 200, 30), "< A/D to switch >", HORIZONTAL_ALIGNMENT_LEFT, 180, 11, Color("#888"))

	# Sprite (large)
	var tex = PokemonDB.get_sprite_texture(pokemon.id)
	if tex:
		draw_texture_rect(tex, Rect2(40, 50, 120, 120), false)

	# Shiny star
	if pokemon.is_shiny:
		draw_string(ThemeDB.fallback_font, Vector2(150, 70), "★ SHINY", HORIZONTAL_ALIGNMENT_LEFT, 80, 14, Color("#ffd700"))

	# Name and basic info
	var col1_x = 180.0
	draw_string(ThemeDB.fallback_font, Vector2(col1_x, 70), pokemon.pokemon_name, HORIZONTAL_ALIGNMENT_LEFT, 200, 20, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(col1_x, 92), "Type: %s" % pokemon.type.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 200, 13, Color("#4fc3f7"))
	draw_string(ThemeDB.fallback_font, Vector2(col1_x, 110), "Level: %d" % pokemon.level, HORIZONTAL_ALIGNMENT_LEFT, 200, 13, Color("#ccc"))
	draw_string(ThemeDB.fallback_font, Vector2(col1_x, 128), "Nature: %s" % pokemon.nature, HORIZONTAL_ALIGNMENT_LEFT, 200, 13, Color("#aaa"))
	draw_string(ThemeDB.fallback_font, Vector2(col1_x, 146), "Ability: %s" % pokemon.ability, HORIZONTAL_ALIGNMENT_LEFT, 200, 13, Color("#ff9800"))
	draw_string(ThemeDB.fallback_font, Vector2(col1_x, 164), "XP: %d / %d" % [pokemon.xp, pokemon.xp_to_next], HORIZONTAL_ALIGNMENT_LEFT, 200, 12, Color("#aaa"))

	# Stats section
	var stats_y = 200.0
	draw_string(ThemeDB.fallback_font, Vector2(40, stats_y), "STATS", HORIZONTAL_ALIGNMENT_LEFT, 100, 16, Color("#4fc3f7"))
	stats_y += 24

	var stats = [
		{"name": "HP", "value": pokemon.hp, "max": pokemon.max_hp, "color": Color("#4caf50")},
		{"name": "Attack", "value": pokemon.atk, "max": 200, "color": Color("#f44336")},
		{"name": "Defense", "value": pokemon.def_stat, "max": 200, "color": Color("#2196f3")},
	]
	for stat in stats:
		draw_string(ThemeDB.fallback_font, Vector2(50, stats_y + 14), stat["name"], HORIZONTAL_ALIGNMENT_LEFT, 80, 12, Color("#ccc"))
		draw_rect(Rect2(140, stats_y + 4, 200, 12), Color("#222"))
		var ratio = float(stat["value"]) / float(stat["max"])
		draw_rect(Rect2(140, stats_y + 4, 200 * minf(ratio, 1.0), 12), stat["color"])
		draw_string(ThemeDB.fallback_font, Vector2(345, stats_y + 14), str(stat["value"]), HORIZONTAL_ALIGNMENT_LEFT, 40, 11, Color.WHITE)
		stats_y += 22

	# IVs and EVs
	stats_y += 10
	draw_string(ThemeDB.fallback_font, Vector2(50, stats_y), "IVs: HP:%d ATK:%d DEF:%d" % [pokemon.iv_hp, pokemon.iv_atk, pokemon.iv_def], HORIZONTAL_ALIGNMENT_LEFT, 300, 10, Color("#666"))
	stats_y += 16
	draw_string(ThemeDB.fallback_font, Vector2(50, stats_y), "EVs: HP:%d ATK:%d DEF:%d" % [pokemon.ev_hp, pokemon.ev_atk, pokemon.ev_def], HORIZONTAL_ALIGNMENT_LEFT, 300, 10, Color("#666"))

	# Moves section
	var moves_x = w * 0.55
	draw_string(ThemeDB.fallback_font, Vector2(moves_x, 200), "MOVES", HORIZONTAL_ALIGNMENT_LEFT, 100, 16, Color("#4fc3f7"))
	var my = 224.0
	for i in pokemon.known_moves.size():
		var mv = pokemon.known_moves[i]
		var tc = Color("#aaa")
		var type_colors = {"fire":Color("#f44"),"water":Color("#4af"),"grass":Color("#4c4"),"electric":Color("#fd2"),"rock":Color("#b96"),"ground":Color("#d94"),"ghost":Color("#86b"),"dark":Color("#654"),"ice":Color("#6df"),"psychic":Color("#f6a"),"fairy":Color("#f9c"),"poison":Color("#a5a"),"flying":Color("#8af"),"steel":Color("#9af"),"dragon":Color("#66f"),"fighting":Color("#c64"),"normal":Color("#aaa")}
		tc = type_colors.get(mv.get("type", "normal"), Color("#aaa"))
		draw_rect(Rect2(moves_x, my, w * 0.4, 36), Color(0.08, 0.1, 0.16))
		draw_rect(Rect2(moves_x, my, w * 0.4, 36), tc, false, 1.5)
		draw_string(ThemeDB.fallback_font, Vector2(moves_x + 8, my + 16), mv.get("name", "???"), HORIZONTAL_ALIGNMENT_LEFT, 120, 13, Color.WHITE)
		draw_string(ThemeDB.fallback_font, Vector2(moves_x + 130, my + 16), mv.get("type", "").to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 60, 10, tc)
		draw_string(ThemeDB.fallback_font, Vector2(moves_x + 200, my + 16), "Pow:%s" % str(mv.get("power", "-")), HORIZONTAL_ALIGNMENT_LEFT, 60, 10, Color("#aaa"))
		draw_string(ThemeDB.fallback_font, Vector2(moves_x + 270, my + 16), "PP:%d/%d" % [mv.get("current_pp", 0), mv.get("pp", 0)], HORIZONTAL_ALIGNMENT_LEFT, 60, 10, Color("#aaa"))
		my += 42

	# Status
	if pokemon.status != "":
		draw_string(ThemeDB.fallback_font, Vector2(40, h - 50), "Status: %s" % pokemon.status.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 200, 14, Color("#f44336"))

	# Footer
	draw_string(ThemeDB.fallback_font, Vector2(20, h - 20), "Press C or ESC to close", HORIZONTAL_ALIGNMENT_LEFT, w, 12, Color("#888"))
