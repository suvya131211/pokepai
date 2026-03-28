extends RefCounted

# Tile shortcuts
const W = 0   # water
const G = 1   # grass
const T = 2   # tall grass
const TR = 3  # tree
const P = 4   # path
const F = 5   # floor
const WL = 6  # wall
const D = 7   # door
const S = 8   # sand
const CF = 9  # cave floor
const CW = 10 # cave wall
const L = 11  # ledge
const SN = 12 # sign
const PC = 13 # pokecenter
const SH = 14 # shop
const GF = 15 # gym floor
const FL = 16 # flower
const FN = 17 # fence

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

func _pallet_town() -> Dictionary:
	# 30x20 peaceful starting town: oak's lab, player house, rival house
	var rows = []
	# Row 0-1: trees along top with exit north to Route 1
	rows.append([TR,TR,TR,TR,TR,TR,TR,TR,TR,TR,TR,TR,TR,TR,P,P,TR,TR,TR,TR,TR,TR,TR,TR,TR,TR,TR,TR,TR,TR])
	rows.append([TR,TR,TR,TR,TR,TR,TR,TR,TR,TR,TR,TR,TR,TR,P,P,TR,TR,TR,TR,TR,TR,TR,TR,TR,TR,TR,TR,TR,TR])
	# Row 2-3: grass with path
	rows.append([TR,G,G,G,G,G,FL,G,G,G,G,G,G,G,P,P,G,G,G,G,G,G,G,FL,G,G,G,G,G,TR])
	rows.append([TR,G,G,FL,G,G,G,G,G,G,G,G,G,G,P,P,G,G,G,G,G,G,G,G,G,G,FL,G,G,TR])
	# Row 4-5: houses (player house left, rival house right)
	rows.append([TR,G,G,WL,WL,WL,WL,WL,G,G,G,G,G,G,P,P,G,G,G,G,G,WL,WL,WL,WL,WL,G,G,G,TR])
	rows.append([TR,G,G,WL,F,F,F,D,G,G,G,G,G,G,P,P,G,G,G,G,G,WL,F,F,F,D,G,G,G,TR])
	rows.append([TR,G,G,WL,WL,WL,WL,WL,G,G,G,G,G,G,P,P,G,G,G,G,G,WL,WL,WL,WL,WL,G,G,G,TR])
	# Row 7-8: path area
	rows.append([TR,G,G,G,G,G,G,G,G,G,G,G,G,P,P,P,P,G,G,G,G,G,G,G,G,G,G,G,G,TR])
	rows.append([TR,G,G,G,G,G,G,G,G,G,G,G,P,P,G,G,P,P,G,G,G,G,G,G,G,G,G,G,G,TR])
	# Row 9-10: flowers and grass
	rows.append([TR,G,FL,G,G,G,G,G,G,G,G,P,P,G,G,G,G,P,P,G,G,G,G,G,G,G,G,FL,G,TR])
	rows.append([TR,G,G,G,G,G,G,G,G,G,G,P,G,G,G,G,G,G,P,G,G,G,G,G,G,G,G,G,G,TR])
	# Row 11-14: Prof Oak's Lab (center bottom)
	rows.append([TR,G,G,G,G,G,G,G,G,G,P,P,G,G,G,G,G,G,P,P,G,G,G,G,G,G,G,G,G,TR])
	rows.append([TR,G,G,G,G,G,G,G,G,WL,WL,WL,WL,WL,WL,WL,WL,WL,WL,WL,WL,G,G,G,G,G,G,G,G,TR])
	rows.append([TR,G,G,G,G,G,G,G,G,WL,F,F,F,F,F,F,F,F,F,F,WL,G,G,G,G,G,G,G,G,TR])
	rows.append([TR,G,G,G,G,G,G,G,G,WL,F,F,F,F,D,D,F,F,F,F,WL,G,G,G,G,G,G,G,G,TR])
	rows.append([TR,G,G,G,G,G,G,G,G,WL,WL,WL,WL,WL,WL,WL,WL,WL,WL,WL,WL,G,G,G,G,G,G,G,G,TR])
	# Row 16-19: bottom area
	rows.append([TR,G,G,G,SN,G,G,G,G,G,G,G,G,G,P,P,G,G,G,G,G,G,G,G,G,SN,G,G,G,TR])
	rows.append([TR,G,G,G,G,G,G,G,G,G,G,G,G,G,P,P,G,G,G,G,G,G,G,G,G,G,G,G,G,TR])
	rows.append([TR,G,G,G,FL,G,W,W,W,W,G,G,G,G,P,P,G,G,G,G,W,W,W,W,G,FL,G,G,G,TR])
	rows.append([TR,TR,TR,TR,TR,TR,W,W,W,W,TR,TR,TR,TR,TR,TR,TR,TR,TR,TR,W,W,W,W,TR,TR,TR,TR,TR,TR])

	return _make_area("Pallet Town", "town", 30, 20, rows, {
		"spawn": {"x": 14, "y": 10},
		"exits": [
			{"x": 14, "y": 0, "target_area": "Route 1", "target_x": 14, "target_y": 28},
			{"x": 15, "y": 0, "target_area": "Route 1", "target_x": 15, "target_y": 28},
		],
		"npcs": [
			{"x": 14, "y": 13, "name": "Prof. Oak", "type": "professor", "dialog": [
				"Welcome to the world of Pokemon!",
				"I'm Professor Oak. I study Pokemon.",
				"A dark force threatens our land... DARKRAI stirs.",
				"Choose your first Pokemon and begin your journey!",
				"Collect 8 Gym Badges and challenge the Pokemon League!",
			]},
			{"x": 5, "y": 5, "name": "Mom", "type": "npc", "dialog": ["Good luck on your adventure, dear!", "Come home safe!"]},
			{"x": 24, "y": 5, "name": "Rival", "type": "rival", "dialog": ["I'll be the Pokemon Champion before you! Just watch!"]},
		],
		"pokecenter": false, "shop": false,
		"encounters": [],
	})

