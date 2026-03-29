extends RefCounted

# Tile shortcuts
const W = 0    # water
const G = 1    # grass
const T = 2    # tall grass
const TR = 3   # tree
const P = 4    # path
const F = 5    # floor
const WL = 6   # wall
const D = 7    # door
const S = 8    # sand
const CF = 9   # cave floor
const CW = 10  # cave wall
const L = 11   # ledge
const SN = 12  # sign
const PC = 13  # pokecenter
const SH = 14  # shop
const GF = 15  # gym floor
const FL = 16  # flower
const FN = 17  # fence
const SW = 18  # snow
const IC = 19  # ice
const LV = 20  # lava
const VR = 21  # volcano rock
const SM = 22  # swamp
const DW = 23  # deep water
const BR = 24  # bridge
const RU = 25  # ruins
const BB = 26  # berry bush
const LS = 27  # lake shore

func get_area(name: String) -> Dictionary:
	match name:
		"Pallet Town": return _pallet_town()
		"Route 1": return _route_1()
		"Pewter City": return _pewter_city()
		"Mt. Moon": return _mt_moon()
		"Cerulean City": return _cerulean_city()
		"Route 3": return _route_3()
		"Vermilion City": return _vermilion_city()
		"Celadon City": return _celadon_city()
		"Saffron City": return _saffron_city()
		"Pokemon League": return _pokemon_league()
	return {}

func get_all_area_names() -> Array:
	return ["Pallet Town", "Route 1", "Pewter City", "Mt. Moon", "Cerulean City",
			"Route 3", "Vermilion City", "Celadon City", "Saffron City", "Pokemon League"]

func _make_area(name: String, type: String, w: int, h: int, tile_rows: Array, extra: Dictionary = {}) -> Dictionary:
	var tiles = PackedInt32Array()
	for row in tile_rows:
		for tile in row:
			tiles.append(tile)
	var data = {"name": name, "type": type, "width": w, "height": h, "tiles": tiles}
	data.merge(extra)
	return data

# ─── Biome terrain generator ───────────────────────────────────────────────

func _biome_tile(x: int, y: int, _w: int, _h: int, biome: String) -> int:
	var hash_val = (x * 7 + y * 13 + x * y) % 100

	match biome:
		"forest":
			if hash_val < 25: return T
			elif hash_val < 40: return TR
			elif hash_val < 50: return FL
			elif hash_val < 55: return BB
			else: return G
		"lake":
			# lake center handled separately in callers
			if hash_val < 20: return T
			elif hash_val < 25: return FL
			else: return G
		"snow":
			if hash_val < 30: return SW
			elif hash_val < 40: return IC
			elif hash_val < 50: return TR
			else: return SW
		"volcano":
			if hash_val < 15: return LV
			elif hash_val < 40: return VR
			elif hash_val < 50: return CF
			elif hash_val < 55: return CW
			else: return VR
		"swamp":
			if hash_val < 20: return SM
			elif hash_val < 35: return W
			elif hash_val < 45: return T
			elif hash_val < 50: return TR
			else: return G
		"ruins":
			if hash_val < 25: return RU
			elif hash_val < 35: return CF
			elif hash_val < 45: return CW
			elif hash_val < 55: return T
			else: return G
		"plains":
			if hash_val < 30: return T
			elif hash_val < 35: return FL
			elif hash_val < 40: return BB
			elif hash_val < 45: return FN
			else: return G
		_:  # default grassland
			if hash_val < 20: return T
			elif hash_val < 25: return TR
			elif hash_val < 30: return FL
			else: return G

func _generate_route(width: int, height: int, biome: String, path_y: int = -1) -> Array:
	var rows = []
	if path_y < 0:
		path_y = height / 2
	var border_tile = TR if biome != "snow" and biome != "volcano" else (CW if biome == "volcano" else TR)

	for y in height:
		var row = []
		for x in width:
			if x == 0 or x == width - 1:
				row.append(border_tile)
			elif y == 0 or y == height - 1:
				row.append(border_tile)
			elif x == width / 2 or x == width / 2 + 1:
				row.append(P)
			elif y == path_y or y == path_y + 1:
				row.append(P)
			else:
				row.append(_biome_tile(x, y, width, height, biome))
		rows.append(row)
	return rows

func _generate_town(width: int, height: int, biome: String = "default") -> Array:
	var rows = []
	for y in height:
		var row = []
		for x in width:
			if x == 0 or x == width - 1 or y == 0 or y == height - 1:
				row.append(TR)
			elif x == width / 2 or x == width / 2 + 1:
				row.append(P)
			elif y == height / 2 or y == height / 2 + 1:
				row.append(P)
			else:
				match biome:
					"snow":
						row.append(SW if (x + y) % 3 != 0 else G)
					"volcano":
						row.append(S if (x + y) % 4 != 0 else VR)
					_:
						row.append(G if (x + y) % 7 != 0 else FL)
		rows.append(row)
	return rows

# ─── Areas ──────────────────────────────────────────────────────────────────

