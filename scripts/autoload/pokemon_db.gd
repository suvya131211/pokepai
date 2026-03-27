extends Node

# Pokemon species data — 20 species
var species: Array[Dictionary] = [
	{"id":1,  "name":"Leafling",  "type":"grass",   "color":Color("#66bb6a"), "hp":45, "atk":49, "def":49, "rarity":1, "habitats":["grass","tall_grass","forest"], "evolves_to":15, "evolve_level":16},
	{"id":2,  "name":"Flamini",   "type":"fire",    "color":Color("#ef5350"), "hp":39, "atk":52, "def":43, "rarity":1, "habitats":["sand","cave"], "evolves_to":16, "evolve_level":18},
	{"id":3,  "name":"Aquafin",   "type":"water",   "color":Color("#42a5f5"), "hp":44, "atk":48, "def":65, "rarity":1, "habitats":["sand","beach"], "evolves_to":17, "evolve_level":18},
	{"id":4,  "name":"Buzzer",    "type":"electric", "color":Color("#ffee58"), "hp":35, "atk":55, "def":30, "rarity":1, "habitats":["grass","tall_grass","town"], "evolves_to":18, "evolve_level":16},
	{"id":5,  "name":"Rockhead",  "type":"rock",    "color":Color("#8d6e63"), "hp":50, "atk":60, "def":70, "rarity":2, "habitats":["mountain","cave"]},
	{"id":6,  "name":"Ghostly",   "type":"ghost",   "color":Color("#7e57c2"), "hp":30, "atk":65, "def":25, "rarity":2, "habitats":["cave","forest"]},
	{"id":7,  "name":"Iciclaw",   "type":"ice",     "color":Color("#80deea"), "hp":55, "atk":50, "def":45, "rarity":2, "habitats":["snow","mountain"]},
	{"id":8,  "name":"Toxifrog",  "type":"poison",  "color":Color("#ab47bc"), "hp":40, "atk":45, "def":35, "rarity":1, "habitats":["tall_grass","forest"]},
	{"id":9,  "name":"Psychowl",  "type":"psychic", "color":Color("#ec407a"), "hp":38, "atk":70, "def":28, "rarity":2, "habitats":["town","path"]},
	{"id":10, "name":"Mudcrawl",  "type":"ground",  "color":Color("#a1887f"), "hp":55, "atk":55, "def":50, "rarity":1, "habitats":["sand","cave","path"]},
	{"id":11, "name":"Windwing",  "type":"flying",  "color":Color("#90caf9"), "hp":42, "atk":55, "def":30, "rarity":2, "habitats":["grass","mountain","forest"]},
	{"id":12, "name":"Darkshade", "type":"dark",    "color":Color("#455a64"), "hp":60, "atk":65, "def":55, "rarity":2, "habitats":["cave","forest"]},
	{"id":13, "name":"Steelvault","type":"steel",   "color":Color("#b0bec5"), "hp":65, "atk":60, "def":80, "rarity":3, "habitats":["mountain","cave"]},
	{"id":14, "name":"Dragonfly", "type":"dragon",  "color":Color("#26c6da"), "hp":55, "atk":80, "def":50, "rarity":3, "habitats":["forest"]},
	{"id":15, "name":"Fairydust", "type":"fairy",   "color":Color("#f48fb1"), "hp":50, "atk":45, "def":45, "rarity":2, "habitats":["grass","tall_grass","town"]},
	{"id":16, "name":"Infernoth", "type":"fire",    "color":Color("#ff7043"), "hp":35, "atk":90, "def":25, "rarity":3, "habitats":["cave","sand"]},
	{"id":17, "name":"Tidecrest", "type":"water",   "color":Color("#1565c0"), "hp":70, "atk":65, "def":70, "rarity":3, "habitats":["beach"]},
	{"id":18, "name":"Thunderex", "type":"electric", "color":Color("#f9a825"), "hp":60, "atk":85, "def":40, "rarity":3, "habitats":["mountain"]},
	{"id":19, "name":"COSMEON",   "type":"psychic", "color":Color("#e0e0e0"), "hp":80, "atk":100,"def":80, "rarity":4, "habitats":["*"]},
	{"id":20, "name":"VOIDREX",   "type":"dark",    "color":Color("#1a1a2e"), "hp":100,"atk":110,"def":90, "rarity":4, "habitats":["*"]},
]

# Type effectiveness chart
var type_chart: Dictionary = {
	"fire":     {"grass":2.0, "ice":2.0, "water":0.5, "rock":0.5},
	"water":    {"fire":2.0, "rock":2.0, "grass":0.5, "electric":0.5},
	"grass":    {"water":2.0, "rock":2.0, "fire":0.5, "flying":0.5},
	"electric": {"water":2.0, "flying":2.0, "ground":0.0},
	"rock":     {"fire":2.0, "flying":2.0, "water":0.5, "grass":0.5},
	"ice":      {"grass":2.0, "flying":2.0, "water":0.5},
	"ghost":    {"psychic":2.0, "dark":0.0},
	"dark":     {"psychic":2.0, "ghost":2.0, "fairy":0.5},
	"psychic":  {"poison":2.0, "dark":0.0},
	"poison":   {"fairy":2.0, "grass":2.0, "rock":0.5},
	"ground":   {"fire":2.0, "rock":2.0, "electric":2.0, "grass":0.5},
	"flying":   {"grass":2.0, "electric":0.5, "rock":0.5},
	"dragon":   {"dragon":2.0, "fairy":0.0},
	"fairy":    {"dark":2.0, "dragon":2.0, "steel":0.5},
	"steel":    {"rock":2.0, "ice":2.0, "fire":0.5},
}

func get_species(id: int) -> Dictionary:
	for s in species:
		if s["id"] == id:
			return s
	return {}

func get_effectiveness(atk_type: String, def_type: String) -> float:
	if atk_type in type_chart and def_type in type_chart[atk_type]:
		return type_chart[atk_type][def_type]
	return 1.0

func get_total_species() -> int:
	return species.size()

func get_species_for_habitat(habitat: String, time: String, weather: String) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for s in species:
		if habitat in s["habitats"] or "*" in s["habitats"]:
			pool.append(s)
	# Weather boosts
	var weather_type_map := {"rain":"water", "snow":"ice", "storm":"electric", "fog":"ghost"}
	if weather in weather_type_map:
		var boost_type = weather_type_map[weather]
		for s in species:
			if s["type"] == boost_type and s not in pool:
				pool.append(s)
	# Night boosts
	if time == "night":
		for s in species:
			if s["type"] in ["ghost","dark"] and s not in pool:
				pool.append(s)
	return pool

func weighted_random_pick(pool: Array[Dictionary]) -> Dictionary:
	if pool.is_empty():
		return {}
	var weights := {1: 40.0, 2: 15.0, 3: 4.0, 4: 1.0}
	var total := 0.0
	for s in pool:
		total += weights.get(s["rarity"], 10.0)
	var roll := randf() * total
	for s in pool:
		roll -= weights.get(s["rarity"], 10.0)
		if roll <= 0:
			return s
	return pool.back()
