extends Node2D

var PokemonScript = preload("res://scripts/pokemon/pokemon.gd")
var AreaManagerScript = preload("res://scripts/world/area_manager.gd")
var NpcHandlerScript = preload("res://scripts/world/npc_handler.gd")
var BattleScript = preload("res://scripts/battle/battle.gd")
var HUDScript = preload("res://scripts/ui/hud.gd")
var PokedexScript = preload("res://scripts/ui/pokedex.gd")
var InventoryScript = preload("res://scripts/ui/inventory_ui.gd")
var TitleScript = preload("res://scripts/ui/title_screen.gd")
var DialogScript = preload("res://scripts/ui/story_dialog.gd")
var StarterScript = preload("res://scripts/ui/starter_select.gd")
var InstructionsScript = preload("res://scripts/ui/instructions_panel.gd")
var DayNightScript = preload("res://scripts/world/day_night.gd")
var WeatherScript = preload("res://scripts/world/weather.gd")
var MinimapScript = preload("res://scripts/ui/minimap_overlay.gd")

@onready var player = $World/Player

var area_manager
var npc_handler
var battle_scene
var hud
var pokedex
var inventory_ui
var story_dialog
var title_screen
var starter_select
var day_night
var weather_system

var current_npc_battle_data = null
var npc_interaction_cooldown: float = 0.0

var area_name_display: String = ""
var area_name_timer: float = 0.0

func _show_area_name(name: String):
	area_name_display = name
	area_name_timer = 2.0

func _ready():
	# Area manager
	area_manager = AreaManagerScript.new()
	$World.add_child(area_manager)
	player.set_area_manager(area_manager)

	# NPC handler
	npc_handler = NpcHandlerScript.new()
	add_child(npc_handler)
	npc_handler.npc_dialog_start.connect(_on_npc_dialog)
	npc_handler.npc_battle_start.connect(_on_npc_battle)
	npc_handler.heal_pokemon.connect(_heal_party)
	npc_handler.open_shop.connect(_on_shop)

	# Day/Night
	day_night = DayNightScript.new()
	$World.add_child(day_night)

	# Weather
	var weather_layer = CanvasLayer.new()
	weather_layer.layer = 5
	add_child(weather_layer)
	weather_system = WeatherScript.new()
	weather_layer.add_child(weather_system)

	# HUD
	hud = HUDScript.new()
	add_child(hud)

	# Add area_manager to group so minimap can find it
	area_manager.add_to_group("area_manager")

	# Minimap overlay
	var minimap = MinimapScript.new()
	minimap.set_anchors_preset(Control.PRESET_FULL_RECT)
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(minimap)

	# Instructions panel
	var instructions = InstructionsScript.new()
	instructions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(instructions)
	instructions.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Battle overlay
	var battle_layer = CanvasLayer.new()
	battle_layer.layer = 20
	add_child(battle_layer)
	battle_scene = BattleScript.new()
	battle_scene.visible = false
	battle_layer.add_child(battle_scene)
	battle_scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_scene.battle_ended.connect(_on_battle_ended)

	# UI layer
	var ui_layer = CanvasLayer.new()
	ui_layer.layer = 25
	add_child(ui_layer)

	pokedex = PokedexScript.new()
	ui_layer.add_child(pokedex)
	pokedex.set_anchors_preset(Control.PRESET_FULL_RECT)

	inventory_ui = InventoryScript.new()
	ui_layer.add_child(inventory_ui)
	inventory_ui.set_anchors_preset(Control.PRESET_FULL_RECT)

	story_dialog = DialogScript.new()
	ui_layer.add_child(story_dialog)
	story_dialog.set_anchors_preset(Control.PRESET_FULL_RECT)

	starter_select = StarterScript.new()
	ui_layer.add_child(starter_select)
	starter_select.set_anchors_preset(Control.PRESET_FULL_RECT)
	starter_select.starter_chosen.connect(_on_starter_chosen)

	# Title screen
	var title_layer = CanvasLayer.new()
	title_layer.layer = 30
	add_child(title_layer)
	title_screen = TitleScript.new()
	title_layer.add_child(title_screen)
	title_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_screen.start_game.connect(_on_title_done)

	# Player signals
	player.encountered_pokemon.connect(_on_wild_encounter)
	player.entered_exit.connect(_on_exit_entered)

	# Berry healing on map pickup
	GameManager.item_collected.connect(_on_item_found)

	# Start paused on title
	GameManager.change_state(GameManager.GameState.PAUSED)

