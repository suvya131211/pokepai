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
var SummaryScript = preload("res://scripts/ui/summary_screen.gd")
var ControlsScript = preload("res://scripts/ui/controls_overlay.gd")

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

var summary_screen = null

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
	npc_handler.add_to_group("npc_handler")
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

	summary_screen = SummaryScript.new()
	summary_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(summary_screen)

	# Title screen
	var title_layer = CanvasLayer.new()
	title_layer.layer = 30
	add_child(title_layer)
	title_screen = TitleScript.new()
	title_layer.add_child(title_screen)
	title_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_screen.start_game.connect(_on_title_done)

	# Controls overlay (press H) — highest layer, always accessible
	var controls_layer = CanvasLayer.new()
	controls_layer.layer = 50  # above title screen (30), battle (20), UI (25)
	add_child(controls_layer)
	var controls = ControlsScript.new()
	controls.set_anchors_preset(Control.PRESET_FULL_RECT)
	controls_layer.add_child(controls)

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
	SoundManager.play_sfx("catch_success")
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
	SoundManager.play_music("overworld")
	_trigger_area_story("Pallet Town")

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
			# Fishing (E facing water)
			elif GameManager.party.size() > 0 and area_manager.current_area:
				var face_dx_f = 0
				var face_dy_f = 0
				match player.direction:
					"up": face_dy_f = -1
					"down": face_dy_f = 1
					"left": face_dx_f = -1
					"right": face_dx_f = 1
				var fx = int(player.global_position.x / 16) + face_dx_f
				var fy = int(player.global_position.y / 16) + face_dy_f
				var tile = area_manager.current_area.get_tile(fx, fy)
				if tile == area_manager.current_area.Tile.WATER:
					_try_fishing()
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

		# Trainer line-of-sight
		if npc_interaction_cooldown <= 0:
			var los_trainer = area_manager.check_trainer_los(player.global_position.x, player.global_position.y)
			if not los_trainer.is_empty():
				# Use same key format as npc_handler: "area_name:npc_name"
				var npc_key = area_manager.get_current_area_name() + ":" + los_trainer.get("name", "")
				if not npc_handler.is_defeated(npc_key):
					npc_interaction_cooldown = 5.0
					npc_handler.interact_with_npc(los_trainer, area_manager.get_current_area_name())

func _try_fishing():
	if randf() < 0.6:  # 60% chance to hook something
		# Water Pokemon encounter
		var water_pokemon = [
			{"species_id": 3, "min_level": 5, "max_level": 15},   # Squirtle
			{"species_id": 17, "min_level": 10, "max_level": 20},  # Gyarados (rare)
		]
		var entry = water_pokemon[0] if randf() < 0.8 else water_pokemon[1]
		story_dialog.show_dialog("", ["...!", "A Pokemon is on the hook!"], Callable(self, "_on_wild_encounter").bind(entry))
	else:
		story_dialog.show_dialog("", ["Not even a nibble..."])

func _on_wild_encounter(encounter_data):
	if GameManager.state != GameManager.GameState.WORLD:
		return  # Don't trigger encounters during other states
	SoundManager.play_encounter_jingle()
	ScreenTransition.battle_transition()
	# Check repel
	var inv = player.get_node("Inventory")
	if inv.repel_steps > 0:
		inv.repel_steps -= 1
		if inv.repel_steps == 0:
			_show_area_name("Repel wore off!")
		return
	SoundManager.play_music("battle")
	var species_id = encounter_data.get("species_id", 1)
	var level = randi_range(encounter_data.get("min_level", 2), encounter_data.get("max_level", 5))
	var wild = PokemonScript.new(species_id, level)
	print("[MAIN] Wild encounter: %s Lv.%d, party size: %d" % [wild.pokemon_name, level, GameManager.party.size()])
	EventTracker.log_event("WILD_ENCOUNTER", {"species_id": species_id, "level": level, "area": area_manager.get_current_area_name()})
	GameManager.add_to_pokedex(wild.id)
	GameManager.change_state(GameManager.GameState.BATTLE)
	battle_scene.set_inventory(inv)
	battle_scene.start(GameManager.party, wild, inv)

