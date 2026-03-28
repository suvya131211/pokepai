extends Control

var expanded: bool = false

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta):
	if Input.is_action_just_pressed("toggle_map"):
		expanded = !expanded
	queue_redraw()

func _draw():
	if GameManager.state != GameManager.GameState.WORLD:
		return

	var vp = get_viewport_rect().size

	if GameManager.show_fly_menu:
		_draw_fly_menu(vp)
	elif expanded:
		_draw_full_map(vp)
	else:
		_draw_mini_map(vp)

func _draw_fly_menu(vp: Vector2):
	var towns = GameManager.towns_visited
	var menu_w = 250.0
	var menu_h = 30.0 + towns.size() * 28.0
	var mx = (vp.x - menu_w) / 2
	var my = (vp.y - menu_h) / 2
	draw_rect(Rect2(mx - 4, my - 4, menu_w + 8, menu_h + 8), Color(0.04, 0.06, 0.12, 0.95))
	draw_rect(Rect2(mx - 4, my - 4, menu_w + 8, menu_h + 8), Color("#4fc3f7"), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(mx + 10, my + 18), "FLY — Choose destination:", HORIZONTAL_ALIGNMENT_LEFT, menu_w, 14, Color("#ffd700"))
	for i in towns.size():
		var ty = my + 32.0 + i * 28.0
		draw_string(ThemeDB.fallback_font, Vector2(mx + 10, ty + 14), "%d. %s" % [i + 1, towns[i]], HORIZONTAL_ALIGNMENT_LEFT, menu_w - 20, 13, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(mx + 10, my + menu_h - 4), "Press 1-%d or ESC" % towns.size(), HORIZONTAL_ALIGNMENT_LEFT, menu_w, 10, Color("#888"))

func _draw_mini_map(vp: Vector2):
	# Small minimap in top-right corner
	var map_w = 120.0
	var map_h = 80.0
	var mx = vp.x - map_w - 10
	var my = 10.0

	# Background
	draw_rect(Rect2(mx - 2, my - 2, map_w + 4, map_h + 4), Color(0, 0, 0, 0.7))

	# Get area data
	var area_mgr = _get_area_manager()
	if not area_mgr or not area_mgr.current_area:
		draw_string(ThemeDB.fallback_font, Vector2(mx + 10, my + 40), "No map", HORIZONTAL_ALIGNMENT_LEFT, map_w, 12, Color("#888"))
		return

	var area = area_mgr.current_area
	var tile_w = map_w / area.width
	var tile_h = map_h / area.height

	# Draw tiles
	for y in area.height:
		for x in area.width:
			var tile = area.get_tile(x, y)
			var color = area.TILE_COLORS.get(tile, Color.BLACK)
			draw_rect(Rect2(mx + x * tile_w, my + y * tile_h, tile_w + 0.5, tile_h + 0.5), color)

	# Draw exits as green dots
	for ex in area.exits:
		var ex_x = mx + ex["x"] * tile_w + tile_w / 2
		var ex_y = my + ex["y"] * tile_h + tile_h / 2
		draw_circle(Vector2(ex_x, ex_y), 3, Color(0, 1, 0, 0.8))

	# Draw NPCs
	for npc in area.npcs:
		var nx = mx + npc["x"] * tile_w + tile_w / 2
		var ny = my + npc["y"] * tile_h + tile_h / 2
		var nc = Color("#4fc3f7")
		if npc.get("type", "") == "trainer": nc = Color("#e53935")
		elif npc.get("type", "") == "nurse": nc = Color("#ff69b4")
		elif npc.get("type", "") == "shop": nc = Color("#2196f3")
		elif npc.get("type", "") == "rival": nc = Color("#ff9800")
		elif npc.get("type", "") == "rocket": nc = Color("#9c27b0")
		draw_circle(Vector2(nx, ny), 2, nc)

	# Draw gym leader
	if not area.gym_leader.is_empty():
		var gx = mx + area.gym_leader.get("x", 0) * tile_w + tile_w / 2
		var gy = my + area.gym_leader.get("y", 0) * tile_h + tile_h / 2
		draw_circle(Vector2(gx, gy), 3, Color("#ffd700"))

	# Draw player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var px = mx + (player.global_position.x / 16.0) * tile_w
		var py = my + (player.global_position.y / 16.0) * tile_h
		draw_circle(Vector2(px, py), 3, Color.WHITE)

	# Area name
	draw_string(ThemeDB.fallback_font, Vector2(mx, my + map_h + 12), area.area_name, HORIZONTAL_ALIGNMENT_LEFT, map_w, 10, Color("#4fc3f7"))

	# Legend hint
	draw_string(ThemeDB.fallback_font, Vector2(mx, my + map_h + 24), "[M] expand", HORIZONTAL_ALIGNMENT_LEFT, map_w, 9, Color("#666"))

	# Badge count display
	var badge_count = GameManager.badges_earned
	draw_string(ThemeDB.fallback_font, Vector2(mx, my + map_h + 38), "Badges: %d/8" % badge_count, HORIZONTAL_ALIGNMENT_LEFT, map_w, 10, Color("#ffd700"))