func _on_title_done():
	EventTracker.log_event("TITLE_DONE", {})
	# Show Prof Oak intro
	story_dialog.show_dialog("Prof. Oak", [
		"Welcome to the world of Pokemon!",
		"I'm Professor Oak. I study Pokemon in the wild.",
		"The world is filled with Pokemon waiting to be discovered!",
		"But first, you need a partner Pokemon.",
	], Callable(self, "_show_starter_selection"))

func _show_starter_selection():
	starter_select.show_selection()

func _on_starter_chosen(species_id: int):
	var starter = PokemonScript.new(species_id, 5)
	GameManager.party.append(starter)
	player.follower_pokemon = starter

	# Rival picks counter-type
	var rival_id = {1: 2, 2: 3, 3: 1}.get(species_id, 2)  # picks advantage

	# Store rival choice for later battles
	GameManager.set_meta("rival_starter", rival_id)

	var starter_name = PokemonDB.get_species(species_id).get("name", "Pokemon")
	EventTracker.log_event("STARTER_CHOSEN", {"species_id": species_id, "name": starter_name})
	story_dialog.show_dialog("Prof. Oak", [
		"Excellent choice! %s is a wonderful partner!" % starter_name,
		"Your rival chose the Pokemon with a type advantage... typical!",
		"Now go! Collect 8 Gym Badges and challenge the Pokemon League!",
		"And fill your Pokedex along the way!",
	], Callable(self, "_start_adventure"))

func _start_adventure():
	EventTracker.log_event("ADVENTURE_START", {"area": "Pallet Town"})
	# Load starting area
	var spawn = area_manager.load_area("Pallet Town")
	player.global_position = Vector2(spawn["x"] * 16 + 8, spawn["y"] * 16 + 8)
	GameManager.change_state(GameManager.GameState.WORLD)

func _process(_delta):
	if area_name_timer > 0:
		area_name_timer -= _delta
		if area_name_timer <= 0:
			area_name_display = ""
	if npc_interaction_cooldown > 0:
		npc_interaction_cooldown -= _delta
	if GameManager.state == GameManager.GameState.WORLD:
		if Input.is_action_just_pressed("open_pokedex"):
			pokedex.toggle()
		if Input.is_action_just_pressed("open_inventory"):
			inventory_ui.toggle(player.get_node("Inventory"))
		# NPC interaction (E key)
		if Input.is_action_just_pressed("interact") and area_manager and npc_interaction_cooldown <= 0:
			# Check regular NPCs first
			var npc = area_manager.check_npc_facing(player.global_position.x, player.global_position.y, player.direction)
			if not npc.is_empty():
				npc_handler.interact_with_npc(npc, area_manager.get_current_area_name())
			# Check gym leader separately (independent of NPC list)
			elif area_manager.current_area and not area_manager.current_area.gym_leader.is_empty():
				var gl = area_manager.current_area.gym_leader
				var gl_x = gl.get("x", -1)
				var gl_y = gl.get("y", -1)
				var player_tile_x = int(player.global_position.x / 16)
				var player_tile_y = int(player.global_position.y / 16)
				var face_dx = 0
				var face_dy = 0
				match player.direction:
					"up": face_dy = -1
					"down": face_dy = 1
					"left": face_dx = -1
					"right": face_dx = 1
				if (player_tile_x + face_dx == gl_x and player_tile_y + face_dy == gl_y) or \
				   (player_tile_x == gl_x and player_tile_y == gl_y):
					_start_gym_battle(gl)

func _on_wild_encounter(encounter_data):
	if GameManager.state != GameManager.GameState.WORLD:
		return  # Don't trigger encounters during other states
	var species_id = encounter_data.get("species_id", 1)
	var level = randi_range(encounter_data.get("min_level", 2), encounter_data.get("max_level", 5))
	var wild = PokemonScript.new(species_id, level)
	print("[MAIN] Wild encounter: %s Lv.%d, party size: %d" % [wild.pokemon_name, level, GameManager.party.size()])
	EventTracker.log_event("WILD_ENCOUNTER", {"species_id": species_id, "level": level, "area": area_manager.get_current_area_name()})
	GameManager.add_to_pokedex(wild.id)
	GameManager.change_state(GameManager.GameState.BATTLE)
	var inv = player.get_node("Inventory")
	battle_scene.set_inventory(inv)
	battle_scene.start(GameManager.party, wild, inv)