func _on_exit_entered(exit_data):
	var target_area = exit_data.get("target_area", "")
	var target_x = exit_data.get("target_x", 14)
	var target_y = exit_data.get("target_y", 14)
	print("[MAIN] Exit triggered → %s at (%d, %d)" % [target_area, target_x, target_y])
	if target_area.is_empty():
		return

	# Pokemon League gate — require 8 badges
	if target_area == "Pokemon League" and npc_handler.get_badge_count() < 8:
		story_dialog.show_dialog("Guard", [
			"Halt! You need all 8 Gym Badges to enter the Pokemon League!",
			"You currently have %d/8 badges." % npc_handler.get_badge_count(),
			"Go back and defeat more Gym Leaders!",
		])
		player.exit_cooldown = 3.0
		return  # Don't transition
	SoundManager.play_sfx("door")
	ScreenTransition.transition(Callable(self, "_do_area_transition").bind(target_area, target_x, target_y))

func _do_area_transition(target_area, target_x, target_y):
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
	# Auto-save on area transition
	SaveManager.save_game()
	# Show area name as a non-blocking notification
	_show_area_name(target_area)
	# Play area-appropriate music
	if area_manager.current_area:
		match area_manager.current_area.area_type:
			"town": SoundManager.play_music("town")
			"route": SoundManager.play_music("overworld")
			"cave": SoundManager.play_music("cave")
			"league": SoundManager.play_music("gym")
			_: SoundManager.play_music("overworld")
	# Trigger story events for new area
	_trigger_area_story(target_area)

func _trigger_area_story(area_name: String):
	var events = StoryEvents.get_area_events(area_name)
	if events.is_empty():
		return
	# Chain dialogs — show first, then chain the rest via callbacks
	_pending_story_events = events.duplicate()
	_show_next_story_event()

var _pending_story_events: Array = []

func _show_next_story_event():
	if _pending_story_events.is_empty():
		return
	var event = _pending_story_events.pop_front()
	var speaker = event.get("speaker", "")
	var lines = event.get("lines", [])
	if _pending_story_events.is_empty():
		story_dialog.show_dialog(speaker, lines)
	else:
		story_dialog.show_dialog(speaker, lines, Callable(self, "_show_next_story_event"))

