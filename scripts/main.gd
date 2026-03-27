extends Node2D

@onready var chunk_manager = $World/ChunkManager
@onready var player = $World/Player
@onready var camera: Camera2D = $World/Player/Camera2D

var spawner
var battle_scene
var hud
var pokedex
var inventory_ui
var day_night
var weather
var title_screen
var story_dialog
var ui_layer: CanvasLayer

# Roaming legendaries
var legendary1_pos: Vector2
var legendary2_pos: Vector2
var legendary1_active: bool = true
var legendary2_active: bool = true

# Preload scripts
var PokemonScript = preload("res://scripts/pokemon/pokemon.gd")
var SpawnerScript = preload("res://scripts/pokemon/spawner.gd")
var DayNightScript = preload("res://scripts/world/day_night.gd")
var WeatherScript = preload("res://scripts/world/weather.gd")
var HUDScript = preload("res://scripts/ui/hud.gd")
var BattleScript = preload("res://scripts/battle/battle.gd")
var PokedexScript = preload("res://scripts/ui/pokedex.gd")
var InventoryScript = preload("res://scripts/ui/inventory_ui.gd")
var TitleScript = preload("res://scripts/ui/title_screen.gd")
var DialogScript = preload("res://scripts/ui/story_dialog.gd")
var InstructionsScript = preload("res://scripts/ui/instructions_panel.gd")

func _ready() -> void:
	# Give player a starter
	var starter = PokemonScript.new(4, 5)  # Buzzer lv5
	GameManager.party.append(starter)
	player.follower_pokemon = starter

	# Spawner
	spawner = SpawnerScript.new()
	add_child(spawner)

	# Day/Night (CanvasModulate)
	day_night = DayNightScript.new()
	$World.add_child(day_night)

	# Weather (rendered on CanvasLayer for screen-space)
	var weather_layer := CanvasLayer.new()
	weather_layer.layer = 5
	add_child(weather_layer)
	weather = WeatherScript.new()
	weather_layer.add_child(weather)

	# HUD
	hud = HUDScript.new()
	add_child(hud)

	# Battle scene (overlay)
	battle_scene = BattleScript.new()
	battle_scene.visible = false
	battle_scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	var battle_layer := CanvasLayer.new()
	battle_layer.layer = 20
	battle_layer.add_child(battle_scene)
	add_child(battle_layer)
	battle_scene.battle_ended.connect(_on_battle_ended)

	# UI layer (pokedex, inventory, story dialog)
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 25
	add_child(ui_layer)

	# Pokedex (overlay)
	pokedex = PokedexScript.new()
	pokedex.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(pokedex)

	# Inventory (overlay)
	inventory_ui = InventoryScript.new()
	inventory_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(inventory_ui)

	# Story dialog (reusable, on UI layer)
	story_dialog = DialogScript.new()
	story_dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(story_dialog)

	# Instructions panel
	var instructions = InstructionsScript.new()
	instructions.set_anchors_preset(Control.PRESET_FULL_RECT)
	instructions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(instructions)

	# Init legendary positions
	legendary1_pos = Vector2(randf_range(-500, 500), randf_range(-500, 500))
	legendary2_pos = Vector2(randf_range(-500, 500), randf_range(-500, 500))

	# Connect player town signal if available
	if player.has_signal("entered_town"):
		player.entered_town.connect(_on_enter_town)

	# Title screen (topmost layer)
	var title_layer := CanvasLayer.new()
	title_layer.layer = 30
	add_child(title_layer)
	title_screen = TitleScript.new()
	title_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_layer.add_child(title_screen)
	title_screen.start_game.connect(_on_title_done)
	GameManager.change_state(GameManager.GameState.PAUSED)

func _on_title_done() -> void:
	GameManager.change_state(GameManager.GameState.WORLD)
	# Professor Willow intro dialog
	story_dialog.show_dialog("Prof. Willow", [
		"Welcome to the world of Pokemon!",
		"I'm Professor Willow. I study Pokemon in the wild.",
		"A dark force has awakened... VOIDREX threatens our world.",
		"Only by finding the legendary COSMEON can we restore balance.",
		"Take this Pikachu and begin your journey!",
		"Catch Pokemon, grow stronger, and save us all!",
	])

func _on_enter_town(town_info: Dictionary) -> void:
	story_dialog.show_dialog("", [
		"You've discovered %s!" % town_info["name"],
		"This town has been added to your fast-travel map.",
	])

func _process(delta: float) -> void:
	if GameManager.state == GameManager.GameState.WORLD:
		# Check for nearby overworld Pokemon
		var nearby = chunk_manager.get_nearby_pokemon(player.global_position, 16.0)
		if nearby.size() > 0:
			var owp = nearby[0]
			var PokemonScript = preload("res://scripts/pokemon/pokemon.gd")
			var wild = PokemonScript.new(owp.pokemon_data["id"], owp.level)
			owp.queue_free()  # remove from overworld
			_start_battle(wild)

		# Pokedex toggle
		if Input.is_action_just_pressed("open_pokedex"):
			pokedex.toggle()

		# Inventory toggle
		if Input.is_action_just_pressed("open_inventory"):
			inventory_ui.toggle(player.get_node("Inventory"))

		# Update legendary positions (roam away from player)
		_update_legendaries(delta)

func _start_battle(wild) -> void:
	GameManager.add_to_pokedex(wild.id)
	GameManager.change_state(GameManager.GameState.BATTLE)
	battle_scene.set_inventory(player.get_node("Inventory"))
	battle_scene.start(GameManager.party, wild)

func _on_battle_ended(result_str: String, wild) -> void:
	match result_str:
		"caught":
			_handle_caught(wild)
		"defeated":
			_check_evolution()
		"fled":
			pass
	GameManager.change_state(GameManager.GameState.WORLD)

func _handle_caught(wild) -> void:
	GameManager.party.append(wild)
	GameManager.add_to_pokedex(wild.id, true)
	GameManager.pokemon_caught.emit(wild)
	player.follower_pokemon = wild
	player._follower_pos = player.global_position
	# Legendary catch story dialogs
	if wild.id == 19:  # Mewtwo
		GameManager.change_state(GameManager.GameState.WORLD)
		story_dialog.show_dialog("???", [
			"You've captured MEWTWO!",
			"Its psychic power resonates with hope...",
			"The balance of the world shifts in your favor.",
		])
	elif wild.id == 20:  # Darkrai
		GameManager.change_state(GameManager.GameState.WORLD)
		story_dialog.show_dialog("???", [
			"DARKRAI has been caught!",
			"The darkness recedes... The world is saved!",
			"Congratulations, Pokemon Master!",
		])

func _check_evolution() -> void:
	pass  # Placeholder for future evolution logic

func _update_legendaries(delta: float) -> void:
	if legendary1_active:
		var flee_dir = (legendary1_pos - player.global_position).normalized()
		legendary1_pos += flee_dir * 20 * delta
	if legendary2_active:
		var flee_dir2 = (legendary2_pos - player.global_position).normalized()
		legendary2_pos += flee_dir2 * 20 * delta
