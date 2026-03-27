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
var status: String = ""  # "sleep" / "paralyzed" / ""

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

func calc_damage(defender) -> Dictionary:
	var eff := PokemonDB.get_effectiveness(type, defender.type)
	var base := int(((2.0 * level + 10.0) / 250.0) * (float(atk) / float(defender.def_stat)) * 50.0 + 2.0)
	var dmg := maxi(1, int(base * eff * randf_range(0.85, 1.0)))
	var text := ""
	if eff > 1.0: text = "Super effective!"
	elif eff < 1.0 and eff > 0: text = "Not very effective..."
	elif eff == 0: text = "No effect!"
	return {"damage": dmg, "effectiveness": eff, "text": text}

func get_catch_rate() -> float:
	var hp_factor := 1.0 - (float(hp) / float(max_hp)) * 0.7
	var rarity_weights = {1: 0.7, 2: 0.45, 3: 0.25, 4: 0.05}
	var rarity_factor = rarity_weights.get(species["rarity"], 0.5)
	return hp_factor * rarity_factor