func _pallet_town() -> Dictionary:
	var w = 40
	var h = 30
	var rows = _generate_town(w, h, "default")

	# Prof Oak's lab (center)
	for dy in range(16, 23):
		for dx in range(14, 26):
			rows[dy][dx] = F if dy < 22 else WL
	rows[22][20] = D

	# Player house (left side)
	for dy in range(7, 12):
		for dx in range(4, 12):
			if dy == 7 or dy == 11 or dx == 4 or dx == 11:
				rows[dy][dx] = WL
			else:
				rows[dy][dx] = F
	rows[11][7] = D

	# Rival house (right side)
	for dy in range(7, 12):
		for dx in range(28, 36):
			if dy == 7 or dy == 11 or dx == 28 or dx == 35:
				rows[dy][dx] = WL
			else:
				rows[dy][dx] = F
	rows[11][31] = D

	# Lake on south side
	for dy in range(25, 29):
		for dx in range(4, 18):
			rows[dy][dx] = W
	for dx in range(3, 19):
		rows[24][dx] = LS

	# Extra flowers and decorations
	for dx in range(2, 6):
		rows[3][dx] = FL
	for dx in range(34, 38):
		rows[3][dx] = FL

	return _make_area("Pallet Town", "town", w, h, rows, {
		"spawn": {"x": 20, "y": 15},
		"exits": [
			{"x": 20, "y": 0, "target_area": "Route 1", "target_x": 25, "target_y": 38},
			{"x": 21, "y": 0, "target_area": "Route 1", "target_x": 26, "target_y": 38},
		],
		"npcs": [
			{"x": 20, "y": 20, "name": "Prof. Oak", "type": "professor", "dialog": [
				"Welcome to the world of Pokemon!",
				"I'm Professor Oak. I study Pokemon.",
				"A dark force threatens our land... DARKRAI stirs.",
				"Choose your first Pokemon and begin your journey!",
				"Collect 8 Gym Badges and challenge the Pokemon League!",
			]},
			{"x": 7, "y": 10, "name": "Mom", "type": "npc", "dialog": ["Good luck on your adventure, dear!", "Come home safe!"]},
			{"x": 31, "y": 10, "name": "Rival", "type": "rival", "dialog": ["I'll be the Pokemon Champion before you! Just watch!"]},
			{"x": 19, "y": 1, "name": "Sign", "type": "npc", "dialog": ["↑ Route 1 (North) — Pewter City beyond"]},
			{"x": 10, "y": 26, "name": "Fisherman", "type": "npc", "dialog": ["Try fishing in the lake!", "You might find Water-type Pokemon!"]},
			{"x": 25, "y": 5, "name": "Youngster", "type": "npc", "dialog": ["This is Pallet Town — the start of all adventures!", "Route 1 is north of here."]},
		],
		"pokecenter": false, "shop": false,
		"encounters": [],
	})

func _route_1() -> Dictionary:
	var w = 50
	var h = 40
	var rows = _generate_route(w, h, "forest", 20)

	# Extra clearings
	for dy in range(8, 14):
		for dx in range(5, 12):
			rows[dy][dx] = G
	for dy in range(22, 28):
		for dx in range(36, 44):
			rows[dy][dx] = G
	# Berry bushes cluster
	for dy in range(15, 18):
		for dx in range(18, 24):
			rows[dy][dx] = BB
	# Tall grass patches
	for dy in range(4, 10):
		for dx in range(28, 35):
			rows[dy][dx] = T
	for dy in range(30, 37):
		for dx in range(8, 16):
			rows[dy][dx] = T
	# Small pond
	for dy in range(12, 16):
		for dx in range(30, 38):
			rows[dy][dx] = W
	for dx in range(29, 39):
		rows[11][dx] = LS
		rows[16][dx] = LS

	return _make_area("Route 1", "route", w, h, rows, {
		"spawn": {"x": 25, "y": 38},
		"exits": [
			{"x": 25, "y": 39, "target_area": "Pallet Town", "target_x": 20, "target_y": 1},
			{"x": 26, "y": 39, "target_area": "Pallet Town", "target_x": 21, "target_y": 1},
			{"x": 25, "y": 0, "target_area": "Pewter City", "target_x": 20, "target_y": 28},
			{"x": 26, "y": 0, "target_area": "Pewter City", "target_x": 21, "target_y": 28},
		],
		"npcs": [
			{"x": 18, "y": 12, "name": "Youngster Joey", "type": "trainer", "dialog": ["My Pidgey is the best!"], "team": [{"id": 11, "level": 3}]},
			{"x": 35, "y": 25, "name": "Lass Jenny", "type": "trainer", "dialog": ["Want to battle?"], "team": [{"id": 8, "level": 4}]},
			{"x": 10, "y": 32, "name": "Bug Catcher Ben", "type": "trainer", "dialog": ["The forest is full of Pokemon!"], "team": [{"id": 1, "level": 4}, {"id": 11, "level": 3}]},
			{"x": 24, "y": 1, "name": "Sign", "type": "npc", "dialog": ["↑ Pewter City (North)", "↓ Pallet Town (South)"]},
			{"x": 24, "y": 37, "name": "Sign", "type": "npc", "dialog": ["↓ Pallet Town (South)", "↑ Pewter City (North)"]},
			{"x": 40, "y": 15, "name": "Hiker", "type": "npc", "dialog": ["There's a small pond to the east!", "I heard Squirtle might live there..."]},
		],
		"encounters": [
			{"species_id": 11, "min_level": 2, "max_level": 6, "weight": 30},   # Pidgey
			{"species_id": 8, "min_level": 2, "max_level": 6, "weight": 25},    # Nidoran
			{"species_id": 10, "min_level": 3, "max_level": 6, "weight": 20},   # Sandshrew
			{"species_id": 1, "min_level": 3, "max_level": 6, "weight": 10},    # Bulbasaur (rare)
			{"species_id": 15, "min_level": 4, "max_level": 6, "weight": 10},   # Clefairy
			{"species_id": 12, "min_level": 4, "max_level": 6, "weight": 5},    # Murkrow (rare)
			{"species_id": 27, "min_level": 2, "max_level": 4, "weight": 15},   # Caterpie
			{"species_id": 29, "min_level": 2, "max_level": 5, "weight": 15},   # Rattata
		],
		"hidden_items": [
			{"x": 10, "y": 18, "type": "ultraball", "found": false},
			{"x": 40, "y": 8, "type": "razz", "found": false},
			{"x": 22, "y": 34, "type": "razz", "found": false},
		],
	})