func _route_1() -> Dictionary:
	# 30x30 vertical route with grass, trainers, and wild Pokemon
	var rows = []
	for y in 30:
		var row = []
		for x in 30:
			if x == 0 or x == 29:
				row.append(TR)
			elif x == 14 or x == 15:
				row.append(P)
			elif (x >= 3 and x <= 8 and y >= 5 and y <= 12) or (x >= 20 and x <= 26 and y >= 15 and y <= 22):
				row.append(T)  # tall grass patches
			elif x >= 10 and x <= 12 and y == 14:
				row.append(FN)
			else:
				row.append(G)
		rows.append(row)

	return _make_area("Route 1", "route", 30, 30, rows, {
		"spawn": {"x": 14, "y": 28},
		"exits": [
			{"x": 14, "y": 29, "target_area": "Pallet Town", "target_x": 14, "target_y": 1},
			{"x": 15, "y": 29, "target_area": "Pallet Town", "target_x": 15, "target_y": 1},
			{"x": 14, "y": 0, "target_area": "Pewter City", "target_x": 14, "target_y": 18},
			{"x": 15, "y": 0, "target_area": "Pewter City", "target_x": 15, "target_y": 18},
		],
		"npcs": [
			{"x": 16, "y": 10, "name": "Youngster Joey", "type": "trainer", "dialog": ["My Pidgey is the best!"], "team": [{"id": 11, "level": 3}]},
			{"x": 13, "y": 20, "name": "Lass Jenny", "type": "trainer", "dialog": ["Want to battle?"], "team": [{"id": 8, "level": 4}]},
		],
		"encounters": [
			{"species_id": 11, "min_level": 2, "max_level": 5, "weight": 40},  # Pidgey
			{"species_id": 8, "min_level": 2, "max_level": 4, "weight": 30},   # Nidoran
			{"species_id": 10, "min_level": 2, "max_level": 4, "weight": 20},  # Sandshrew
			{"species_id": 1, "min_level": 3, "max_level": 5, "weight": 10},   # Bulbasaur (rare)
		],
	})

