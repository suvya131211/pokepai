extends Control
class_name InventoryUI

var _current_inventory = null
var _heal_message: String = ""
var _heal_timer: float = 0.0

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

func toggle(inventory) -> void:
	_current_inventory = inventory
	visible = !visible
	if visible:
		GameManager.change_state(GameManager.GameState.INVENTORY)
	else:
		GameManager.change_state(GameManager.GameState.WORLD)

func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("open_inventory") or event.is_action_pressed("pause_menu")):
		visible = false
		GameManager.change_state(GameManager.GameState.WORLD)
		get_viewport().set_input_as_handled()
	# Use Repel (R key)
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		if _current_inventory and _current_inventory.key_items.get("repel", 0) > 0:
			_current_inventory.key_items["repel"] -= 1
			_current_inventory.repel_steps = 200
			_heal_message = "Used Repel! No wild encounters for 200 steps."
			_heal_timer = 2.0
			get_viewport().set_input_as_handled()
		elif _current_inventory:
			_heal_message = "You have no Repels!"
			_heal_timer = 2.0
			get_viewport().set_input_as_handled()
	# Use Escape Rope (E key in inventory)
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_E:
		if _current_inventory and _current_inventory.key_items.get("escape_rope", 0) > 0:
			_current_inventory.key_items["escape_rope"] -= 1
			_heal_message = "Used Escape Rope! Teleported to last Pokemon Center."
			_heal_timer = 2.0
			get_viewport().set_input_as_handled()
			# Signal escape rope use (main.gd or game manager can handle teleport)
			GameManager.emit_signal("escape_rope_used") if GameManager.has_signal("escape_rope_used") else null
		elif _current_inventory:
			_heal_message = "You have no Escape Ropes!"
			_heal_timer = 2.0
			get_viewport().set_input_as_handled()
	# Use berry on party Pokemon (press 1-6 to heal that party member)
	if visible and event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_6:
			var idx = event.keycode - KEY_1
			if idx < GameManager.party.size():
				var pkmn = GameManager.party[idx]
				if pkmn.hp < pkmn.max_hp:
					var inv = _current_inventory
					if inv:
						for berry_type in ["razz", "nanab", "pinap"]:
							if inv.berries.get(berry_type, 0) > 0:
								inv.berries[berry_type] -= 1
								pkmn.hp = mini(pkmn.max_hp, pkmn.hp + 15)
								_heal_message = "%s used %s berry! +15 HP (%d/%d)" % [pkmn.pokemon_name, berry_type.capitalize(), pkmn.hp, pkmn.max_hp]
								_heal_timer = 2.0
								get_viewport().set_input_as_handled()
								break
				else:
					_heal_message = "%s is already at full HP!" % GameManager.party[idx].pokemon_name
					_heal_timer = 2.0
					get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if visible:
		queue_redraw()
	if _heal_timer > 0:
		_heal_timer -= delta