func _pewter_city() -> Dictionary:
	var w = 40
	var h = 30
	var rows = _generate_town(w, h, "default")

	# Rocky terrain touches (Pewter is near mountains)
	for dy in range(2, 6):
		for dx in range(2, 8):
			rows[dy][dx] = S
	for dy in range(2, 5):
		for dx in range(32, 38):
			rows[dy][dx] = S

	# Gym (left side)
	for dy in range(4, 11):
		for dx in range(3, 12):
			if dy == 4 or dy == 10 or dx == 3 or dx == 11:
				rows[dy][dx] = WL
			else:
				rows[dy][dx] = GF
	rows[10][7] = D

	# Pokecenter (right side)
	for dy in range(4, 9):
		for dx in range(28, 37):
			if dy == 4 or dy == 8 or dx == 28 or dx == 36:
				rows[dy][dx] = WL
			else:
				rows[dy][dx] = F
	rows[8][32] = PC
	rows[8][33] = PC

	# Shop
	for dy in range(13, 18):
		for dx in range(28, 37):
			if dy == 13 or dy == 17 or dx == 28 or dx == 36:
				rows[dy][dx] = WL
			else:
				rows[dy][dx] = F
	rows[17][32] = SH
	rows[17][33] = SH

	# East exit path to Mt. Moon
	for dy in range(13, 17):
		rows[dy][39] = P
		rows[dy][38] = P

	return _make_area("Pewter City", "town", w, h, rows, {
		"spawn": {"x": 20, "y": 28},
		"exits": [
			{"x": 20, "y": 29, "target_area": "Route 1", "target_x": 25, "target_y": 1},
			{"x": 21, "y": 29, "target_area": "Route 1", "target_x": 26, "target_y": 1},
			{"x": 39, "y": 14, "target_area": "Mt. Moon", "target_x": 1, "target_y": 17},
			{"x": 39, "y": 15, "target_area": "Mt. Moon", "target_x": 1, "target_y": 18},
		],
		"npcs": [
			{"x": 32, "y": 6, "name": "Nurse Joy", "type": "nurse", "dialog": ["Welcome! Let me heal your Pokemon.", "Your Pokemon are fully healed!"]},
			{"x": 32, "y": 15, "name": "Shopkeeper", "type": "shop", "dialog": ["Welcome to the Poke Mart!"]},
			{"x": 19, "y": 1, "name": "Sign", "type": "npc", "dialog": ["Pewter City — The Stone Gray City", "↓ Route 1 / Pallet Town (South)", "→ Mt. Moon (East)"]},
			{"x": 37, "y": 13, "name": "Sign", "type": "npc", "dialog": ["→ Mt. Moon (East)"]},
			{"x": 15, "y": 20, "name": "Scientist", "type": "npc", "dialog": ["The museum near here has rare fossils!", "I wonder what Pokemon once lived in these rocks..."]},
			{"x": 6, "y": 22, "name": "Kid", "type": "npc", "dialog": ["Brock is super tough! His rock-type Pokemon are amazing!"]},
		],
		"gym_leader": {
			"x": 7, "y": 6, "name": "Brock", "type": "gym_leader",
			"specialty": "rock", "badge": "Boulder Badge",
			"dialog": ["I'm Brock, the Pewter City Gym Leader!", "My rock-hard Pokemon will crush you!"],
			"team": [{"id": 5, "level": 9}, {"id": 10, "level": 10}, {"id": 5, "level": 12}],
			"win_dialog": ["You beat me! Take the Boulder Badge!", "You've earned my respect."],
		},
		"pokecenter": true, "shop": true,
		"encounters": [],
	})

func _mt_moon() -> Dictionary:
	var w = 40
	var h = 35
	var rows = []

	for y in h:
		var row = []
		for x in w:
			if x == 0 or x == w - 1 or y == 0 or y == h - 1:
				row.append(CW)
			elif (x + y * 3) % 13 == 0 and x > 2 and x < w - 3 and y > 2 and y < h - 3:
				row.append(CW)  # random pillars
			elif y > 26:
				# Lava pockets in southern section
				var lh = (x * 7 + y * 11) % 100
				if lh < 20:
					row.append(LV)
				elif lh < 45:
					row.append(VR)
				else:
					row.append(CF)
			else:
				row.append(CF)
		rows.append(row)

	# Winding path corridors
	for y in range(5, 30):
		rows[y][18] = CF
		rows[y][19] = CF
	for x in range(5, 35):
		rows[17][x] = CF
		rows[18][x] = CF

	return _make_area("Mt. Moon", "cave", w, h, rows, {
		"spawn": {"x": 1, "y": 17},
		"exits": [
			{"x": 0, "y": 17, "target_area": "Pewter City", "target_x": 38, "target_y": 14},
			{"x": 0, "y": 18, "target_area": "Pewter City", "target_x": 38, "target_y": 15},
			{"x": 39, "y": 17, "target_area": "Cerulean City", "target_x": 1, "target_y": 14},
			{"x": 39, "y": 18, "target_area": "Cerulean City", "target_x": 1, "target_y": 15},
		],
		"npcs": [
			{"x": 12, "y": 8, "name": "Rocket Grunt", "type": "rocket", "dialog": ["Hand over your Pokemon!", "Team Rocket will rule!"], "team": [{"id": 8, "level": 8}, {"id": 12, "level": 9}]},
			{"x": 28, "y": 22, "name": "Rocket Grunt", "type": "rocket", "dialog": ["You'll never stop Team Rocket!"], "team": [{"id": 6, "level": 10}]},
			{"x": 20, "y": 30, "name": "Rocket Grunt", "type": "rocket", "dialog": ["Stay away from our operations!"], "team": [{"id": 5, "level": 9}, {"id": 6, "level": 11}]},
			{"x": 2, "y": 16, "name": "Sign", "type": "npc", "dialog": ["← Pewter City (West)", "→ Cerulean City (East)"]},
			{"x": 5, "y": 28, "name": "Geologist", "type": "npc", "dialog": ["Careful! Lava flows deeper in the cave.", "The heat attracts Fire-type Pokemon..."]},
		],
		"encounters": [
			{"species_id": 5, "min_level": 7, "max_level": 12, "weight": 25},   # Geodude
			{"species_id": 6, "min_level": 7, "max_level": 11, "weight": 20},   # Gastly
			{"species_id": 15, "min_level": 8, "max_level": 11, "weight": 10},  # Clefairy
			{"species_id": 9, "min_level": 8, "max_level": 12, "weight": 10},   # Abra
			{"species_id": 13, "min_level": 9, "max_level": 12, "weight": 8},   # Aron
			{"species_id": 2, "min_level": 8, "max_level": 12, "weight": 7},    # Charmander (lava area!)
		],
		"hidden_items": [
			{"x": 20, "y": 6, "type": "razz", "found": false},
			{"x": 8, "y": 24, "type": "ultraball", "found": false},
			{"x": 34, "y": 12, "type": "razz", "found": false},
			{"x": 15, "y": 30, "type": "ultraball", "found": false},
		],
	})

