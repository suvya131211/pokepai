extends Control

# Press V to toggle evolution tracker

func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_V:
		visible = !visible
		get_viewport().set_input_as_handled()
		queue_redraw()
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		visible = false
		get_viewport().set_input_as_handled()

func _process(_delta):
	if visible:
		queue_redraw()

func _draw():
	if not visible:
		return
	var vp = get_viewport_rect().size
	var w = vp.x
	var h = vp.y

	# Dark overlay
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.85))

	# Panel
	var pw = w * 0.8
	var ph = h * 0.85
	var px = (w - pw) / 2
	var py = (h - ph) / 2
	draw_rect(Rect2(px, py, pw, ph), Color(0.04, 0.06, 0.12, 0.98))
	draw_rect(Rect2(px, py, pw, ph), Color("#4fc3f7"), false, 2.0)

	# Title
	draw_string(ThemeDB.fallback_font, Vector2(px + 16, py + 26), "EVOLUTION GUIDE  [V to close]", HORIZONTAL_ALIGNMENT_LEFT, pw, 18, Color("#4fc3f7"))

	# Get all evolution chains
	var chains = _get_evolution_chains()
	var col_w = pw / 2 - 10
	var row_h = 60.0
	var y_start = py + 50

	for i in chains.size():
		var chain = chains[i]
		var col = i % 2
		var row = i / 2
		var cx = px + 10 + col * (col_w + 10)
		var cy = y_start + row * row_h

		if cy + row_h > py + ph - 30:
			break  # don't draw beyond panel

		# Chain background
		draw_rect(Rect2(cx, cy, col_w, row_h - 4), Color(0.08, 0.1, 0.16, 0.9))
		draw_rect(Rect2(cx, cy, col_w, row_h - 4), Color("#333"), false, 1.0)

		# Draw each stage
		var stage_w = col_w / chain.size()
		for j in chain.size():
			var stage = chain[j]
			var sx = cx + j * stage_w
			var sy = cy + 4

			# Pokemon sprite
			var tex = PokemonDB.get_sprite_texture(stage["id"])
			if tex:
				draw_texture_rect(tex, Rect2(sx + 4, sy, 28, 28), false)
			else:
				draw_circle(Vector2(sx + 18, sy + 14), 12, stage.get("color", Color.GRAY))

			# Name
			draw_string(ThemeDB.fallback_font, Vector2(sx + 2, sy + 34),
				stage["name"], HORIZONTAL_ALIGNMENT_LEFT, stage_w - 4, 10, Color.WHITE)

			# Level requirement
			if stage.has("evolve_level"):
				draw_string(ThemeDB.fallback_font, Vector2(sx + 2, sy + 46),
					"Lv.%d →" % stage["evolve_level"], HORIZONTAL_ALIGNMENT_LEFT, stage_w - 4, 9, Color("#ffd700"))
			elif j == chain.size() - 1:
				draw_string(ThemeDB.fallback_font, Vector2(sx + 2, sy + 46),
					"FINAL", HORIZONTAL_ALIGNMENT_LEFT, stage_w - 4, 9, Color("#4caf50"))

			# Owned indicator
			var owned = stage["id"] in GameManager.pokedex_caught
			if owned:
				draw_string(ThemeDB.fallback_font, Vector2(sx + stage_w - 16, sy + 2),
					"✓", HORIZONTAL_ALIGNMENT_LEFT, 14, 10, Color("#4caf50"))

			# Arrow between stages
			if j < chain.size() - 1:
				var arrow_x = sx + stage_w - 6
				draw_string(ThemeDB.fallback_font, Vector2(arrow_x, sy + 18),
					"→", HORIZONTAL_ALIGNMENT_LEFT, 12, 14, Color("#ffd700"))

	# Your party evolution status
	var party_y = py + ph - 100
	draw_line(Vector2(px + 10, party_y - 6), Vector2(px + pw - 10, party_y - 6), Color("#333"), 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(px + 16, party_y + 10), "YOUR PARTY — Evolution Status:", HORIZONTAL_ALIGNMENT_LEFT, pw, 13, Color("#4fc3f7"))

	var party_x = px + 16
	for pkmn in GameManager.party:
		if party_x + 140 > px + pw:
			break
		var tex = PokemonDB.get_sprite_texture(pkmn.id)
		if tex:
			draw_texture_rect(tex, Rect2(party_x, party_y + 18, 24, 24), false)
		draw_string(ThemeDB.fallback_font, Vector2(party_x + 28, party_y + 30),
			pkmn.pokemon_name, HORIZONTAL_ALIGNMENT_LEFT, 60, 10, Color.WHITE)
		draw_string(ThemeDB.fallback_font, Vector2(party_x + 28, party_y + 42),
			"Lv.%d" % pkmn.level, HORIZONTAL_ALIGNMENT_LEFT, 40, 9, Color("#aaa"))

		# Can evolve?
		if pkmn.can_evolve():
			draw_string(ThemeDB.fallback_font, Vector2(party_x + 28, party_y + 54),
				"READY!", HORIZONTAL_ALIGNMENT_LEFT, 40, 9, Color("#ffd700"))
		elif pkmn.species.has("evolves_to") and pkmn.species["evolves_to"] != null:
			var evolve_lv = pkmn.species.get("evolve_level", 99)
			var levels_left = evolve_lv - pkmn.level
			draw_string(ThemeDB.fallback_font, Vector2(party_x + 28, party_y + 54),
				"%d lvls to go" % levels_left, HORIZONTAL_ALIGNMENT_LEFT, 60, 9, Color("#ff9800"))
		else:
			draw_string(ThemeDB.fallback_font, Vector2(party_x + 28, party_y + 54),
				"No evolution", HORIZONTAL_ALIGNMENT_LEFT, 60, 9, Color("#666"))

		party_x += 145

	# Tips
	draw_string(ThemeDB.fallback_font, Vector2(px + 16, py + ph - 16),
		"Tip: Defeat wild Pokemon to gain XP. Level up to evolve! Press ESC or V to close.",
		HORIZONTAL_ALIGNMENT_LEFT, pw - 32, 10, Color("#888"))

func _get_evolution_chains() -> Array:
	# Build evolution chains from PokemonDB
	var chains = []
	var used_ids = {}

	for species in PokemonDB.species:
		if species["id"] in used_ids:
			continue
		# Check if this is a base form (nothing evolves into it)
		var is_base = true
		for other in PokemonDB.species:
			if other.get("evolves_to", null) == species["id"]:
				is_base = false
				break
		if not is_base:
			continue

		# Build chain from this base
		var chain = []
		var current = species
		while current != null:
			chain.append({
				"id": current["id"],
				"name": current["name"],
				"color": current.get("color", Color.GRAY),
				"evolve_level": current.get("evolve_level", 0) if current.get("evolves_to", null) != null else 0,
			})
			used_ids[current["id"]] = true

			var next_id = current.get("evolves_to", null)
			if next_id != null and next_id is int:
				current = PokemonDB.get_species(next_id)
				if current.is_empty():
					break
			else:
				break

		if chain.size() >= 2:  # only show Pokemon that evolve
			chains.append(chain)

	return chains
