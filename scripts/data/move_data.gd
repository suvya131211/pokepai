extends Node

# Move data: {name, type, power, accuracy, pp, category, effect}
# category: "physical", "special", "status"
# effect: "none", "sleep", "paralyze", "poison", "lower_atk", "lower_def", "flinch", "false_swipe"
var moves: Dictionary = {
    # Normal moves
    "Tackle": {"type":"normal","power":40,"accuracy":100,"pp":35,"category":"physical","effect":"none"},
    "Scratch": {"type":"normal","power":40,"accuracy":100,"pp":35,"category":"physical","effect":"none"},
    "Pound": {"type":"normal","power":40,"accuracy":100,"pp":35,"category":"physical","effect":"none"},
    "Quick Attack": {"type":"normal","power":40,"accuracy":100,"pp":30,"category":"physical","effect":"none"},
    "False Swipe": {"type":"normal","power":40,"accuracy":100,"pp":40,"category":"physical","effect":"false_swipe"},
    "Growl": {"type":"normal","power":0,"accuracy":100,"pp":40,"category":"status","effect":"lower_atk"},

    # Fire
    "Ember": {"type":"fire","power":40,"accuracy":100,"pp":25,"category":"special","effect":"none"},
    "Flamethrower": {"type":"fire","power":90,"accuracy":100,"pp":15,"category":"special","effect":"none"},
    "Fire Spin": {"type":"fire","power":35,"accuracy":85,"pp":15,"category":"special","effect":"none"},

    # Water
    "Water Gun": {"type":"water","power":40,"accuracy":100,"pp":25,"category":"special","effect":"none"},
    "Surf": {"type":"water","power":90,"accuracy":100,"pp":15,"category":"special","effect":"none"},
    "Bubble": {"type":"water","power":40,"accuracy":100,"pp":30,"category":"special","effect":"none"},

    # Grass
    "Vine Whip": {"type":"grass","power":45,"accuracy":100,"pp":25,"category":"physical","effect":"none"},
    "Razor Leaf": {"type":"grass","power":55,"accuracy":95,"pp":25,"category":"physical","effect":"none"},
    "Sleep Powder": {"type":"grass","power":0,"accuracy":75,"pp":15,"category":"status","effect":"sleep"},
    "Leech Seed": {"type":"grass","power":0,"accuracy":90,"pp":10,"category":"status","effect":"leech"},

    # Electric
    "Thunder Shock": {"type":"electric","power":40,"accuracy":100,"pp":30,"category":"special","effect":"paralyze"},
    "Thunderbolt": {"type":"electric","power":90,"accuracy":100,"pp":15,"category":"special","effect":"none"},
    "Thunder Wave": {"type":"electric","power":0,"accuracy":90,"pp":20,"category":"status","effect":"paralyze"},

    # Rock/Ground
    "Rock Throw": {"type":"rock","power":50,"accuracy":90,"pp":15,"category":"physical","effect":"none"},
    "Rock Slide": {"type":"rock","power":75,"accuracy":90,"pp":10,"category":"physical","effect":"flinch"},
    "Earthquake": {"type":"ground","power":100,"accuracy":100,"pp":10,"category":"physical","effect":"none"},
    "Dig": {"type":"ground","power":80,"accuracy":100,"pp":10,"category":"physical","effect":"none"},

    # Ghost/Dark
    "Shadow Ball": {"type":"ghost","power":80,"accuracy":100,"pp":15,"category":"special","effect":"none"},
    "Lick": {"type":"ghost","power":30,"accuracy":100,"pp":30,"category":"physical","effect":"paralyze"},
    "Bite": {"type":"dark","power":60,"accuracy":100,"pp":25,"category":"physical","effect":"flinch"},
    "Dark Pulse": {"type":"dark","power":80,"accuracy":100,"pp":15,"category":"special","effect":"none"},

    # Ice
    "Ice Beam": {"type":"ice","power":90,"accuracy":100,"pp":10,"category":"special","effect":"none"},
    "Icy Wind": {"type":"ice","power":55,"accuracy":95,"pp":15,"category":"special","effect":"lower_atk"},
    "Ice Shard": {"type":"ice","power":40,"accuracy":100,"pp":30,"category":"physical","effect":"none"},

    # Psychic/Fairy
    "Psychic": {"type":"psychic","power":90,"accuracy":100,"pp":10,"category":"special","effect":"none"},
    "Confusion": {"type":"psychic","power":50,"accuracy":100,"pp":25,"category":"special","effect":"none"},
    "Moonblast": {"type":"fairy","power":95,"accuracy":100,"pp":15,"category":"special","effect":"none"},
    "Dazzling Gleam": {"type":"fairy","power":80,"accuracy":100,"pp":10,"category":"special","effect":"none"},

    # Poison
    "Poison Sting": {"type":"poison","power":15,"accuracy":100,"pp":35,"category":"physical","effect":"poison"},
    "Sludge Bomb": {"type":"poison","power":90,"accuracy":100,"pp":10,"category":"special","effect":"poison"},

    # Flying
    "Gust": {"type":"flying","power":40,"accuracy":100,"pp":35,"category":"special","effect":"none"},
    "Fly": {"type":"flying","power":90,"accuracy":95,"pp":15,"category":"physical","effect":"none"},
    "Wing Attack": {"type":"flying","power":60,"accuracy":100,"pp":35,"category":"physical","effect":"none"},

    # Steel/Dragon
    "Iron Tail": {"type":"steel","power":100,"accuracy":75,"pp":15,"category":"physical","effect":"lower_def"},
    "Metal Claw": {"type":"steel","power":50,"accuracy":95,"pp":35,"category":"physical","effect":"none"},
    "Dragon Rage": {"type":"dragon","power":0,"accuracy":100,"pp":10,"category":"special","effect":"fixed_40"},
    "Dragon Claw": {"type":"dragon","power":80,"accuracy":100,"pp":15,"category":"physical","effect":"none"},

    # Fighting
    "Karate Chop": {"type":"fighting","power":50,"accuracy":100,"pp":25,"category":"physical","effect":"none"},
    "Brick Break": {"type":"fighting","power":75,"accuracy":100,"pp":15,"category":"physical","effect":"none"},

    # HM moves (also usable in battle)
    "Cut": {"type":"normal","power":50,"accuracy":95,"pp":30,"category":"physical","effect":"none"},
    "Strength": {"type":"normal","power":80,"accuracy":100,"pp":15,"category":"physical","effect":"none"},
    "Flash": {"type":"normal","power":0,"accuracy":100,"pp":20,"category":"status","effect":"lower_atk"},
}