func _cerulean_city() -> Dictionary:
	var w = 40
	var h = 30
	var rows = _generate_town(w, h, "default")

	# Central lake feature
	for dy in range(16, 24):
		for dx in range(10, 30):
			rows[dy][dx] = W
	# Lake shore
	for dx in range(9, 31):
		rows[15][dx] = LS
		if rows[24][dx] != W:
			rows[24][dx] = LS
	for dy in range(15, 25):
		rows[dy][9] = LS
		rows[dy][30] = LS

	# Deep water in center
	for dy in range(18, 22):
		for dx in range(16, 24):
			rows[dy][dx] = DW

	# Bridge over lake
	for dy in range(18, 22):
		rows[dy][20] = BR
		rows[dy][21] = BR

	# Gym (left)
	for dy in range(4, 12):
		for dx in range(3, 13):
			if dy == 4 or dy == 11 or dx == 3 or dx == 12:
				rows[dy][dx] = WL
			else:
				rows[dy][dx] = GF
	rows[11][7] = D

	# Pokecenter (right)
	for dy in range(4, 9):
		for dx in range(28, 37):
			if dy == 4 or dy == 8 or dx == 28 or dx == 36:
				rows[dy][dx] = WL
			else:
				rows[dy][dx] = F
	rows[8][32] = PC
	rows[8][33] = PC

	# East-west passes (ensure walkable near exits)
	for dy in range(13, 17):
		rows[dy][0] = P
		rows[dy][1] = P
		rows[dy][38] = P
		rows[dy][39] = P

	return _make_area("Cerulean City", "town", w, h, rows, {
		"spawn": {"x": 1, "y": 14},
		"exits": [
			{"x": 0, "y": 14, "target_area": "Mt. Moon", "target_x": 38, "target_y": 17},
			{"x": 0, "y": 15, "target_area": "Mt. Moon", "target_x": 38, "target_y": 18},
			{"x": 39, "y": 14, "target_area": "Route 3", "target_x": 1, "target_y": 20},
			{"x": 39, "y": 15, "target_area": "Route 3", "target_x": 1, "target_y": 21},
		],
		"npcs": [
			{"x": 32, "y": 6, "name": "Nurse Joy", "type": "nurse", "dialog": ["Let me heal your Pokemon!", "Come back whenever you need!"]},
			{"x": 18, "y": 9, "name": "Rival", "type": "rival", "dialog": [
				"Well well, look who made it!",
				"Let's see how strong you've gotten!",
			], "team": [{"id": 11, "level": 14}, {"id": 2, "level": 16}], "battle_index": 1},
			{"x": 1, "y": 13, "name": "Sign", "type": "npc", "dialog": ["← Mt. Moon (West)", "→ Route 3 / Vermilion (East)"]},
			{"x": 37, "y": 13, "name": "Sign", "type": "npc", "dialog": ["→ Route 3 (East)", "← Mt. Moon (West)"]},
			{"x": 20, "y": 16, "name": "Swimmer", "type": "npc", "dialog": ["The lake in this city is beautiful!", "Water Pokemon love it here — try using Surf!"]},
			{"x": 8, "y": 24, "name": "Fisherman", "type": "npc", "dialog": ["The lake is full of Squirtle!", "They say a Gyarados lurks in the deep water..."]},
		],
		"gym_leader": {
			"x": 7, "y": 7, "name": "Misty", "type": "gym_leader",
			"specialty": "water", "badge": "Cascade Badge",
			"dialog": ["I'm Misty! My water Pokemon are unstoppable!"],
			"team": [{"id": 3, "level": 14}, {"id": 17, "level": 16}, {"id": 3, "level": 18}],
			"win_dialog": ["You beat my water Pokemon! Take the Cascade Badge!"],
		},
		"pokecenter": true, "shop": false,
		"encounters": [
			{"species_id": 3, "min_level": 10, "max_level": 14, "weight": 30},  # Squirtle (lake)
			{"species_id": 17, "min_level": 12, "max_level": 15, "weight": 10}, # Gyarados (rare)
			{"species_id": 8, "min_level": 10, "max_level": 13, "weight": 20},  # Nidoran
			{"species_id": 9, "min_level": 11, "max_level": 15, "weight": 15},  # Abra
			{"species_id": 15, "min_level": 10, "max_level": 14, "weight": 15}, # Clefairy
			{"species_id": 1, "min_level": 11, "max_level": 15, "weight": 10},  # Bulbasaur
		],
	})