func _on_exit_entered(exit_data):
	var target_area = exit_data.get("target_area", "")
	var target_x = exit_data.get("target_x", 14)
	var target_y = exit_data.get("target_y", 14)
	print("[MAIN] Exit triggered → %s at (%d, %d)" % [target_area, target_x, target_y])
	if target_area.is_empty():
		return
	var from_area = area_manager.get_current_area_name()
	var spawn = area_manager.load_area(target_area, target_x, target_y)
	if spawn.is_empty():
		print("[MAIN] ERROR: Failed to load area %s" % target_area)
		return
	# Place player 2 tiles away from exit to avoid re-triggering
	var sx = spawn["x"]
	var sy = spawn["y"]
	EventTracker.log_event("AREA_TRANSITION", {"from": from_area, "to": target_area, "spawn": str(Vector2(sx, sy))})
	# Move inward based on which edge the exit is on
	var area_w = 30
	var area_h = 20
	if area_manager.current_area:
		area_w = area_manager.current_area.width
		area_h = area_manager.current_area.height
	# Push 2 tiles inward from edge, then find walkable position
	if sy <= 1: sy = 2
	elif sy >= area_h - 2: sy = area_h - 3
	if sx <= 1: sx = 2
	elif sx >= area_w - 2: sx = area_w - 3
	# Search for nearest walkable tile from the path/center column
	# Prefer the center path (x=14,15) at the target y
	var best_x = sx
	var best_y = sy
	var found = false
	# First try: the path column at target y
	for try_x in [14, 15, 13, 16, sx, sx + 1, sx - 1]:
		if try_x >= 0 and try_x < area_w and area_manager.current_area.is_walkable(try_x, sy):
			best_x = try_x
			best_y = sy
			found = true
			break
	# Second try: spiral from adjusted position
	if not found:
		for radius in range(0, 8):
			for dy in range(-radius, radius + 1):
				for dx in range(-radius, radius + 1):
					var cx = sx + dx
					var cy = sy + dy
					if cx >= 0 and cx < area_w and cy >= 0 and cy < area_h:
						if area_manager.current_area.is_walkable(cx, cy):
							best_x = cx
							best_y = cy
							found = true
							break
				if found: break
			if found: break
	sx = best_x
	sy = best_y
	EventTracker.log_event("SPAWN_PLACED", {"area": target_area, "tile": str(Vector2i(sx, sy)), "walkable": area_manager.current_area.is_walkable(sx, sy)})
	player.global_position = Vector2(sx * 16 + 8, sy * 16 + 8)
	player.exit_cooldown = 3.0
	npc_interaction_cooldown = 3.0  # prevent NPC auto-trigger on area load
	# Show area name as a non-blocking notification
	_show_area_name(target_area)

func _on_npc_dialog(speaker, messages):
	npc_interaction_cooldown = 2.0  # prevent re-trigger after dialog
	story_dialog.show_dialog(speaker, messages)

func _on_npc_battle(npc_data):
	current_npc_battle_data = npc_data
	# Show dialog first, then start battle when dialog closes
	var dialog_lines = npc_data.get("dialog", ["Let's battle!"])
	var speaker = npc_data.get("name", "Trainer")
	story_dialog.show_dialog(speaker, dialog_lines, Callable(self, "_begin_npc_fight"))

func _begin_npc_fight():
	if not current_npc_battle_data:
		return
	GameManager.change_state(GameManager.GameState.BATTLE)
	var team = current_npc_battle_data.get("team", [])
	if team.size() > 0:
		battle_scene.set_inventory(player.get_node("Inventory"))
		if battle_scene.has_method("start_trainer_battle"):
			battle_scene.start_trainer_battle(current_npc_battle_data.get("name", "Trainer"), team)
		else:
			battle_scene.start(GameManager.party, team[0], player.get_node("Inventory"))

func _start_gym_battle(gym_data):
	story_dialog.show_dialog(gym_data.get("name", "Gym Leader"), gym_data.get("dialog", []), Callable(self, "_begin_gym_fight").bind(gym_data))

func _begin_gym_fight(gym_data):
	var team = npc_handler._build_team(gym_data.get("team", []))
	current_npc_battle_data = {"name": gym_data.get("name", ""), "key": "", "is_gym": true, "badge": gym_data.get("badge", ""), "win_dialog": gym_data.get("win_dialog", [])}
	GameManager.change_state(GameManager.GameState.BATTLE)
	battle_scene.set_inventory(player.get_node("Inventory"))
	if battle_scene.has_method("start_trainer_battle"):
		battle_scene.start_trainer_battle(gym_data.get("name", "Gym Leader"), team)
	else:
		battle_scene.start(GameManager.party, team[0], player.get_node("Inventory"))

