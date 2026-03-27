extends Node2D

@onready var chunk_manager: ChunkManager = $World/ChunkManager
@onready var player: PlayerCharacter = $World/Player
@onready var camera: Camera2D = $World/Player/Camera2D

var spawner: PokemonSpawner
var battle_scene: BattleScene
var catch_scene: CatchScene
var hud: GameHUD
var pokedex: PokedexUI
var inventory_ui: InventoryUI
var day_night: DayNightCycle
var weather: WeatherSystem

# Roaming legendaries
var legendary1_pos: Vector2
var legendary2_pos: Vector2
var legendary1_active: bool = true
var legendary2_active: bool = true

func _ready() -> void:
	# Give player a starter
	var starter := Pokemon.new(4, 5)  # Buzzer lv5
	GameManager.party.append(starter)
	player.follower_pokemon = starter

	# Spawner
	spawner = PokemonSpawner.new()
	add_child(spawner)

	# Day/Night (CanvasModulate)
	day_night = DayNightCycle.new()
	$World.add_child(day_night)

	# Weather (rendered on CanvasLayer for screen-space)
	var weather_layer := CanvasLayer.new()
	weather_layer.layer = 5
	add_child(weather_layer)
	weather = WeatherSystem.new()
	weather_layer.add_child(weather)

	# HUD
	hud = GameHUD.new()
	add_child(hud)

	# Battle scene (overlay)
	battle_scene = BattleScene.new()
	battle_scene.visible = false
	battle_scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	var battle_layer := CanvasLayer.new()
	battle_layer.layer = 20
	battle_layer.add_child(battle_scene)
	add_child(battle_layer)
	battle_scene.battle_ended.connect(_on_battle_ended)

	# Catch scene (overlay)
	catch_scene = CatchScene.new()
	catch_scene.visible = false
	catch_scene.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_layer.add_child(catch_scene)
	catch_scene.catch_ended.connect(_on_catch_ended)

	# Pokedex (overlay)
	pokedex = PokedexUI.new()
	pokedex.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ui_layer := CanvasLayer.new()
	ui_layer.layer = 25
	ui_layer.add_child(pokedex)
	add_child(ui_layer)

	# Inventory (overlay)
	inventory_ui = InventoryUI.new()
	inventory_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(inventory_ui)

	# Init legendary positions
	legendary1_pos = Vector2(randf_range(-500, 500), randf_range(-500, 500))
	legendary2_pos = Vector2(randf_range(-500, 500), randf_range(-500, 500))

func _process(delta: float) -> void:
	if GameManager.state == GameManager.GameState.WORLD:
		# Check encounters
		var wild := spawner.check_encounter(player)
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

func _start_battle(wild: Pokemon) -> void:
	GameManager.add_to_pokedex(wild.id)
	GameManager.change_state(GameManager.GameState.BATTLE)
	battle_scene.start(GameManager.party, wild)

func _on_battle_ended(result: String, wild: Pokemon) -> void:
	match result:
		"defeated":
			# Check evolution
			for i in GameManager.party.size():
				var pkmn: Pokemon = GameManager.party[i]
				if pkmn.can_evolve():
					var evolved := pkmn.evolve()
					GameManager.party[i] = evolved
					if player.follower_pokemon == pkmn:
						player.follower_pokemon = evolved
			GameManager.change_state(GameManager.GameState.WORLD)
		"fled":
			GameManager.change_state(GameManager.GameState.WORLD)
		"catch":
			# Switch to catch scene
			var inv: PlayerInventory = player.get_node("Inventory")
			catch_scene.start(wild, inv)
			GameManager.change_state(GameManager.GameState.CATCH)

func _on_catch_ended(result: String, wild: Pokemon) -> void:
	if result == "caught":
		GameManager.party.append(wild)
		GameManager.add_to_pokedex(wild.id, true)
		GameManager.pokemon_caught.emit(wild)
		player.follower_pokemon = wild
		player._follower_pos = player.global_position
	GameManager.change_state(GameManager.GameState.WORLD)

func _update_legendaries(delta: float) -> void:
	if legendary1_active:
		var flee_dir := (legendary1_pos - player.global_position).normalized()
		legendary1_pos += flee_dir * 20 * delta
	if legendary2_active:
		var flee_dir := (legendary2_pos - player.global_position).normalized()
		legendary2_pos += flee_dir * 20 * delta
