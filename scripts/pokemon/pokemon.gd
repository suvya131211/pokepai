extends RefCounted
class_name Pokemon

var species: Dictionary
var id: int
var pokemon_name: String
var type: String
var color: Color
var level: int
var max_hp: int
var hp: int
var atk: int
var def_stat: int
var xp: int = 0
var xp_to_next: int
var status: String = ""  # "sleep" / "paralyzed" / "poisoned" / ""

var known_moves: Array = []  # array of move dicts (with current_pp included)
var move_pp: Array = []       # current PP for each move (mirrors known_moves current_pp)

func _init(species_id: int, lvl: int = 1) -> void:
	species = PokemonDB.get_species(species_id)
	id = species_id
	pokemon_name = species["name"]
	type = species["type"]
	color = species["color"]
	level = lvl
	max_hp = int(species["hp"] * (1.0 + level * 0.1))
	hp = max_hp
	atk = int(species["atk"] * (1.0 + level * 0.05))
	def_stat = int(species["def"] * (1.0 + level * 0.05))
	xp_to_next = level * 20

	# Load moves from MoveData autoload
	var move_names = MoveData.get_default_moves(species_id)
	for mname in move_names:
		var mdata = MoveData.get_move(mname)
		if not mdata.is_empty():
			mdata["name"] = mname
			mdata["current_pp"] = mdata["pp"]
			known_moves.append(mdata)
			move_pp.append(mdata["pp"])

func gain_xp(amount: int) -> bool:
	xp += amount
	if xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = level * 20
		max_hp = int(species["hp"] * (1.0 + level * 0.1))
		hp = min(hp + 5, max_hp)
		atk = int(species["atk"] * (1.0 + level * 0.05))
		def_stat = int(species["def"] * (1.0 + level * 0.05))
		return true  # leveled up
	return false

func is_alive() -> bool:
	return hp > 0

func can_evolve() -> bool:
	return species.has("evolves_to") and level >= species.get("evolve_level", 999)

func evolve():
	var evolved = get_script().new(species["evolves_to"], level)
	evolved.hp = hp
	evolved.xp = xp
	evolved.xp_to_next = xp_to_next
	return evolved

func use_move(index: int) -> Dictionary:
	if index < 0 or index >= known_moves.size():
		return {}
	var move = known_moves[index]
	if move["current_pp"] <= 0:
		return {}
	move["current_pp"] -= 1
	move_pp[index] = move["current_pp"]
	return move

func calc_damage_with_move(defender, move: Dictionary) -> Dictionary:
	if move.is_empty():
		return {"damage": 0, "effectiveness": 1.0, "text": "No PP left!", "move_name": ""}
	if move["category"] == "status" or move["power"] == 0:
		return _apply_status_move(defender, move)
	# Accuracy check
	if randi_range(1, 100) > move["accuracy"]:
		return {"damage": 0, "effectiveness": 1.0, "text": "But it missed!", "move_name": move.get("name", "")}
	var eff = PokemonDB.get_effectiveness(move["type"], defender.type)
	if eff == 0.0:
		return {"damage": 0, "effectiveness": 0.0, "text": "No effect!", "move_name": move.get("name", "")}
	# STAB bonus (1.5x if move type matches user type)
	var stab = 1.5 if move["type"] == type else 1.0
	var atk_stat = atk
	var def_stat_val = defender.def_stat
	var power = move["power"]
	var base = int(((2.0 * level + 10.0) / 250.0) * (float(atk_stat) / float(def_stat_val)) * power + 2.0)
	var dmg = maxi(1, int(base * eff * stab * randf_range(0.85, 1.0)))
	# False Swipe: always leave 1 HP
	if move["effect"] == "false_swipe" and defender.hp - dmg < 1:
		dmg = maxi(0, defender.hp - 1)
	# Apply flinch / secondary effects on hit
	if move["effect"] == "paralyze" and randf() < 0.3:
		if defender.status == "":
			defender.status = "paralyzed"
	elif move["effect"] == "poison" and randf() < 0.3:
		if defender.status == "":
			defender.status = "poisoned"
	var eff_text = ""
	if eff > 1.0: eff_text = "Super effective!"
	elif eff < 1.0 and eff > 0: eff_text = "Not very effective..."
	return {"damage": dmg, "effectiveness": eff, "text": eff_text, "move_name": move.get("name", "")}

func _apply_status_move(defender, move: Dictionary) -> Dictionary:
	# Accuracy check
	if randi_range(1, 100) > move["accuracy"]:
		return {"damage": 0, "effectiveness": 1.0, "text": "But it missed!", "move_name": move.get("name", "")}
	match move["effect"]:
		"sleep":
			if defender.status != "":
				return {"damage": 0, "effectiveness": 1.0, "text": "It won't affect %s..." % defender.pokemon_name, "move_name": move.get("name", "")}
			defender.status = "sleep"
			return {"damage": 0, "effectiveness": 1.0, "text": "%s fell asleep!" % defender.pokemon_name, "move_name": move.get("name", "")}
		"paralyze":
			if defender.status != "":
				return {"damage": 0, "effectiveness": 1.0, "text": "It won't affect %s..." % defender.pokemon_name, "move_name": move.get("name", "")}
			defender.status = "paralyzed"
			return {"damage": 0, "effectiveness": 1.0, "text": "%s is paralyzed!" % defender.pokemon_name, "move_name": move.get("name", "")}
		"poison":
			if defender.status != "":
				return {"damage": 0, "effectiveness": 1.0, "text": "It won't affect %s..." % defender.pokemon_name, "move_name": move.get("name", "")}
			defender.status = "poisoned"
			return {"damage": 0, "effectiveness": 1.0, "text": "%s was poisoned!" % defender.pokemon_name, "move_name": move.get("name", "")}
		"lower_atk":
			defender.atk = int(defender.atk * 0.8)
			return {"damage": 0, "effectiveness": 1.0, "text": "%s's attack fell!" % defender.pokemon_name, "move_name": move.get("name", "")}
		"lower_def":
			defender.def_stat = int(defender.def_stat * 0.8)
			return {"damage": 0, "effectiveness": 1.0, "text": "%s's defense fell!" % defender.pokemon_name, "move_name": move.get("name", "")}
	return {"damage": 0, "effectiveness": 1.0, "text": "But nothing happened!", "move_name": move.get("name", "")}

# Legacy compatibility: calc_damage uses first move by default
func calc_damage(defender) -> Dictionary:
	if known_moves.size() > 0:
		return calc_damage_with_move(defender, known_moves[0])
	# Fallback: type-based damage with no named move
	var eff := PokemonDB.get_effectiveness(type, defender.type)
	var base := int(((2.0 * level + 10.0) / 250.0) * (float(atk) / float(defender.def_stat)) * 50.0 + 2.0)
	var dmg := maxi(1, int(base * eff * randf_range(0.85, 1.0)))
	var text := ""
	if eff > 1.0: text = "Super effective!"
	elif eff < 1.0 and eff > 0: text = "Not very effective..."
	elif eff == 0: text = "No effect!"
	return {"damage": dmg, "effectiveness": eff, "text": text, "move_name": ""}

func get_catch_rate() -> float:
	var hp_factor := 1.0 - (float(hp) / float(max_hp)) * 0.7
	var rarity_weights = {1: 0.7, 2: 0.45, 3: 0.25, 4: 0.05}
	var rarity_factor = rarity_weights.get(species["rarity"], 0.5)
	return hp_factor * rarity_factor