func _route_3() -> Dictionary:
	var w = 50
	var h = 40
	var rows = _generate_route(w, h, "snow", 20)

	# Frozen lake in the middle
	for dy in range(14, 22):
		for dx in range(8, 20):
			rows[dy][dx] = IC
	for dx in range(7, 21):
		rows[13][dx] = SW
		rows[22][dx] = SW

	# Snow-covered trees
	for dy in range(5, 12):
		for dx in range(28, 38):
			if (dx + dy) % 3 == 0:
				rows[dy][dx] = TR
			else:
				rows[dy][dx] = SW

	# Blizzard tall-grass equivalent (snow patches for encounters)
	for dy in range(25, 35):
		for dx in range(30, 45):
			if (dx * 5 + dy * 7) % 3 != 0:
				rows[dy][dx] = SW

	# Mountain ridge on north edge
	for dy in range(1, 6):
		for dx in range(1, w - 1):
			if (dx * 7 + dy * 3) % 5 < 2:
				rows[dy][dx] = CW

	return _make_area("Route 3", "route", w, h, rows, {
		"spawn": {"x": 1, "y": 20},
		"exits": [
			{"x": 0, "y": 20, "target_area": "Cerulean City", "target_x": 38, "target_y": 14},
			{"x": 0, "y": 21, "target_area": "Cerulean City", "target_x": 38, "target_y": 15},
			{"x": 49, "y": 20, "target_area": "Vermilion City", "target_x": 1, "target_y": 14},
			{"x": 49, "y": 21, "target_area": "Vermilion City", "target_x": 1, "target_y": 15},
		],
		"npcs": [
			{"x": 15, "y": 8, "name": "Hiker Mike", "type": "trainer", "dialog": ["These icy mountains are tough!", "My Pokemon love the cold!"], "team": [{"id": 5, "level": 15}, {"id": 13, "level": 16}]},
			{"x": 35, "y": 28, "name": "Skier Amy", "type": "trainer", "dialog": ["Snow routes are my specialty!", "Battle me!"], "team": [{"id": 15, "level": 15}, {"id": 7, "level": 16}]},
			{"x": 24, "y": 33, "name": "Picnicker Dana", "type": "trainer", "dialog": ["Even in snow, I love Pokemon!"], "team": [{"id": 15, "level": 14}, {"id": 4, "level": 15}]},
			{"x": 1, "y": 19, "name": "Sign", "type": "npc", "dialog": ["← Cerulean City (West)", "→ Vermilion City (East)", "BLIZZARD WARNING: Ice-type Pokemon active!"]},
			{"x": 47, "y": 19, "name": "Sign", "type": "npc", "dialog": ["→ Vermilion City (East)", "← Cerulean City (West)"]},
			{"x": 22, "y": 15, "name": "Researcher", "type": "npc", "dialog": ["The frozen lake has rare Ice-type Pokemon!", "I've spotted a Dratini in the deep snow..."]},
		],
		"encounters": [
			{"species_id": 7, "min_level": 14, "max_level": 18, "weight": 30},  # Sneasel
			{"species_id": 15, "min_level": 14, "max_level": 17, "weight": 20}, # Clefairy
			{"species_id": 5, "min_level": 15, "max_level": 18, "weight": 15},  # Geodude (mountain)
			{"species_id": 11, "min_level": 14, "max_level": 18, "weight": 15}, # Pidgey
			{"species_id": 13, "min_level": 16, "max_level": 20, "weight": 10}, # Aron (rare)
			{"species_id": 14, "min_level": 17, "max_level": 20, "weight": 5},  # Dratini (very rare!)
		],
	})