func _pewter_city() -> Dictionary:
	var rows = []
	for y in 20:
		var row = []
		for x in 30:
			if x == 0 or x == 29 or y == 0:
				row.append(TR)
			elif x == 14 or x == 15:
				row.append(P)
			elif x >= 3 and x <= 8 and y >= 3 and y <= 6:
				row.append(GF if y > 3 else WL)  # Gym
			elif x == 3 and y == 6:
				row.append(D)  # Gym door
			elif x >= 20 and x <= 25 and y >= 3 and y <= 5:
				row.append(F if y < 5 else PC)  # Pokecenter
			elif x >= 20 and x <= 25 and y >= 8 and y <= 10:
				row.append(F if y < 10 else SH)  # Shop
			else:
				if (x + y) % 7 != 0:
					row.append(G)
				else:
					row.append(FL)
		rows.append(row)

	return _make_area("Pewter City", "town", 30, 20, rows, {
		"spawn": {"x": 14, "y": 18},
		"exits": [
			{"x": 14, "y": 19, "target_area": "Route 1", "target_x": 14, "target_y": 1},
			{"x": 15, "y": 19, "target_area": "Route 1", "target_x": 15, "target_y": 1},
			{"x": 29, "y": 10, "target_area": "Mt. Moon", "target_x": 1, "target_y": 10},
		],
		"npcs": [
			{"x": 22, "y": 4, "name": "Nurse Joy", "type": "nurse", "dialog": ["Welcome! Let me heal your Pokemon.", "Your Pokemon are fully healed!"]},
			{"x": 22, "y": 9, "name": "Shopkeeper", "type": "shop", "dialog": ["Welcome to the Poke Mart!"]},
		],
		"gym_leader": {
			"x": 5, "y": 4, "name": "Brock", "type": "gym_leader",
			"specialty": "rock", "badge": "Boulder Badge",
			"dialog": ["I'm Brock, the Pewter City Gym Leader!", "My rock-hard Pokemon will crush you!"],
			"team": [{"id": 5, "level": 8}, {"id": 10, "level": 10}],  # Geodude, Sandshrew
			"win_dialog": ["You beat me! Take the Boulder Badge!", "You've earned my respect."],
		},
		"pokecenter": true, "shop": true,
		"encounters": [],
	})

func _mt_moon() -> Dictionary:
	var rows = []
	for y in 25:
		var row = []
		for x in 30:
			if x == 0 or x == 29 or y == 0 or y == 24:
				row.append(CW)
			elif (x + y * 3) % 11 == 0 and x > 2 and x < 27 and y > 2 and y < 22:
				row.append(CW)  # random pillars
			else:
				row.append(CF)
		rows.append(row)

	return _make_area("Mt. Moon", "cave", 30, 25, rows, {
		"spawn": {"x": 1, "y": 10},
		"exits": [
			{"x": 0, "y": 10, "target_area": "Pewter City", "target_x": 28, "target_y": 10},
			{"x": 29, "y": 12, "target_area": "Cerulean City", "target_x": 1, "target_y": 10},
		],
		"npcs": [
			{"x": 10, "y": 8, "name": "Rocket Grunt", "type": "rocket", "dialog": ["Hand over your Pokemon!", "Team Rocket will rule!"], "team": [{"id": 8, "level": 9}, {"id": 12, "level": 10}]},
			{"x": 20, "y": 15, "name": "Rocket Grunt", "type": "rocket", "dialog": ["You'll never stop Team Rocket!"], "team": [{"id": 6, "level": 11}]},
		],
		"encounters": [
			{"species_id": 5, "min_level": 6, "max_level": 10, "weight": 30},   # Geodude
			{"species_id": 6, "min_level": 6, "max_level": 9, "weight": 20},    # Gastly
			{"species_id": 15, "min_level": 6, "max_level": 9, "weight": 15},   # Clefairy
			{"species_id": 9, "min_level": 7, "max_level": 10, "weight": 10},   # Abra
			{"species_id": 13, "min_level": 8, "max_level": 11, "weight": 5},   # Aron (rare)
		],
	})

