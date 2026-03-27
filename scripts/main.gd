extends Node2D

@onready var chunk_manager = $World/ChunkManager
@onready var player = $World/Player
@onready var camera: Camera2D = $World/Player/Camera2D

var spawner
var battle_scene
var catch_scene
var hud
var pokedex
var inventory_ui
var day_night
var weather

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
var CatchScript = preload("res://scripts/battle/catch_game.gd")
var PokedexScript = preload("res://scripts/ui/pokedex.gd")
var InventoryScript = preload("res://scripts/ui/inventory_ui.gd")

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

	# Catch scene (overlay)
	catch_scene = CatchScript.new()
	catch_scene.visible = false
	catch_scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_layer.add_child(catch_scene)
	catch_scene.catch_ended.connect(_on_catch_ended)

	# Pokedex (overlay)
	pokedex = PokedexScript.new()
	pokedex.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 25
	ui_layer.add_child(pokedex)
	add_child(ui_layer)

	# Inventory (overlay)
	inventory_ui = InventoryScript.new()
	inventory_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(inventory_ui)

	# Init legendary positions
	legendary1_pos = Vector2(randf_range(-500, 500), randf_range(-500, 500))
	legendary2_pos = Vector2(randf_range(-500, 500), randf_range(-500, 500))

func _process(delta: float) -> void:
	if GameManager.state == GameManager.GameState.WORLD:
		# Check encounters
		var wild = spawner.check_encounter(player)
		if wild:
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
	battle_scene.start(GameManager.party, wild)

func _on_battle_ended(result: String, wild) -> void:
	match result:
		"defeated":
			# Check evolution
			for i in GameManager.party.size():
				var pkmn = GameManager.party[i]
				if pkmn.can_evolve():
					var evolved = pkmn.evolve()
					GameManager.party[i] = evolved
					if player.follower_pokemon == pkmn:
						player.follower_pokemon = evolved
			GameManager.change_state(GameManager.GameState.WORLD)
		"fled":
			GameManager.change_state(GameManager.GameState.WORLD)
		"catch":
			# Switch to catch scene
			var inv = player.get_node("Inventory")
			catch_scene.start(wild, inv)
			GameManager.change_state(GameManager.GameState.CATCH)

func _on_catch_ended(result: String, wild) -> void:
	if result == "caught":
		GameManager.party.append(wild)
		GameManager.add_to_pokedex(wild.id, true)
		GameManager.pokemon_caught.emit(wild)
		player.follower_pokemon = wild
		player._follower_pos = player.global_position
	GameManager.change_state(GameManager.GameState.WORLD)

func _update_legendaries(delta: float) -> void:
	if legendary1_active:
		var flee_dir = (legendary1_pos - player.global_position).normalized()
		legendary1_pos += flee_dir * 20 * delta
	if legendary2_active:
		var flee_dir2 = (legendary2_pos - player.global_position).normalized()
		legendary2_pos += flee_dir2 * 20 * delta