func _draw_full_map(vp: Vector2):
	# Large centered map overlay
	var map_w = vp.x * 0.6
	var map_h = vp.y * 0.6
	var mx = (vp.x - map_w) / 2
	var my = (vp.y - map_h) / 2

	# Dark overlay
	draw_rect(Rect2(0, 0, vp.x, vp.y), Color(0, 0, 0, 0.5))
	# Map background
	draw_rect(Rect2(mx - 4, my - 4, map_w + 8, map_h + 8), Color(0.05, 0.08, 0.12, 0.95))
	draw_rect(Rect2(mx - 4, my - 4, map_w + 8, map_h + 8), Color("#4fc3f7"), false, 2.0)

	var area_mgr = _get_area_manager()
	if not area_mgr or not area_mgr.current_area:
		return

	var area = area_mgr.current_area
	var tile_w = map_w / area.width
	var tile_h = map_h / area.height

	# Draw tiles
	for y in area.height:
		for x in area.width:
			var tile = area.get_tile(x, y)
			var color = area.TILE_COLORS.get(tile, Color.BLACK)
			draw_rect(Rect2(mx + x * tile_w, my + y * tile_h, tile_w + 0.5, tile_h + 0.5), color)

	# Grid lines
	for y in area.height + 1:
		draw_line(Vector2(mx, my + y * tile_h), Vector2(mx + map_w, my + y * tile_h), Color(0, 0, 0, 0.1), 0.5)
	for x in area.width + 1:
		draw_line(Vector2(mx + x * tile_w, my), Vector2(mx + x * tile_w, my + map_h), Color(0, 0, 0, 0.1), 0.5)

	# Exits with labels
	for ex in area.exits:
		var ex_x = mx + ex["x"] * tile_w + tile_w / 2
		var ex_y = my + ex["y"] * tile_h + tile_h / 2
		draw_circle(Vector2(ex_x, ex_y), 5, Color(0, 1, 0, 0.8))
		draw_string(ThemeDB.fallback_font, Vector2(ex_x + 8, ex_y + 4), ex.get("target_area", ""), HORIZONTAL_ALIGNMENT_LEFT, 100, 9, Color(0, 1, 0))

	# NPCs with labels
	for npc in area.npcs:
		var nx = mx + npc["x"] * tile_w + tile_w / 2
		var ny = my + npc["y"] * tile_h + tile_h / 2
		var nc = Color("#4fc3f7")
		if npc.get("type", "") == "trainer": nc = Color("#e53935")
		elif npc.get("type", "") == "nurse": nc = Color("#ff69b4")
		elif npc.get("type", "") == "shop": nc = Color("#2196f3")
		elif npc.get("type", "") == "rival": nc = Color("#ff9800")
		elif npc.get("type", "") == "rocket": nc = Color("#9c27b0")
		draw_circle(Vector2(nx, ny), 4, nc)
		draw_string(ThemeDB.fallback_font, Vector2(nx + 6, ny + 4), npc.get("name", ""), HORIZONTAL_ALIGNMENT_LEFT, 80, 8, nc)

	# Gym leader
	if not area.gym_leader.is_empty():
		var gl = area.gym_leader
		var gx = mx + gl.get("x", 0) * tile_w + tile_w / 2
		var gy = my + gl.get("y", 0) * tile_h + tile_h / 2
		draw_circle(Vector2(gx, gy), 5, Color("#ffd700"))
		draw_string(ThemeDB.fallback_font, Vector2(gx + 8, gy + 4), gl.get("name", "Gym Leader"), HORIZONTAL_ALIGNMENT_LEFT, 100, 10, Color("#ffd700"))

	# Player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var px = mx + (player.global_position.x / 16.0) * tile_w
		var py = my + (player.global_position.y / 16.0) * tile_h
		draw_circle(Vector2(px, py), 5, Color.WHITE)
		draw_arc(Vector2(px, py), 5, 0, TAU, 8, Color("#ffd700"), 2.0)

	# Title
	draw_string(ThemeDB.fallback_font, Vector2(mx + 10, my - 8), area.area_name, HORIZONTAL_ALIGNMENT_LEFT, map_w, 16, Color("#4fc3f7"))

	# Legend
	var ly = my + map_h + 14
	draw_string(ThemeDB.fallback_font, Vector2(mx, ly), "Legend:", HORIZONTAL_ALIGNMENT_LEFT, 50, 10, Color("#aaa"))
	var items = [
		{"color": Color.WHITE, "label": "You"},
		{"color": Color(0, 1, 0), "label": "Exit"},
		{"color": Color("#ffd700"), "label": "Gym"},
		{"color": Color("#ff69b4"), "label": "Heal"},
		{"color": Color("#2196f3"), "label": "Shop"},
		{"color": Color("#e53935"), "label": "Trainer"},
	]
	var lx = mx + 60
	for item in items:
		draw_circle(Vector2(lx, ly - 3), 4, item["color"])
		draw_string(ThemeDB.fallback_font, Vector2(lx + 8, ly), item["label"], HORIZONTAL_ALIGNMENT_LEFT, 50, 9, Color("#ccc"))
		lx += 70

	draw_string(ThemeDB.fallback_font, Vector2(mx + map_w - 100, my - 8), "Press [M] to close", HORIZONTAL_ALIGNMENT_LEFT, 100, 10, Color("#888"))

func _get_area_manager():
	var nodes = get_tree().get_nodes_in_group("area_manager")
	if nodes.size() > 0:
		return nodes[0]
	return null