func _draw() -> void:
	if not visible:
		return
	var w := get_viewport_rect().size.x
	var h := get_viewport_rect().size.y

	draw_rect(Rect2(0, 0, w, h), Color(0.05, 0.07, 0.12, 0.95))
	draw_string(ThemeDB.fallback_font, Vector2(24, 40), "INVENTORY", HORIZONTAL_ALIGNMENT_LEFT, w, 20, Color("#4fc3f7"))

	# Balls section
	var y := 70.0
	draw_string(ThemeDB.fallback_font, Vector2(24, y), "Pokeballs", HORIZONTAL_ALIGNMENT_LEFT, w, 16, Color("#e0e0e0"))
	y += 28

	# Draw ball items (will be populated from player inventory in main scene)
	var ball_items := ["pokeball", "greatball", "ultraball"]
	var ball_colors := {"pokeball": Color("#f44336"), "greatball": Color("#2196f3"), "ultraball": Color("#ffd700")}
	for ball_type in ball_items:
		draw_circle(Vector2(40, y + 8), 10, ball_colors[ball_type])
		draw_circle(Vector2(40, y + 13), 10, Color.WHITE)
		var ball_count = _current_inventory.balls.get(ball_type, 0) if _current_inventory else "?"
		draw_string(ThemeDB.fallback_font, Vector2(60, y + 14), "%s: %s" % [ball_type.capitalize(), str(ball_count)], HORIZONTAL_ALIGNMENT_LEFT, w, 14, Color("#ccc"))
		y += 32

	y += 16
	draw_string(ThemeDB.fallback_font, Vector2(24, y), "Berries", HORIZONTAL_ALIGNMENT_LEFT, w, 16, Color("#e0e0e0"))
	y += 28
	var berry_colors := {"razz": Color("#e91e63"), "nanab": Color("#ffeb3b"), "pinap": Color("#8bc34a")}
	for berry_type in ["razz", "nanab", "pinap"]:
		draw_circle(Vector2(40, y + 8), 8, berry_colors[berry_type])
		var berry_count = _current_inventory.berries.get(berry_type, 0) if _current_inventory else "?"
		draw_string(ThemeDB.fallback_font, Vector2(60, y + 14), "%s Berry: %s" % [berry_type.capitalize(), str(berry_count)], HORIZONTAL_ALIGNMENT_LEFT, w, 14, Color("#ccc"))
		y += 32

	# Party list for healing
	draw_string(ThemeDB.fallback_font, Vector2(24, h * 0.6), "PARTY — Press 1-%d to heal:" % GameManager.party.size(), HORIZONTAL_ALIGNMENT_LEFT, w, 14, Color("#4fc3f7"))
	var py = h * 0.6 + 20
	for i in GameManager.party.size():
		var p = GameManager.party[i]
		var hp_text = "%d. %s  HP: %d/%d" % [i + 1, p.pokemon_name, p.hp, p.max_hp]
		var col = Color("#4caf50") if p.hp == p.max_hp else (Color("#ff9800") if p.hp > 0 else Color("#f44336"))
		draw_string(ThemeDB.fallback_font, Vector2(36, py), hp_text, HORIZONTAL_ALIGNMENT_LEFT, w - 48, 12, col)
		py += 18

	# Key Items section
	if _current_inventory and "key_items" in _current_inventory:
		var ki = _current_inventory.key_items
		if not ki.is_empty():
			draw_string(ThemeDB.fallback_font, Vector2(24, py + 10), "Key Items", HORIZONTAL_ALIGNMENT_LEFT, w, 16, Color("#e0e0e0"))
			py += 30
			var repel_count = ki.get("repel", 0)
			var rope_count = ki.get("escape_rope", 0)
			var repel_steps_left = _current_inventory.repel_steps if "repel_steps" in _current_inventory else 0
			var repel_label = "Repel x%d" % repel_count
			if repel_steps_left > 0:
				repel_label += " (active: %d steps)" % repel_steps_left
			draw_string(ThemeDB.fallback_font, Vector2(36, py), repel_label + "  [R to use]", HORIZONTAL_ALIGNMENT_LEFT, w - 48, 12, Color("#a5d6a7"))
			py += 18
			draw_string(ThemeDB.fallback_font, Vector2(36, py), "Escape Rope x%d  [E to use]" % rope_count, HORIZONTAL_ALIGNMENT_LEFT, w - 48, 12, Color("#ffcc80"))
			py += 18

	# Heal message
	if _heal_timer > 0:
		draw_string(ThemeDB.fallback_font, Vector2(w / 2 - 100, h - 40), _heal_message, HORIZONTAL_ALIGNMENT_CENTER, 200, 13, Color("#4caf50"))

	draw_string(ThemeDB.fallback_font, Vector2(24, h - 16), "Press I or ESC to close | R=Repel | E=Escape Rope", HORIZONTAL_ALIGNMENT_LEFT, w, 12, Color("#888"))
	draw_string(ThemeDB.fallback_font, Vector2(w - 80, 20), "[H] Help", HORIZONTAL_ALIGNMENT_LEFT, 70, 10, Color("#555"))