func _vermilion_city() -> Dictionary:
	var w = 40
	var h = 30
	var rows = _generate_town(w, h, "default")

	# Port / waterfront (south edge)
	for dy in range(23, 29):
		for dx in range(1, w - 1):
			rows[dy][dx] = W
	for dx in range(1, w - 1):
		rows[22][dx] = LS
		rows[22][dx] = LS

	# Deep water in south port
	for dy in range(25, 29):
		for dx in range(8, 32):
			rows[dy][dx] = DW

	# Docks / piers
	for dy in range(20, 26):
		rows[dy][12] = BR
		rows[dy][13] = BR
		rows[dy][26] = BR
		rows[dy][27] = BR

	# Gym (left)
	for dy in range(4, 12):
		for dx in range(3, 13):
			if dy == 4 or dy == 11 or dx == 3 or dx == 12:
				rows[dy][dx] = WL
			else:
				rows[dy][dx] = GF
	rows[11][7] = D

	# Pokecenter (right)
	for dy in range(4, 9):
		for dx in range(28, 37):
			if dy == 4 or dy == 8 or dx == 28 or dx == 36:
				rows[dy][dx] = WL
			else:
				rows[dy][dx] = F
	rows[8][32] = PC
	rows[8][33] = PC

	# Shop
	for dy in range(13, 18):
		for dx in range(28, 37):
			if dy == 13 or dy == 17 or dx == 28 or dx == 36:
				rows[dy][dx] = WL
			else:
				rows[dy][dx] = F
	rows[17][32] = SH
	rows[17][33] = SH

	return _make_area("Vermilion City", "town", w, h, rows, {
		"spawn": {"x": 1, "y": 14},
		"exits": [
			{"x": 0, "y": 14, "target_area": "Route 3", "target_x": 48, "target_y": 20},
			{"x": 0, "y": 15, "target_area": "Route 3", "target_x": 48, "target_y": 21},
			{"x": 39, "y": 14, "target_area": "Celadon City", "target_x": 1, "target_y": 14},
			{"x": 39, "y": 15, "target_area": "Celadon City", "target_x": 1, "target_y": 15},
		],
		"npcs": [
			{"x": 32, "y": 6, "name": "Nurse Joy", "type": "nurse", "dialog": ["Your Pokemon are healed!", "Safe travels, trainer!"]},
			{"x": 32, "y": 15, "name": "Shopkeeper", "type": "shop", "dialog": ["Buy Pokeballs here!", "We have the best stock in the port city!"]},
			{"x": 1, "y": 13, "name": "Sign", "type": "npc", "dialog": ["← Route 3 / Cerulean City (West)", "→ Celadon City (East)"]},
			{"x": 37, "y": 13, "name": "Sign", "type": "npc", "dialog": ["→ Celadon City (East)"]},
			{"x": 20, "y": 21, "name": "Sailor", "type": "npc", "dialog": ["The S.S. Anne docks here sometimes!", "Electric Pokemon hide in the tall grass near town."]},
			{"x": 14, "y": 18, "name": "Dock Worker", "type": "npc", "dialog": ["Great dock we have here!", "The deep water has strong Pokemon — be careful!"]},
		],
		"gym_leader": {
			"x": 7, "y": 7, "name": "Lt. Surge", "type": "gym_leader",
			"specialty": "electric", "badge": "Thunder Badge",
			"dialog": ["I'm Lt. Surge! Prepare to be shocked!"],
			"team": [{"id": 4, "level": 20}, {"id": 18, "level": 22}, {"id": 4, "level": 24}],
			"win_dialog": ["Electrifying battle! The Thunder Badge is yours!"],
		},
		"pokecenter": true, "shop": true,
		"encounters": [],
	})

func _celadon_city() -> Dictionary:
	var w = 40
	var h = 30
	var rows = _generate_town(w, h, "default")

	# Swamp area on east side
	for dy in range(4, 20):
		for dx in range(30, 39):
			var sh = (dx * 5 + dy * 11) % 100
			if sh < 25:
				rows[dy][dx] = SM
			elif sh < 40:
				rows[dy][dx] = W
			elif sh < 50:
				rows[dy][dx] = T
			else:
				rows[dy][dx] = G

	# Erika gym (left upper)
	for dy in range(3, 10):
		for dx in range(3, 13):
			if dy == 3 or dy == 9 or dx == 3 or dx == 12:
				rows[dy][dx] = WL
			else:
				rows[dy][dx] = GF
	rows[9][7] = D

	# Koga gym (left lower)
	for dy in range(16, 23):
		for dx in range(3, 13):
			if dy == 16 or dy == 22 or dx == 3 or dx == 12:
				rows[dy][dx] = WL
			else:
				rows[dy][dx] = GF
	rows[22][7] = D

	# Pokecenter (center-right)
	for dy in range(3, 8):
		for dx in range(22, 30):
			if dy == 3 or dy == 7 or dx == 22 or dx == 29:
				rows[dy][dx] = WL
			else:
				rows[dy][dx] = F
	rows[7][25] = PC
	rows[7][26] = PC

	# Shop
	for dy in range(11, 16):
		for dx in range(22, 30):
			if dy == 11 or dy == 15 or dx == 22 or dx == 29:
				rows[dy][dx] = WL
			else:
				rows[dy][dx] = F
	rows[15][25] = SH
	rows[15][26] = SH

	return _make_area("Celadon City", "town", w, h, rows, {
		"spawn": {"x": 1, "y": 14},
		"exits": [
			{"x": 0, "y": 14, "target_area": "Vermilion City", "target_x": 38, "target_y": 14},
			{"x": 0, "y": 15, "target_area": "Vermilion City", "target_x": 38, "target_y": 15},
			{"x": 39, "y": 14, "target_area": "Saffron City", "target_x": 1, "target_y": 14},
			{"x": 39, "y": 15, "target_area": "Saffron City", "target_x": 1, "target_y": 15},
		],
		"hidden_items": [
			{"x": 15, "y": 12, "type": "razz", "found": false},
			{"x": 32, "y": 18, "type": "ultraball", "found": false},
		],
		"npcs": [
			{"x": 25, "y": 5, "name": "Nurse Joy", "type": "nurse", "dialog": ["Healed!", "Celadon's Pokemon Center is the finest!"]},
			{"x": 25, "y": 13, "name": "Shopkeeper", "type": "shop", "dialog": ["Welcome to Celadon's big store!", "Best prices in the region!"]},
			{"x": 20, "y": 22, "name": "Rocket Grunt", "type": "rocket", "dialog": ["Team Rocket controls this city!", "You'll pay for interfering!"], "team": [{"id": 8, "level": 20}, {"id": 12, "level": 22}, {"id": 6, "level": 21}]},
			{"x": 7, "y": 19, "name": "Koga", "type": "gym_leader_2", "specialty": "poison", "badge": "Soul Badge",
			 "dialog": ["I am Koga, master of Poison! Can you withstand my toxic techniques?"],
			 "team": [{"id": 8, "level": 28}, {"id": 8, "level": 30}, {"id": 12, "level": 32}],
			 "win_dialog": ["Your spirit is strong! Take the Soul Badge!"]},
			{"x": 1, "y": 13, "name": "Sign", "type": "npc", "dialog": ["← Vermilion City (West)", "→ Saffron City (East)"]},
			{"x": 37, "y": 13, "name": "Sign", "type": "npc", "dialog": ["→ Saffron City (East)", "Watch out for the swamp to the east!"]},
			{"x": 35, "y": 10, "name": "Swamp Guide", "type": "npc", "dialog": ["The swamp east of town teems with life.", "Poison-type Pokemon lurk in those waters..."]},
		],
		"gym_leader": {
			"x": 7, "y": 6, "name": "Erika", "type": "gym_leader",
			"specialty": "grass", "badge": "Rainbow Badge",
			"dialog": ["I'm Erika. My grass Pokemon are beautiful and strong!"],
			"team": [{"id": 1, "level": 24}, {"id": 8, "level": 26}, {"id": 1, "level": 28}],
			"win_dialog": ["What a lovely battle! The Rainbow Badge is yours!"],
		},
		"pokecenter": true, "shop": true,
		"encounters": [
			{"species_id": 8, "min_level": 20, "max_level": 25, "weight": 25},  # Nidoran (swamp)
			{"species_id": 1, "min_level": 20, "max_level": 25, "weight": 20},  # Bulbasaur
			{"species_id": 6, "min_level": 22, "max_level": 27, "weight": 20},  # Gastly
			{"species_id": 12, "min_level": 21, "max_level": 26, "weight": 15}, # Murkrow
			{"species_id": 9, "min_level": 22, "max_level": 28, "weight": 10},  # Abra
			{"species_id": 19, "min_level": 24, "max_level": 28, "weight": 10}, # Mewtwo (very rare!)
		],
	})