func _cerulean_city() -> Dictionary:
	var rows = []
	for y in 20:
		var row = []
		for x in 30:
			if x == 0 or x == 29 or y == 0 or y == 19:
				row.append(TR if y < 19 else W)
			elif x == 14 or x == 15:
				row.append(P)
			elif x >= 3 and x <= 8 and y >= 3 and y <= 7:
				row.append(GF if y > 3 and y < 7 else WL)
			elif x >= 22 and x <= 27 and y >= 3 and y <= 5:
				row.append(PC if y == 5 else F)
			elif y >= 16 and y <= 18 and x >= 5 and x <= 25:
				row.append(W)
			else:
				row.append(G)
		rows.append(row)

	return _make_area("Cerulean City", "town", 30, 20, rows, {
		"spawn": {"x": 1, "y": 10},
		"exits": [
			{"x": 0, "y": 10, "target_area": "Mt. Moon", "target_x": 28, "target_y": 12},
			{"x": 29, "y": 10, "target_area": "Route 3", "target_x": 1, "target_y": 10},
		],
		"npcs": [
			{"x": 24, "y": 4, "name": "Nurse Joy", "type": "nurse", "dialog": ["Let me heal your Pokemon!"]},
			{"x": 16, "y": 8, "name": "Rival", "type": "rival", "dialog": [
				"Well well, look who made it!",
				"Let's see how strong you've gotten!",
			], "team": [{"id": 11, "level": 14}, {"id": 2, "level": 16}], "battle_index": 1},
		],
		"gym_leader": {
			"x": 5, "y": 5, "name": "Misty", "type": "gym_leader",
			"specialty": "water", "badge": "Cascade Badge",
			"dialog": ["I'm Misty! My water Pokemon are unstoppable!"],
			"team": [{"id": 3, "level": 16}, {"id": 17, "level": 18}],  # Squirtle, Gyarados
			"win_dialog": ["You beat my water Pokemon! Take the Cascade Badge!"],
		},
		"pokecenter": true, "shop": false,
		"encounters": [],
	})

func _route_3() -> Dictionary:
	var rows = []
	for y in 25:
		var row = []
		for x in 30:
			if x == 0 or x == 29:
				row.append(TR)
			elif y == 0 or y == 24:
				row.append(FN)
			elif x == 14 or x == 15:
				row.append(P)
			elif (x >= 3 and x <= 10 and y >= 4 and y <= 10) or (x >= 18 and x <= 26 and y >= 12 and y <= 20):
				row.append(T)
			else:
				row.append(G)
		rows.append(row)

	return _make_area("Route 3", "route", 30, 25, rows, {
		"spawn": {"x": 1, "y": 10},
		"exits": [
			{"x": 0, "y": 10, "target_area": "Cerulean City", "target_x": 28, "target_y": 10},
			{"x": 29, "y": 12, "target_area": "Vermilion City", "target_x": 1, "target_y": 10},
		],
		"npcs": [
			{"x": 12, "y": 6, "name": "Hiker Mike", "type": "trainer", "dialog": ["These mountains are tough!"], "team": [{"id": 5, "level": 14}, {"id": 13, "level": 15}]},
			{"x": 20, "y": 16, "name": "Bug Catcher Sam", "type": "trainer", "dialog": ["Check out my Pokemon!"], "team": [{"id": 1, "level": 15}]},
			{"x": 16, "y": 22, "name": "Picnicker Amy", "type": "trainer", "dialog": ["Battle me!"], "team": [{"id": 15, "level": 14}, {"id": 4, "level": 14}]},
		],
		"encounters": [
			{"species_id": 11, "min_level": 10, "max_level": 14, "weight": 25},  # Pidgey
			{"species_id": 1, "min_level": 10, "max_level": 14, "weight": 20},   # Bulbasaur
			{"species_id": 4, "min_level": 10, "max_level": 13, "weight": 20},   # Pikachu
			{"species_id": 7, "min_level": 11, "max_level": 14, "weight": 15},   # Sneasel
			{"species_id": 14, "min_level": 12, "max_level": 15, "weight": 5},   # Dratini (rare)
		],
	})

