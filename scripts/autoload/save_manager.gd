extends Node

const SAVE_PATH = "user://pokepai_save.json"

func save_game():
	var data = {
		"version": 1,
		"party": _serialize_party(),
		"badges": GameManager.badges_earned,
		"pokedex_caught": GameManager.pokedex_caught.keys(),
		"pokedex_seen": GameManager.pokedex_seen.keys(),
		"current_area": "",
		"player_pos": {"x": 0, "y": 0},
		"inventory": {},
		"story_flags": {},
		"defeated_trainers": {},
		"defeated_gyms": [],
		"towns_visited": GameManager.towns_visited,
	}

	# Get current area from area_manager group
	var area_mgr = get_tree().get_first_node_in_group("area_manager")
	if area_mgr:
		data["current_area"] = area_mgr.get_current_area_name()

	# Get player position
	var player = get_tree().get_first_node_in_group("player")
	if player:
		data["player_pos"] = {"x": player.global_position.x, "y": player.global_position.y}

	# Get inventory
	var inv_node = player.get_node("Inventory") if player else null
	if inv_node:
		data["inventory"] = {"balls": inv_node.balls.duplicate(), "berries": inv_node.berries.duplicate()}

	# Story flags
	data["story_flags"] = StoryEvents.flags.duplicate()

	# NPC handler data
	var npc_h = get_tree().get_first_node_in_group("npc_handler")
	if npc_h:
		data["defeated_trainers"] = npc_h.defeated_trainers.duplicate()
		data["defeated_gyms"] = npc_h.defeated_gyms.duplicate()

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("[SAVE] Game saved!")
		return true
	return false

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return {}
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return {}
	return json.data

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func _serialize_party() -> Array:
	var result = []
	for pkmn in GameManager.party:
		result.append({
			"species_id": pkmn.id,
			"level": pkmn.level,
			"hp": pkmn.hp,
			"max_hp": pkmn.max_hp,
			"xp": pkmn.xp,
			"status": pkmn.status,
			"nature": pkmn.nature if "nature" in pkmn else "Hardy",
		})
	return result

func deserialize_party(party_data: Array) -> Array:
	var PokemonScript = preload("res://scripts/pokemon/pokemon.gd")
	var party = []
	for data in party_data:
		var pkmn = PokemonScript.new(data["species_id"], data["level"])
		pkmn.hp = data.get("hp", pkmn.max_hp)
		pkmn.xp = data.get("xp", 0)
		pkmn.status = data.get("status", "")
		if "nature" in data and "nature" in pkmn:
			pkmn.nature = data["nature"]
			pkmn._apply_nature()
		party.append(pkmn)
	return party