func _on_battle_ended(result_str, wild):
	EventTracker.log_event("BATTLE_RESULT", {"result": result_str, "party_hp": str(GameManager.party.map(func(p): return "%s:%d/%d" % [p.pokemon_name, p.hp, p.max_hp]))})
	match result_str:
		"caught":
			wild.hp = wild.max_hp  # Heal caught Pokemon to full HP
			wild.status = ""
			GameManager.party.append(wild)
			GameManager.add_to_pokedex(wild.id, true)
			player.follower_pokemon = wild
			player._follower_pos = player.global_position
			story_dialog.show_dialog("", ["You caught %s!" % wild.pokemon_name])
		"defeated", "trainer_defeated":
			# Check evolution
			for i in GameManager.party.size():
				var pkmn = GameManager.party[i]
				if pkmn.can_evolve():
					var evolved = pkmn.evolve()
					GameManager.party[i] = evolved
					if player.follower_pokemon == pkmn:
						player.follower_pokemon = evolved
					story_dialog.show_dialog("", ["%s evolved into %s!" % [pkmn.pokemon_name, evolved.pokemon_name]])
			# Handle trainer defeat rewards
			if current_npc_battle_data:
				var key = current_npc_battle_data.get("key", "")
				if key:
					npc_handler.mark_defeated(key)
				if current_npc_battle_data.get("is_rival", false):
					npc_handler.mark_rival_defeated(current_npc_battle_data.get("battle_index", 0))
				if current_npc_battle_data.get("is_elite4", false):
					npc_handler.mark_elite4_defeated(current_npc_battle_data.get("name", ""))
				if current_npc_battle_data.get("is_gym", false):
					var badge = current_npc_battle_data.get("badge", "")
					npc_handler.mark_gym_defeated(badge)
					var win_msgs = current_npc_battle_data.get("win_dialog", [])
					if win_msgs.size() > 0:
						story_dialog.show_dialog(current_npc_battle_data.get("name", ""), win_msgs)
					story_dialog.show_dialog("", ["You earned the %s!" % badge, "Badges: %d/8" % npc_handler.get_badge_count()])
				if current_npc_battle_data.get("is_champion", false):
					story_dialog.show_dialog("Prof. Oak", [
						"Congratulations! You've defeated the Champion!",
						"You are now the Pokemon League Champion!",
						"Your journey through Kanto is complete!",
						"But there are still Pokemon to catch...",
						"Thank you for playing Pokepai!",
					])
				current_npc_battle_data = null
		"fled":
			pass
	# If lead Pokemon fainted, heal party fully (simulate "blacking out" to Pokemon Center)
	if GameManager.party.size() > 0 and GameManager.party[0].hp <= 0:
		_heal_party()
		story_dialog.show_dialog("", [
			"You blacked out!",
			"You were rushed to the nearest Pokemon Center...",
			"Your Pokemon have been fully healed!",
		])
	elif result_str in ["defeated", "trainer_defeated"]:
		# Only offer berry healing for fights, not catches
		var inv = player.get_node("Inventory")
		if player_pokemon_hurt() and inv.berries.get("razz", 0) > 0:
			var pkmn = GameManager.party[0]
			pkmn.hp = mini(pkmn.max_hp, pkmn.hp + int(pkmn.max_hp * 0.3))
			inv.berries["razz"] -= 1
			story_dialog.show_dialog("", [
				"%s has %d/%d HP." % [pkmn.pokemon_name, pkmn.hp, pkmn.max_hp],
				"Used a Razz Berry to heal!",
			])
	npc_interaction_cooldown = 2.0  # 2 second cooldown after battle
	GameManager.change_state(GameManager.GameState.WORLD)

func _on_shop():
	var inv = player.get_node("Inventory")
	inv.balls["pokeball"] += 5
	inv.balls["greatball"] += 2
	story_dialog.show_dialog("Shopkeeper", [
		"Here are some Pokeballs for your journey!",
		"Got 5 Pokeballs and 2 Great Balls!",
	])

func player_pokemon_hurt() -> bool:
	if GameManager.party.size() > 0:
		var p = GameManager.party[0]
		return p.hp < p.max_hp
	return false

func _heal_party():
	EventTracker.log_event("PARTY_HEALED", {})
	for pkmn in GameManager.party:
		pkmn.hp = pkmn.max_hp
		pkmn.status = ""
		for move in pkmn.known_moves:
			move["current_pp"] = move["pp"]

func _on_item_found(item_type: String):
	if item_type in ["razz", "nanab", "pinap"]:
		# Auto-heal lead Pokemon by 10 HP when finding a berry
		if GameManager.party.size() > 0:
			var lead = GameManager.party[0]
			if lead.hp < lead.max_hp:
				lead.hp = mini(lead.max_hp, lead.hp + 10)
				story_dialog.show_dialog("", ["Found a %s berry! %s healed 10 HP! (%d/%d)" % [item_type.capitalize(), lead.pokemon_name, lead.hp, lead.max_hp]])
			else:
				story_dialog.show_dialog("", ["Found a %s berry! Saved for later." % item_type.capitalize()])
