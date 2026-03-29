extends Node

# Pokemon species data — 20 species
var species: Array[Dictionary] = [
	{"id":1,  "name":"Bulbasaur",  "sprite":"res://assets/sprites/1.png",   "type":"grass",    "pokeapi":1,   "color":Color("#66bb6a"), "hp":45, "atk":49, "def":49, "rarity":1, "habitats":["grass","tall_grass","forest"], "evolves_to":21, "evolve_level":16, "ability":"Overgrow"},
	{"id":2,  "name":"Charmander", "sprite":"res://assets/sprites/4.png",   "type":"fire",     "pokeapi":4,   "color":Color("#ef5350"), "hp":39, "atk":52, "def":43, "rarity":1, "habitats":["sand","cave"], "evolves_to":23, "evolve_level":16, "ability":"Blaze"},
	{"id":3,  "name":"Squirtle",   "sprite":"res://assets/sprites/7.png",   "type":"water",    "pokeapi":7,   "color":Color("#42a5f5"), "hp":44, "atk":48, "def":65, "rarity":1, "habitats":["sand","beach"], "evolves_to":25, "evolve_level":16, "ability":"Torrent"},
	{"id":4,  "name":"Pikachu",    "sprite":"res://assets/sprites/25.png",  "type":"electric", "pokeapi":25,  "color":Color("#ffee58"), "hp":35, "atk":55, "def":30, "rarity":1, "habitats":["grass","tall_grass","town"], "evolves_to":18, "evolve_level":16, "ability":"Static"},
	{"id":5,  "name":"Geodude",    "sprite":"res://assets/sprites/74.png",  "type":"rock",     "pokeapi":74,  "color":Color("#8d6e63"), "hp":50, "atk":60, "def":70, "rarity":2, "habitats":["mountain","cave"], "ability":"Sturdy"},
	{"id":6,  "name":"Gastly",     "sprite":"res://assets/sprites/92.png",  "type":"ghost",    "pokeapi":92,  "color":Color("#7e57c2"), "hp":30, "atk":65, "def":25, "rarity":2, "habitats":["cave","forest"], "ability":"Levitate"},
	{"id":7,  "name":"Sneasel",    "sprite":"res://assets/sprites/215.png", "type":"ice",      "pokeapi":215, "color":Color("#80deea"), "hp":55, "atk":50, "def":45, "rarity":2, "habitats":["snow","mountain"], "ability":"Inner Focus"},
	{"id":8,  "name":"Nidoran",    "sprite":"res://assets/sprites/29.png",  "type":"poison",   "pokeapi":29,  "color":Color("#ab47bc"), "hp":40, "atk":45, "def":35, "rarity":1, "habitats":["tall_grass","forest"], "ability":"Poison Point"},
	{"id":9,  "name":"Abra",       "sprite":"res://assets/sprites/63.png",  "type":"psychic",  "pokeapi":63,  "color":Color("#ec407a"), "hp":38, "atk":70, "def":28, "rarity":2, "habitats":["town","path"], "ability":"Synchronize"},
	{"id":10, "name":"Sandshrew",  "sprite":"res://assets/sprites/27.png",  "type":"ground",   "pokeapi":27,  "color":Color("#a1887f"), "hp":55, "atk":55, "def":50, "rarity":1, "habitats":["sand","cave","path"], "ability":"Sand Veil"},
	{"id":11, "name":"Pidgey",     "sprite":"res://assets/sprites/16.png",  "type":"flying",   "pokeapi":16,  "color":Color("#90caf9"), "hp":42, "atk":55, "def":30, "rarity":1, "habitats":["grass","mountain","forest"], "ability":"Keen Eye"},
	{"id":12, "name":"Murkrow",    "sprite":"res://assets/sprites/198.png", "type":"dark",     "pokeapi":198, "color":Color("#455a64"), "hp":60, "atk":65, "def":55, "rarity":2, "habitats":["cave","forest"], "ability":"Insomnia"},
	{"id":13, "name":"Aron",       "sprite":"res://assets/sprites/304.png", "type":"steel",    "pokeapi":304, "color":Color("#b0bec5"), "hp":65, "atk":60, "def":80, "rarity":3, "habitats":["mountain","cave"], "ability":"Rock Head"},
	{"id":14, "name":"Dratini",    "sprite":"res://assets/sprites/147.png", "type":"dragon",   "pokeapi":147, "color":Color("#26c6da"), "hp":55, "atk":80, "def":50, "rarity":3, "habitats":["forest"], "ability":"Shed Skin"},
	{"id":15, "name":"Clefairy",   "sprite":"res://assets/sprites/35.png",  "type":"fairy",    "pokeapi":35,  "color":Color("#f48fb1"), "hp":50, "atk":45, "def":45, "rarity":2, "habitats":["grass","tall_grass","town"], "ability":"Magic Guard"},
	{"id":16, "name":"Arcanine",   "sprite":"res://assets/sprites/59.png",  "type":"fire",     "pokeapi":59,  "color":Color("#ff7043"), "hp":35, "atk":90, "def":25, "rarity":3, "habitats":["cave","sand"], "ability":"Intimidate"},
	{"id":17, "name":"Gyarados",   "sprite":"res://assets/sprites/130.png", "type":"water",    "pokeapi":130, "color":Color("#1565c0"), "hp":70, "atk":65, "def":70, "rarity":3, "habitats":["beach"], "ability":"Intimidate"},
	{"id":18, "name":"Raichu",     "sprite":"res://assets/sprites/26.png",  "type":"electric", "pokeapi":26,  "color":Color("#f9a825"), "hp":60, "atk":85, "def":40, "rarity":3, "habitats":["mountain"], "ability":"Lightning Rod"},
	{"id":19, "name":"Mewtwo",     "sprite":"res://assets/sprites/150.png", "type":"psychic",  "pokeapi":150, "color":Color("#e0e0e0"), "hp":80, "atk":100, "def":80, "rarity":4, "habitats":["*"], "ability":"Pressure"},
	{"id":20, "name":"Darkrai",    "sprite":"res://assets/sprites/491.png", "type":"dark",     "pokeapi":491, "color":Color("#1a1a2e"), "hp":100, "atk":110, "def":90, "rarity":4, "habitats":["*"], "ability":"Bad Dreams"},

	# --- NEW SPECIES (21-50) ---
	{"id":21, "name":"Ivysaur",    "sprite":"res://assets/sprites/2.png",  "type":"grass",   "pokeapi":2,   "color":Color("#4caf50"), "hp":60, "atk":62, "def":63, "rarity":2, "habitats":["forest","tall_grass"], "evolves_to":22, "evolve_level":32},
	{"id":22, "name":"Venusaur",   "sprite":"res://assets/sprites/3.png",  "type":"grass",   "pokeapi":3,   "color":Color("#388e3c"), "hp":80, "atk":82, "def":83, "rarity":3, "habitats":["forest"], "evolves_to":null},
	{"id":23, "name":"Charmeleon", "sprite":"res://assets/sprites/5.png",  "type":"fire",    "pokeapi":5,   "color":Color("#e53935"), "hp":58, "atk":64, "def":58, "rarity":2, "habitats":["volcano","cave"], "evolves_to":24, "evolve_level":36},
	{"id":24, "name":"Charizard",  "sprite":"res://assets/sprites/6.png",  "type":"fire",    "pokeapi":6,   "color":Color("#d32f2f"), "hp":78, "atk":84, "def":78, "rarity":3, "habitats":["volcano"], "evolves_to":null},
	{"id":25, "name":"Wartortle",  "sprite":"res://assets/sprites/8.png",  "type":"water",   "pokeapi":8,   "color":Color("#1e88e5"), "hp":59, "atk":63, "def":80, "rarity":2, "habitats":["lake","beach"], "evolves_to":26, "evolve_level":36},
	{"id":26, "name":"Blastoise",  "sprite":"res://assets/sprites/9.png",  "type":"water",   "pokeapi":9,   "color":Color("#1565c0"), "hp":79, "atk":83, "def":100, "rarity":3, "habitats":["lake"], "evolves_to":null},
	{"id":27, "name":"Caterpie",   "sprite":"res://assets/sprites/10.png", "type":"grass",   "pokeapi":10,  "color":Color("#8bc34a"), "hp":45, "atk":30, "def":35, "rarity":1, "habitats":["forest","grass","tall_grass"], "evolves_to":null},
	{"id":28, "name":"Weedle",     "sprite":"res://assets/sprites/13.png", "type":"poison",  "pokeapi":13,  "color":Color("#ff9800"), "hp":40, "atk":35, "def":30, "rarity":1, "habitats":["forest","tall_grass"], "evolves_to":null},
	{"id":29, "name":"Rattata",    "sprite":"res://assets/sprites/19.png", "type":"normal",  "pokeapi":19,  "color":Color("#9e9e9e"), "hp":30, "atk":56, "def":35, "rarity":1, "habitats":["grass","path","town"], "evolves_to":null},
	{"id":30, "name":"Spearow",    "sprite":"res://assets/sprites/21.png", "type":"flying",  "pokeapi":21,  "color":Color("#a1887f"), "hp":40, "atk":60, "def":30, "rarity":1, "habitats":["grass","mountain"], "evolves_to":null},
	{"id":31, "name":"Ekans",      "sprite":"res://assets/sprites/23.png", "type":"poison",  "pokeapi":23,  "color":Color("#7b1fa2"), "hp":35, "atk":60, "def":44, "rarity":2, "habitats":["swamp","forest"], "evolves_to":null},
	{"id":32, "name":"Vulpix",     "sprite":"res://assets/sprites/37.png", "type":"fire",    "pokeapi":37,  "color":Color("#ff7043"), "hp":38, "atk":41, "def":40, "rarity":2, "habitats":["volcano","cave"], "evolves_to":null},
	{"id":33, "name":"Jigglypuff", "sprite":"res://assets/sprites/39.png", "type":"fairy",   "pokeapi":39,  "color":Color("#f8bbd0"), "hp":115, "atk":45, "def":20, "rarity":2, "habitats":["grass","town"], "evolves_to":null},
	{"id":34, "name":"Zubat",      "sprite":"res://assets/sprites/41.png", "type":"poison",  "pokeapi":41,  "color":Color("#7e57c2"), "hp":40, "atk":45, "def":35, "rarity":1, "habitats":["cave"], "evolves_to":null},
	{"id":35, "name":"Oddish",     "sprite":"res://assets/sprites/43.png", "type":"grass",   "pokeapi":43,  "color":Color("#66bb6a"), "hp":45, "atk":50, "def":55, "rarity":1, "habitats":["grass","tall_grass","forest"], "evolves_to":null},
	{"id":36, "name":"Meowth",     "sprite":"res://assets/sprites/52.png", "type":"normal",  "pokeapi":52,  "color":Color("#ffcc80"), "hp":40, "atk":45, "def":35, "rarity":1, "habitats":["town","path"], "evolves_to":null},
	{"id":37, "name":"Psyduck",    "sprite":"res://assets/sprites/54.png", "type":"water",   "pokeapi":54,  "color":Color("#ffd54f"), "hp":50, "atk":52, "def":48, "rarity":2, "habitats":["lake","beach"], "evolves_to":null},
	{"id":38, "name":"Mankey",     "sprite":"res://assets/sprites/56.png", "type":"fighting", "pokeapi":56, "color":Color("#d7ccc8"), "hp":40, "atk":80, "def":35, "rarity":2, "habitats":["mountain","cave"], "evolves_to":null},
	{"id":39, "name":"Growlithe",  "sprite":"res://assets/sprites/58.png", "type":"fire",    "pokeapi":58,  "color":Color("#ff8a65"), "hp":55, "atk":70, "def":45, "rarity":2, "habitats":["volcano","grass"], "evolves_to":null},
	{"id":40, "name":"Machop",     "sprite":"res://assets/sprites/66.png", "type":"fighting", "pokeapi":66, "color":Color("#90a4ae"), "hp":70, "atk":80, "def":50, "rarity":2, "habitats":["mountain","cave"], "evolves_to":null},
	{"id":41, "name":"Slowpoke",   "sprite":"res://assets/sprites/79.png", "type":"psychic", "pokeapi":79,  "color":Color("#f48fb1"), "hp":90, "atk":65, "def":65, "rarity":2, "habitats":["lake","beach"], "evolves_to":null},
	{"id":42, "name":"Magnemite",  "sprite":"res://assets/sprites/81.png", "type":"electric","pokeapi":81,  "color":Color("#bdbdbd"), "hp":25, "atk":35, "def":70, "rarity":2, "habitats":["ruins","town"], "evolves_to":null},
	{"id":43, "name":"Onix",       "sprite":"res://assets/sprites/95.png", "type":"rock",    "pokeapi":95,  "color":Color("#8d6e63"), "hp":35, "atk":45, "def":160, "rarity":3, "habitats":["cave","mountain"], "evolves_to":null},
	{"id":44, "name":"Cubone",     "sprite":"res://assets/sprites/104.png","type":"ground",  "pokeapi":104, "color":Color("#bcaaa4"), "hp":50, "atk":50, "def":95, "rarity":2, "habitats":["cave","ruins"], "evolves_to":null},
	{"id":45, "name":"Rhyhorn",    "sprite":"res://assets/sprites/111.png","type":"rock",    "pokeapi":111, "color":Color("#9e9e9e"), "hp":80, "atk":85, "def":95, "rarity":3, "habitats":["mountain","volcano"], "evolves_to":null},
	{"id":46, "name":"Horsea",     "sprite":"res://assets/sprites/116.png","type":"water",   "pokeapi":116, "color":Color("#4fc3f7"), "hp":30, "atk":40, "def":70, "rarity":2, "habitats":["lake","beach"], "evolves_to":null},
	{"id":47, "name":"Scyther",    "sprite":"res://assets/sprites/123.png","type":"flying",  "pokeapi":123, "color":Color("#66bb6a"), "hp":70, "atk":110, "def":80, "rarity":3, "habitats":["forest"], "evolves_to":null},
	{"id":48, "name":"Magikarp",   "sprite":"res://assets/sprites/129.png","type":"water",   "pokeapi":129, "color":Color("#ef5350"), "hp":20, "atk":10, "def":55, "rarity":1, "habitats":["lake","beach"], "evolves_to":17, "evolve_level":20},
	{"id":49, "name":"Lapras",     "sprite":"res://assets/sprites/131.png","type":"ice",     "pokeapi":131, "color":Color("#4dd0e1"), "hp":130, "atk":85, "def":80, "rarity":3, "habitats":["lake","snow"], "evolves_to":null},
	{"id":50, "name":"Eevee",      "sprite":"res://assets/sprites/133.png","type":"normal",  "pokeapi":133, "color":Color("#a1887f"), "hp":55, "atk":55, "def":50, "rarity":3, "habitats":["grass","town"], "evolves_to":null},
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
	var weather_type_map = {"rain":"water", "snow":"ice", "storm":"electric", "fog":"ghost"}
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
	var weights = {1: 40.0, 2: 15.0, 3: 4.0, 4: 1.0}
	var total := 0.0
	for s in pool:
		total += weights.get(s["rarity"], 10.0)
	var roll := randf() * total
	for s in pool:
		roll -= weights.get(s["rarity"], 10.0)
		if roll <= 0:
			return s
	return pool.back()

var _sprite_cache: Dictionary = {}

func get_sprite_texture(species_id: int) -> Texture2D:
	if species_id in _sprite_cache:
		return _sprite_cache[species_id]
	var s = get_species(species_id)
	if s.is_empty() or not s.has("sprite"):
		return null
	var tex = load(s["sprite"])
	_sprite_cache[species_id] = tex
	return tex