func _vermilion_city() -> Dictionary:
	var rows = []
	for y in 20:
		var row = []
		for x in 30:
			if x == 0 or x == 29:
				row.append(TR)
			elif y == 0 or y == 19:
				row.append(W if y == 19 else TR)
			elif x == 14 or x == 15:
				row.append(P)
			elif x >= 3 and x <= 8 and y >= 4 and y <= 8:
				row.append(GF if y > 4 and y < 8 else WL)
			elif x >= 22 and x <= 27 and y >= 3 and y <= 5:
				row.append(PC if y == 5 else F)
			elif x >= 22 and x <= 27 and y >= 8 and y <= 10:
				row.append(SH if y == 10 else F)
			else:
				row.append(G)
		rows.append(row)

	return _make_area("Vermilion City", "town", 30, 20, rows, {
		"spawn": {"x": 1, "y": 10},
		"exits": [
			{"x": 0, "y": 10, "target_area": "Route 3", "target_x": 28, "target_y": 12},
			{"x": 29, "y": 10, "target_area": "Celadon City", "target_x": 1, "target_y": 10},
		],
		"npcs": [
			{"x": 24, "y": 4, "name": "Nurse Joy", "type": "nurse", "dialog": ["Your Pokemon are healed!"]},
			{"x": 24, "y": 9, "name": "Shopkeeper", "type": "shop", "dialog": ["Buy Pokeballs here!"]},
		],
		"gym_leader": {
			"x": 5, "y": 6, "name": "Lt. Surge", "type": "gym_leader",
			"specialty": "electric", "badge": "Thunder Badge",
			"dialog": ["I'm Lt. Surge! Prepare to be shocked!"],
			"team": [{"id": 4, "level": 22}, {"id": 18, "level": 24}],  # Pikachu, Raichu
			"win_dialog": ["Electrifying battle! The Thunder Badge is yours!"],
		},
		"pokecenter": true, "shop": true,
		"encounters": [],
	})

func _celadon_city() -> Dictionary:
	var rows = []
	for y in 20:
		var row = []
		for x in 30:
			if x == 0 or x == 29 or y == 0 or y == 19:
				row.append(TR)
			elif x == 14 or x == 15:
				row.append(P)
			elif x >= 3 and x <= 8 and y >= 2 and y <= 6:
				row.append(GF if y > 2 and y < 6 else WL)  # Erika gym
			elif x >= 3 and x <= 8 and y >= 10 and y <= 14:
				row.append(GF if y > 10 and y < 14 else WL)  # Koga gym
			elif x >= 22 and x <= 27 and y >= 3 and y <= 5:
				row.append(PC if y == 5 else F)
			elif x >= 22 and x <= 27 and y >= 8 and y <= 10:
				row.append(SH if y == 10 else F)
			else:
				if (x + y) % 5 != 0:
					row.append(G)
				else:
					row.append(FL)
		rows.append(row)

	return _make_area("Celadon City", "town", 30, 20, rows, {
		"spawn": {"x": 1, "y": 10},
		"exits": [
			{"x": 0, "y": 10, "target_area": "Vermilion City", "target_x": 28, "target_y": 10},
			{"x": 29, "y": 10, "target_area": "Saffron City", "target_x": 1, "target_y": 10},
		],
		"npcs": [
			{"x": 24, "y": 4, "name": "Nurse Joy", "type": "nurse", "dialog": ["Healed!"]},
			{"x": 24, "y": 9, "name": "Shopkeeper", "type": "shop", "dialog": ["Welcome!"]},
			{"x": 15, "y": 15, "name": "Rocket Grunt", "type": "rocket", "dialog": ["Team Rocket controls this city!", "You'll pay for interfering!"], "team": [{"id": 8, "level": 22}, {"id": 12, "level": 24}, {"id": 6, "level": 23}]},
		],
		"gym_leader": {
			"x": 5, "y": 4, "name": "Erika", "type": "gym_leader",
			"specialty": "grass", "badge": "Rainbow Badge",
			"dialog": ["I'm Erika. My grass Pokemon are beautiful and strong!"],
			"team": [{"id": 1, "level": 26}, {"id": 8, "level": 28}],
			"win_dialog": ["What a lovely battle! The Rainbow Badge is yours!"],
		},
		"pokecenter": true, "shop": true,
		"encounters": [],
	})

