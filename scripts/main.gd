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

	# Instructions panel
	var instructions = InstructionsScript.new()
	instructions.set_anchors_preset(Control.PRESET_FULL_RECT)
	instructions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(instructions)

	# Battle overlay
	var battle_layer = CanvasLayer.new()
	battle_layer.layer = 20
	add_child(battle_layer)
	battle_scene = BattleScript.new()
	battle_scene.visible = false
	battle_scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_layer.add_child(battle_scene)
	battle_scene.battle_ended.connect(_on_battle_ended)

	# UI layer
	var ui_layer = CanvasLayer.new()
	ui_layer.layer = 25
	add_child(ui_layer)

	pokedex = PokedexScript.new()
	pokedex.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(pokedex)

	inventory_ui = InventoryScript.new()
	inventory_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(inventory_ui)

	story_dialog = DialogScript.new()
	story_dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(story_dialog)

	starter_select = StarterScript.new()
	starter_select.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(starter_select)
	starter_select.starter_chosen.connect(_on_starter_chosen)

	# Title screen
	var title_layer = CanvasLayer.new()
	title_layer.layer = 30
	add_child(title_layer)
	title_screen = TitleScript.new()
	title_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_layer.add_child(title_screen)
	title_screen.start_game.connect(_on_title_done)

	# Player signals
	player.encountered_pokemon.connect(_on_wild_encounter)
	player.entered_exit.connect(_on_exit_entered)

	# Start paused on title
	GameManager.change_state(GameManager.GameState.PAUSED)

func _on_title_done():
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
	story_dialog.show_dialog("Prof. Oak", [
		"Excellent choice! %s is a wonderful partner!" % starter_name,
		"Your rival chose the Pokemon with a type advantage... typical!",
		"Now go! Collect 8 Gym Badges and challenge the Pokemon League!",
		"And fill your Pokedex along the way!",
	], Callable(self, "_start_adventure"))

func _start_adventure():
	# Load starting area
	var spawn = area_manager.load_area("Pallet Town")
	player.global_position = Vector2(spawn["x"] * 16 + 8, spawn["y"] * 16 + 8)
	GameManager.change_state(GameManager.GameState.WORLD)

func _process(_delta):
	if GameManager.state == GameManager.GameState.WORLD:
		if Input.is_action_just_pressed("open_pokedex"):
			pokedex.toggle()
		if Input.is_action_just_pressed("open_inventory"):
			inventory_ui.toggle(player.get_node("Inventory"))
		# NPC interaction (E key)
		if Input.is_action_just_pressed("interact") and area_manager:
			var npc = area_manager.check_npc(player.global_position.x, player.global_position.y)
			if not npc.is_empty():
				npc_handler.interact_with_npc(npc, area_manager.get_current_area_name())
				# Check gym leader separately
				if area_manager.current_area and not area_manager.current_area.gym_leader.is_empty():
					var gl = area_manager.current_area.gym_leader
					var gl_x = gl.get("x", -1) * 16
					var gl_y = gl.get("y", -1) * 16
					if abs(player.global_position.x - gl_x) < 32 and abs(player.global_position.y - gl_y) < 32:
						_start_gym_battle(gl)

func _on_wild_encounter(encounter_data):
	var species_id = encounter_data.get("species_id", 1)
	var level = randi_range(encounter_data.get("min_level", 2), encounter_data.get("max_level", 5))
	var wild = PokemonScript.new(species_id, level)
	GameManager.add_to_pokedex(wild.id)
	GameManager.change_state(GameManager.GameState.BATTLE)
	var inv = player.get_node("Inventory")
	battle_scene.set_inventory(inv)
	battle_scene.start(GameManager.party, wild, inv)

func _on_exit_entered(exit_data):
	var target_area = exit_data.get("target_area", "")
	var target_x = exit_data.get("target_x", 14)
	var target_y = exit_data.get("target_y", 14)
	if target_area.is_empty():
		return
	var spawn = area_manager.load_area(target_area, target_x, target_y)
	player.global_position = Vector2(spawn["x"] * 16 + 8, spawn["y"] * 16 + 8)
	# Show area name
	story_dialog.show_dialog("", [target_area])

func _on_npc_dialog(speaker, messages):
	story_dialog.show_dialog(speaker, messages)

func _on_npc_battle(npc_data):
	current_npc_battle_data = npc_data
	GameManager.change_state(GameManager.GameState.BATTLE)
	var team = npc_data.get("team", [])
	if team.size() > 0:
		battle_scene.set_inventory(player.get_node("Inventory"))
		if battle_scene.has_method("start_trainer_battle"):
			battle_scene.start_trainer_battle(npc_data.get("name", "Trainer"), team)
		else:
			# Fallback: fight first Pokemon as wild
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
	match result_str:
		"caught":
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
	GameManager.change_state(GameManager.GameState.WORLD)

func _heal_party():
	for pkmn in GameManager.party:
		pkmn.hp = pkmn.max_hp
		pkmn.status = ""
		for move in pkmn.known_moves:
			move["current_pp"] = move["pp"]