func _saffron_city() -> Dictionary:
	var w = 40
	var h = 30
	var rows = _generate_town(w, h, "ruins")

	# Central Silph Co building
	for dy in range(11, 22):
		for dx in range(14, 26):
			rows[dy][dx] = F
	rows[21][19] = D
	rows[21][20] = D

	# Ruin aesthetics over some floor areas
	for dy in range(12, 21):
		for dx in range(15, 25):
			if (dx + dy) % 6 == 0:
				rows[dy][dx] = RU

	# Sabrina gym (left upper)
	for dy in range(3, 11):
		for dx in range(3, 13):
			if dy == 3 or dy == 10 or dx == 3 or dx == 12:
				rows[dy][dx] = WL
			else:
				rows[dy][dx] = GF
	rows[10][7] = D

	# Blaine gym (left lower)
	for dy in range(16, 24):
		for dx in range(3, 13):
			if dy == 16 or dy == 23 or dx == 3 or dx == 12:
				rows[dy][dx] = WL
			else:
				rows[dy][dx] = GF
	rows[23][7] = D

	# Pokecenter (right)
	for dy in range(3, 8):
		for dx in range(28, 37):
			if dy == 3 or dy == 7 or dx == 28 or dx == 36:
				rows[dy][dx] = WL
			else:
				rows[dy][dx] = F
	rows[7][32] = PC
	rows[7][33] = PC

	# Ruins scattered in town
	for dy in range(24, 29):
		for dx in range(18, 30):
			if (dx * 3 + dy * 7) % 5 == 0:
				rows[dy][dx] = RU
			elif (dx * 5 + dy * 3) % 7 == 0:
				rows[dy][dx] = CF

	# North exit to Pokemon League
	for dx in range(19, 22):
		rows[0][dx] = P
		rows[1][dx] = P

	return _make_area("Saffron City", "town", w, h, rows, {
		"spawn": {"x": 1, "y": 14},
		"exits": [
			{"x": 0, "y": 14, "target_area": "Celadon City", "target_x": 38, "target_y": 14},
			{"x": 0, "y": 15, "target_area": "Celadon City", "target_x": 38, "target_y": 15},
			{"x": 20, "y": 0, "target_area": "Pokemon League", "target_x": 20, "target_y": 28},
			{"x": 21, "y": 0, "target_area": "Pokemon League", "target_x": 21, "target_y": 28},
		],
		"npcs": [
			{"x": 32, "y": 5, "name": "Nurse Joy", "type": "nurse", "dialog": ["Healed!", "The ancient city's power heals all wounds..."]},
			{"x": 19, "y": 1, "name": "Sign", "type": "npc", "dialog": ["↑ Pokemon League (North)", "← Celadon City (West)"]},
			{"x": 1, "y": 13, "name": "Sign", "type": "npc", "dialog": ["← Celadon City (West)", "↑ Pokemon League (North)"]},
			{"x": 19, "y": 23, "name": "Rival", "type": "rival", "dialog": [
				"You again! I've been training hard!",
				"This time I won't lose!",
			], "team": [{"id": 11, "level": 30}, {"id": 2, "level": 32}, {"id": 16, "level": 32}], "battle_index": 2},
			{"x": 7, "y": 20, "name": "Blaine", "type": "gym_leader_2", "specialty": "fire", "badge": "Volcano Badge",
			 "dialog": ["I'm Blaine! My fire burns hotter than the sun!"],
			 "team": [{"id": 2, "level": 34}, {"id": 16, "level": 36}, {"id": 2, "level": 38}],
			 "win_dialog": ["You extinguished my flames! The Volcano Badge is yours!"]},
			{"x": 20, "y": 14, "name": "Giovanni", "type": "gym_leader_2", "specialty": "ground", "badge": "Earth Badge",
			 "dialog": ["I am Giovanni. I was once Team Shadow's leader...", "But I've seen the error of my ways.", "Defeat me, and earn the final badge!"],
			 "team": [{"id": 10, "level": 36}, {"id": 5, "level": 38}, {"id": 10, "level": 40}],
			 "win_dialog": ["You are truly worthy! Take the Earth Badge — the final badge!", "The Pokemon League awaits you!"]},
			{"x": 28, "y": 25, "name": "Archaeologist", "type": "npc", "dialog": ["Saffron City was built on ancient ruins!", "The ruins attract Psychic and Ghost Pokemon..."]},
		],
		"gym_leader": {
			"x": 7, "y": 6, "name": "Sabrina", "type": "gym_leader",
			"specialty": "psychic", "badge": "Marsh Badge",
			"dialog": ["I foresaw your arrival... I'm Sabrina."],
			"team": [{"id": 9, "level": 32}, {"id": 19, "level": 34}, {"id": 9, "level": 36}],
			"win_dialog": ["I did not foresee this... The Marsh Badge is yours."],
		},
		"pokecenter": true, "shop": false,
		"encounters": [
			{"species_id": 9, "min_level": 25, "max_level": 30, "weight": 25},  # Abra (ruins)
			{"species_id": 6, "min_level": 26, "max_level": 30, "weight": 20},  # Gastly
			{"species_id": 19, "min_level": 28, "max_level": 32, "weight": 10}, # Mewtwo (rare!)
			{"species_id": 5, "min_level": 25, "max_level": 30, "weight": 20},  # Geodude
			{"species_id": 13, "min_level": 26, "max_level": 31, "weight": 15}, # Aron
			{"species_id": 12, "min_level": 27, "max_level": 32, "weight": 10}, # Murkrow
		],
	})