func _saffron_city() -> Dictionary:
	var rows = []
	for y in 20:
		var row = []
		for x in 30:
			if x == 0 or x == 29 or y == 0 or y == 19:
				row.append(WL)
			elif x == 14 or x == 15:
				row.append(P)
			elif x >= 3 and x <= 8 and y >= 2 and y <= 6:
				row.append(GF if y > 2 and y < 6 else WL)  # Sabrina gym
			elif x >= 3 and x <= 8 and y >= 10 and y <= 14:
				row.append(GF if y > 10 and y < 14 else WL)  # Blaine gym
			elif x >= 22 and x <= 27 and y >= 3 and y <= 5:
				row.append(PC if y == 5 else F)
			elif x >= 10 and x <= 19 and y >= 10 and y <= 16:
				row.append(F)  # Silph Co
			else:
				row.append(P)
		rows.append(row)

	return _make_area("Saffron City", "town", 30, 20, rows, {
		"spawn": {"x": 1, "y": 10},
		"exits": [
			{"x": 0, "y": 10, "target_area": "Celadon City", "target_x": 28, "target_y": 10},
			{"x": 14, "y": 0, "target_area": "Pokemon League", "target_x": 14, "target_y": 18},
			{"x": 15, "y": 0, "target_area": "Pokemon League", "target_x": 15, "target_y": 18},
		],
		"npcs": [
			{"x": 24, "y": 4, "name": "Nurse Joy", "type": "nurse", "dialog": ["Healed!"]},
			{"x": 14, "y": 13, "name": "Rival", "type": "rival", "dialog": [
				"You again! I've been training hard!",
				"This time I won't lose!",
			], "team": [{"id": 11, "level": 32}, {"id": 2, "level": 34}, {"id": 16, "level": 35}], "battle_index": 2},
			{"x": 16, "y": 12, "name": "Giovanni", "type": "rocket", "dialog": [
				"So you've come to challenge Team Rocket...",
				"I am Giovanni, the boss of Team Rocket!",
				"And I'm also a Gym Leader. Defeat me if you can!",
			], "team": [{"id": 10, "level": 34}, {"id": 8, "level": 35}, {"id": 5, "level": 36}]},
		],
		"gym_leader": {
			"x": 5, "y": 4, "name": "Sabrina", "type": "gym_leader",
			"specialty": "psychic", "badge": "Marsh Badge",
			"dialog": ["I foresaw your arrival... I'm Sabrina."],
			"team": [{"id": 9, "level": 34}, {"id": 19, "level": 38}],  # Abra, Mewtwo
			"win_dialog": ["I did not foresee this... The Marsh Badge is yours."],
		},
		"pokecenter": true, "shop": false,
		"encounters": [],
	})

func _pokemon_league() -> Dictionary:
	var rows = []
	for y in 20:
		var row = []
		for x in 30:
			if x == 0 or x == 29 or y == 0:
				row.append(WL)
			elif y == 19:
				row.append(TR)
			elif x == 14 or x == 15:
				row.append(P)
			elif x >= 5 and x <= 24 and y >= 2 and y <= 8:
				row.append(GF)  # League hall
			elif x >= 11 and x <= 18 and y >= 10 and y <= 14:
				row.append(F)  # Champion room
			else:
				row.append(G)
		rows.append(row)

	return _make_area("Pokemon League", "league", 30, 20, rows, {
		"spawn": {"x": 14, "y": 18},
		"exits": [
			{"x": 14, "y": 19, "target_area": "Saffron City", "target_x": 14, "target_y": 1},
			{"x": 15, "y": 19, "target_area": "Saffron City", "target_x": 15, "target_y": 1},
		],
		"npcs": [
			# Elite Four
			{"x": 8, "y": 5, "name": "Lorelei", "type": "elite4", "dialog": ["I'm Lorelei of the Elite Four!"], "team": [{"id": 7, "level": 42}, {"id": 17, "level": 44}]},
			{"x": 12, "y": 5, "name": "Bruno", "type": "elite4", "dialog": ["My fighting spirit burns!"], "team": [{"id": 5, "level": 44}, {"id": 13, "level": 46}]},
			{"x": 17, "y": 5, "name": "Agatha", "type": "elite4", "dialog": ["Heh heh, scared?"], "team": [{"id": 6, "level": 46}, {"id": 20, "level": 48}]},
			{"x": 21, "y": 5, "name": "Lance", "type": "elite4", "dialog": ["I am Lance, the Dragon Master!"], "team": [{"id": 14, "level": 48}, {"id": 16, "level": 50}]},
			# Champion (Rival)
			{"x": 14, "y": 12, "name": "Champion", "type": "champion", "dialog": [
				"So you finally made it here...",
				"I've been waiting for this moment!",
				"I'm the Pokemon League Champion now!",
				"Let's settle this once and for all!",
			], "team": [{"id": 11, "level": 48}, {"id": 2, "level": 50}, {"id": 16, "level": 50}, {"id": 17, "level": 52}]},
		],
		"pokecenter": false, "shop": false,
		"encounters": [],
	})