func _show_gym_victory_story(gym_name: String, badge: String):
	var badge_count = npc_handler.get_badge_count()
	var story_lines = []

	match gym_name:
		"Brock":
			story_lines = [
				"Brock: You've got real talent, kid!",
				"Take the Boulder Badge as proof of your victory.",
				"The path east leads to Mt. Moon. Be careful in those caves.",
				"I've heard strange things about Team Shadow lurking there...",
				"Badge 1/8 collected!",
			]
		"Misty":
			story_lines = [
				"Misty: Wow! Your Pokemon are impressive!",
				"Here's the Cascade Badge. You've earned it!",
				"The dark energy near the river... I think it's connected to something bigger.",
				"Head south through Route 3 to reach Vermilion City.",
				"Badge 2/8 collected!",
			]
		"Lt. Surge":
			story_lines = [
				"Lt. Surge: Now THAT was an electrifying battle!",
				"The Thunder Badge is yours, soldier!",
				"I've been monitoring some strange signals from Celadon City.",
				"Team Shadow might be operating a base there. Stay sharp!",
				"Badge 3/8 collected!",
			]
		"Erika":
			story_lines = [
				"Erika: What a beautiful battle! Your bond with your Pokemon is lovely.",
				"Please accept the Rainbow Badge!",
				"I've sensed the Void Energy affecting the plants in my garden...",
				"Koga's Gym is also here in Celadon. You'll need his badge too.",
				"Badge 4/8 collected!",
			]
		_:
			# Generic for Koga, Sabrina, Blaine, Giovanni
			story_lines = [
				"%s: Well fought! You've proven yourself worthy." % gym_name,
				"Take the %s as a symbol of your strength!" % badge,
				"Badge %d/8 collected!" % badge_count,
			]

	if badge_count >= 8:
		story_lines.append("")
		story_lines.append("You've collected all 8 badges!")
		story_lines.append("The Pokemon League Championship is now open to you!")
		story_lines.append("Head north from Saffron City to reach the Pokemon League!")
		story_lines.append("The Elite Four and the Champion await your challenge!")
	elif badge_count >= 5:
		story_lines.append("You're getting closer to the Pokemon League!")
		story_lines.append("Keep collecting badges — %d more to go!" % (8 - badge_count))

	story_dialog.show_dialog(gym_name, story_lines)

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
	SoundManager.play_music("battle")
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
	SoundManager.play_music("gym")
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
			if GameManager.party.size() < 6:
				GameManager.party.append(wild)
				player.follower_pokemon = wild
				player._follower_pos = player.global_position
				story_dialog.show_dialog("", ["You caught %s!" % wild.pokemon_name])
			else:
				PCStorage.deposit(wild)
				story_dialog.show_dialog("", ["You caught %s!" % wild.pokemon_name, "Party is full! %s was sent to the PC." % wild.pokemon_name])
			GameManager.add_to_pokedex(wild.id, true)
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
					var gym_name = current_npc_battle_data.get("name", "")
					npc_handler.mark_gym_defeated(badge)
					StoryEvents.on_gym_defeated(gym_name, badge)
					GameManager.badges_earned = npc_handler.get_badge_count()
					var win_msgs = current_npc_battle_data.get("win_dialog", [])
					if win_msgs.size() > 0:
						story_dialog.show_dialog(current_npc_battle_data.get("name", ""), win_msgs)
					_show_gym_victory_story(gym_name, badge)
				if current_npc_battle_data.get("is_champion", false):
					StoryEvents.on_champion_defeated()
					# Check postgame
					var postgame = StoryEvents.get_postgame_events()
					if not postgame.is_empty():
						_pending_story_events = postgame.duplicate()
						_show_next_story_event()
					story_dialog.show_dialog("Prof. Oak", [
						"...",
						"I can't believe it... You've done it!",
						"You've defeated the Champion and saved the region from the Void!",
						"MEWTWO's barrier has been restored. DARKRAI has been sealed away.",
						"The Pokemon of the world are safe, thanks to you.",
						"",
						"You started as a young trainer from Pallet Town...",
						"And now you are the Pokemon League CHAMPION!",
						"",
						"But your journey doesn't end here.",
						"There are still Pokemon to discover, battles to fight, and friends to make.",
						"",
						"Thank you for playing POKEPAI!",
						"--- THE END ---",
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
	# Restore area music
	if area_manager and area_manager.current_area:
		match area_manager.current_area.area_type:
			"town": SoundManager.play_music("town")
			"cave": SoundManager.play_music("cave")
			_: SoundManager.play_music("overworld")
	else:
		SoundManager.play_music("overworld")
	GameManager.change_state(GameManager.GameState.WORLD)

func _on_shop():
	var inv = player.get_node("Inventory")
	inv.balls["pokeball"] += 5
	inv.balls["greatball"] += 2
	inv.potions["potion"] += 3
	inv.potions["super_potion"] += 1
	inv.medicine["antidote"] += 2
	inv.key_items["repel"] = inv.key_items.get("repel", 0) + 3
	inv.key_items["escape_rope"] = inv.key_items.get("escape_rope", 0) + 1
	story_dialog.show_dialog("Shopkeeper", [
		"Here are some items for your journey!",
		"Got: 5 Pokeballs, 2 Great Balls",
		"3 Potions, 1 Super Potion",
		"2 Antidotes, 3 Repels, 1 Escape Rope!",
	])

func player_pokemon_hurt() -> bool:
	if GameManager.party.size() > 0:
		var p = GameManager.party[0]
		return p.hp < p.max_hp
	return false

func _heal_party():
	SoundManager.play_sfx("heal")
	EventTracker.log_event("PARTY_HEALED", {})
	for pkmn in GameManager.party:
		pkmn.hp = pkmn.max_hp
		pkmn.status = ""
		for move in pkmn.known_moves:
			move["current_pp"] = move["pp"]

func _check_fly() -> bool:
	for pkmn in GameManager.party:
		for move in pkmn.known_moves:
			if move.get("name", "") == "Fly":
				return true
	return false

func _open_fly_menu():
	GameManager.show_fly_menu = true

func _fly_to(town_name: String):
	GameManager.show_fly_menu = false
	EventTracker.log_event("FLY", {"to": town_name})
	# Use screen transition for smooth fly
	ScreenTransition.transition(Callable(self, "_do_fly_land").bind(town_name))

func _do_fly_land(town_name: String):
	var spawn = area_manager.load_area(town_name)
	if spawn.is_empty():
		GameManager.change_state(GameManager.GameState.WORLD)
		return
	var sx = spawn["x"]
	var sy = spawn["y"]
	var area_w = 30
	var area_h = 20
	if area_manager.current_area:
		area_w = area_manager.current_area.width
		area_h = area_manager.current_area.height
		# Find walkable position near center
		var found = false
		for try_x in [area_w / 2, area_w / 2 + 1, area_w / 2 - 1, sx]:
			for try_y in [area_h / 2, area_h / 2 + 1, sy]:
				if area_manager.current_area.is_walkable(try_x, try_y):
					sx = try_x
					sy = try_y
					found = true
					break
			if found: break
	player.global_position = Vector2(sx * 16 + 8, sy * 16 + 8)
	player.exit_cooldown = 3.0
	npc_interaction_cooldown = 3.0
	GameManager.change_state(GameManager.GameState.WORLD)
	_show_area_name("Flew to %s!" % town_name)
	SoundManager.play_sfx("door")

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F5:
			_save_game()
		elif event.keycode == KEY_F9:
			_load_game()
		elif event.keycode == KEY_C and GameManager.state == GameManager.GameState.WORLD:
			if GameManager.party.size() > 0 and summary_screen:
				summary_screen.show_summary(GameManager.party[0], 0)
		elif event.keycode == KEY_T and GameManager.state == GameManager.GameState.WORLD:
			if _check_fly():
				_open_fly_menu()
			else:
				story_dialog.show_dialog("", ["No Pokemon knows Fly!"])
		elif GameManager.show_fly_menu and event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var idx = event.keycode - KEY_1
			if idx < GameManager.towns_visited.size():
				_fly_to(GameManager.towns_visited[idx])
			else:
				GameManager.show_fly_menu = false
		elif GameManager.show_fly_menu and event.keycode == KEY_ESCAPE:
			GameManager.show_fly_menu = false

func _save_game():
	if SaveManager.save_game():
		story_dialog.show_dialog("", ["Game saved!"])

func _load_game():
	var data = SaveManager.load_game()
	if data.is_empty():
		story_dialog.show_dialog("", ["No save file found!"])
		return
	# Restore party
	GameManager.party = SaveManager.deserialize_party(data.get("party", []))
	GameManager.badges_earned = data.get("badges", 0)
	GameManager.pokedex_caught = {}
	for id in data.get("pokedex_caught", []):
		GameManager.pokedex_caught[int(id)] = true
	GameManager.pokedex_seen = {}
	for id in data.get("pokedex_seen", []):
		GameManager.pokedex_seen[int(id)] = true
	GameManager.towns_visited = data.get("towns_visited", ["Starter Town"])
	# Story flags
	StoryEvents.flags = data.get("story_flags", StoryEvents.flags)
	# NPC handler
	if npc_handler:
		npc_handler.defeated_trainers = data.get("defeated_trainers", {})
		npc_handler.defeated_gyms = data.get("defeated_gyms", [])
	# Inventory
	var inv = player.get_node("Inventory")
	var inv_data = data.get("inventory", {})
	if inv and not inv_data.is_empty():
		inv.balls = inv_data.get("balls", inv.balls)
		inv.berries = inv_data.get("berries", inv.berries)
	# Load area
	var area_name = data.get("current_area", "Pallet Town")
	var pos = data.get("player_pos", {"x": 232, "y": 168})
	area_manager.load_area(area_name)
	player.global_position = Vector2(pos["x"], pos["y"])
	if GameManager.party.size() > 0:
		player.follower_pokemon = GameManager.party[0]
	GameManager.change_state(GameManager.GameState.WORLD)
	story_dialog.show_dialog("", ["Game loaded!"])

func _on_item_found(item_type: String):
	SoundManager.play_sfx("item")
	if item_type == "ultraball":
		var inv = player.get_node("Inventory")
		inv.balls["ultraball"] = inv.balls.get("ultraball", 0) + 1
		_show_area_name("Found Ultra Ball!")
	elif item_type in ["razz", "nanab", "pinap"]:
		if GameManager.party.size() > 0:
			var lead = GameManager.party[0]
			if lead.hp < lead.max_hp:
				lead.hp = mini(lead.max_hp, lead.hp + 10)
				_show_area_name("Berry: %s +10 HP!" % lead.pokemon_name)
			else:
				_show_area_name("Found %s berry!" % item_type.capitalize())
	else:
		_show_area_name("Found %s!" % item_type.capitalize())