func _pokemon_league() -> Dictionary:
	var w = 40
	var h = 30
	var rows = _generate_route(w, h, "volcano", 15)

	# League hall (upper section)
	for dy in range(3, 11):
		for dx in range(5, 35):
			rows[dy][dx] = GF
	# Hall walls
	for dx in range(5, 35):
		rows[3][dx] = WL
		rows[10][dx] = WL
	for dy in range(3, 11):
		rows[dy][5] = WL
		rows[dy][34] = WL
	rows[10][19] = D
	rows[10][20] = D

	# Champion room (center)
	for dy in range(13, 21):
		for dx in range(12, 28):
			rows[dy][dx] = F
	for dx in range(12, 28):
		rows[13][dx] = WL
		rows[20][dx] = WL
	for dy in range(13, 21):
		rows[dy][12] = WL
		rows[dy][27] = WL
	rows[20][19] = D
	rows[20][20] = D

	# Lava river across map
	for dx in range(1, w - 1):
		if dx < 10 or dx > 30:
			rows[22][dx] = LV
			rows[23][dx] = LV
		else:
			rows[22][dx] = BR  # bridge over lava

	# Volcanic terrain in south
	for dy in range(24, h - 1):
		for dx in range(1, w - 1):
			var vh = (dx * 7 + dy * 5) % 100
			if vh < 20:
				rows[dy][dx] = LV
			elif vh < 50:
				rows[dy][dx] = VR
			else:
				rows[dy][dx] = CF

	# South entry path
	for dy in range(25, h - 1):
		rows[dy][20] = P
		rows[dy][21] = P

	return _make_area("Pokemon League", "league", w, h, rows, {
		"spawn": {"x": 20, "y": 28},
		"exits": [
			{"x": 20, "y": 29, "target_area": "Saffron City", "target_x": 20, "target_y": 1},
			{"x": 21, "y": 29, "target_area": "Saffron City", "target_x": 21, "target_y": 1},
		],
		"npcs": [
			# Elite Four
			{"x": 9, "y": 6, "name": "Lorelei", "type": "elite4", "dialog": ["I'm Lorelei of the Elite Four!", "Ice is my domain — you'll freeze!"], "team": [{"id": 7, "level": 42}, {"id": 17, "level": 44}]},
			{"x": 14, "y": 6, "name": "Bruno", "type": "elite4", "dialog": ["My fighting spirit burns!", "Power alone wins battles!"], "team": [{"id": 5, "level": 44}, {"id": 13, "level": 46}]},
			{"x": 20, "y": 6, "name": "Agatha", "type": "elite4", "dialog": ["Heh heh, scared?", "Ghosts fear no one..."], "team": [{"id": 6, "level": 46}, {"id": 20, "level": 48}]},
			{"x": 26, "y": 6, "name": "Lance", "type": "elite4", "dialog": ["I am Lance, the Dragon Master!", "Dragons answer only to the strongest!"], "team": [{"id": 14, "level": 50}, {"id": 16, "level": 52}]},
			# Champion (Rival)
			{"x": 19, "y": 16, "name": "Champion", "type": "champion", "dialog": [
				"So you finally made it here...",
				"I've been waiting for this moment!",
				"I'm the Pokemon League Champion now!",
				"Let's settle this once and for all!",
			], "team": [{"id": 11, "level": 48}, {"id": 2, "level": 50}, {"id": 16, "level": 52}, {"id": 17, "level": 55}]},
			{"x": 19, "y": 27, "name": "Sign", "type": "npc", "dialog": ["↓ Saffron City (South)", "You stand before the Pokemon League!", "Only the strongest trainers reach this place."]},
			{"x": 4, "y": 25, "name": "Veteran", "type": "npc", "dialog": ["The volcano's heat powers the League!", "Fire and Dragon Pokemon thrive here."]},
		],
		"pokecenter": false, "shop": false,
		"encounters": [
			{"species_id": 2, "min_level": 35, "max_level": 42, "weight": 25},  # Charmander
			{"species_id": 16, "min_level": 38, "max_level": 45, "weight": 15}, # Arcanine
			{"species_id": 5, "min_level": 35, "max_level": 42, "weight": 20},  # Geodude
			{"species_id": 14, "min_level": 38, "max_level": 45, "weight": 10}, # Dratini
			{"species_id": 6, "min_level": 36, "max_level": 43, "weight": 15},  # Gastly
			{"species_id": 13, "min_level": 37, "max_level": 45, "weight": 10}, # Aron
		],
	})