# Default movesets per species (by pokemon_db id)
var default_movesets: Dictionary = {
    1:  ["Vine Whip", "Tackle", "Leech Seed", "Razor Leaf"],       # Bulbasaur
    2:  ["Ember", "Scratch", "Growl", "Fire Spin"],                  # Charmander
    3:  ["Water Gun", "Tackle", "Bubble", "Bite"],                   # Squirtle
    4:  ["Thunder Shock", "Quick Attack", "Thunder Wave", "Tackle"], # Pikachu
    5:  ["Rock Throw", "Tackle", "Rock Slide", "Dig"],              # Geodude
    6:  ["Lick", "Shadow Ball", "Confusion", "Bite"],               # Gastly
    7:  ["Ice Shard", "Icy Wind", "Quick Attack", "Bite"],          # Sneasel
    8:  ["Poison Sting", "Scratch", "Bite", "Tackle"],              # Nidoran
    9:  ["Confusion", "Psychic", "Flash", "Tackle"],                # Abra
    10: ["Scratch", "Dig", "Poison Sting", "Quick Attack"],         # Sandshrew
    11: ["Gust", "Quick Attack", "Wing Attack", "Tackle"],          # Pidgey
    12: ["Bite", "Dark Pulse", "Wing Attack", "Gust"],              # Murkrow
    13: ["Metal Claw", "Rock Throw", "Tackle", "Iron Tail"],        # Aron
    14: ["Dragon Rage", "Tackle", "Water Gun", "Dragon Claw"],      # Dratini
    15: ["Pound", "Dazzling Gleam", "Moonblast", "Growl"],          # Clefairy
    16: ["Flamethrower", "Bite", "Fire Spin", "Quick Attack"],      # Arcanine
    17: ["Surf", "Bite", "Dragon Rage", "Tackle"],                  # Gyarados
    18: ["Thunderbolt", "Quick Attack", "Thunder Wave", "Iron Tail"], # Raichu
    19: ["Psychic", "Shadow Ball", "Ice Beam", "Confusion"],        # Mewtwo
    20: ["Dark Pulse", "Shadow Ball", "Ice Beam", "Psychic"],       # Darkrai
}

func get_move(move_name: String) -> Dictionary:
    if move_name in moves:
        return moves[move_name].duplicate()
    return {}

func get_default_moves(species_id: int) -> Array:
    if species_id in default_movesets:
        return default_movesets[species_id].duplicate()
    return ["Tackle", "Growl", "Scratch", "Pound"]
