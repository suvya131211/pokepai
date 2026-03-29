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
    "Ember": {"type":"fire","power":40,"accuracy":100,"pp":25,"category":"special","effect":"burn"},
    "Flamethrower": {"type":"fire","power":90,"accuracy":100,"pp":15,"category":"special","effect":"burn"},
    "Fire Spin": {"type":"fire","power":35,"accuracy":85,"pp":15,"category":"special","effect":"none"},
    "Fire Blast": {"type":"fire","power":110,"accuracy":85,"pp":5,"category":"special","effect":"burn"},
    "Scald": {"type":"water","power":80,"accuracy":100,"pp":15,"category":"special","effect":"burn"},

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
    "Thunderbolt": {"type":"electric","power":90,"accuracy":100,"pp":15,"category":"special","effect":"paralyze"},
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
    "Ice Beam": {"type":"ice","power":90,"accuracy":100,"pp":10,"category":"special","effect":"freeze"},
    "Icy Wind": {"type":"ice","power":55,"accuracy":95,"pp":15,"category":"special","effect":"lower_atk"},
    "Ice Shard": {"type":"ice","power":40,"accuracy":100,"pp":30,"category":"physical","effect":"none"},
    "Ice Punch": {"type":"ice","power":75,"accuracy":100,"pp":15,"category":"physical","effect":"freeze"},

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

    # Stat-raising moves
    "Swords Dance": {"type":"normal","power":0,"accuracy":100,"pp":20,"category":"status","effect":"raise_atk_2"},
    "Iron Defense": {"type":"steel","power":0,"accuracy":100,"pp":15,"category":"status","effect":"raise_def_2"},
    "Harden": {"type":"normal","power":0,"accuracy":100,"pp":30,"category":"status","effect":"raise_def"},
    "Meditate": {"type":"psychic","power":0,"accuracy":100,"pp":40,"category":"status","effect":"raise_atk"},

    # TM moves
    "Flare Blitz": {"type":"fire","power":120,"accuracy":100,"pp":15,"category":"physical","effect":"burn"},
    "Hydro Pump": {"type":"water","power":110,"accuracy":80,"pp":5,"category":"special","effect":"none"},
    "Solar Beam": {"type":"grass","power":120,"accuracy":100,"pp":10,"category":"special","effect":"none"},
    "Thunder": {"type":"electric","power":110,"accuracy":70,"pp":10,"category":"special","effect":"paralyze"},
    "Blizzard": {"type":"ice","power":110,"accuracy":70,"pp":5,"category":"special","effect":"freeze"},

    # HM moves (also usable in battle)
    "Cut": {"type":"normal","power":50,"accuracy":95,"pp":30,"category":"physical","effect":"none"},
    "Strength": {"type":"normal","power":80,"accuracy":100,"pp":15,"category":"physical","effect":"none"},
    "Flash": {"type":"normal","power":0,"accuracy":100,"pp":20,"category":"status","effect":"lower_atk"},

    # New moves for expanded species
    "Bug Bite": {"type":"grass","power":60,"accuracy":100,"pp":20,"category":"physical","effect":"none"},
    "Hyper Fang": {"type":"normal","power":80,"accuracy":90,"pp":15,"category":"physical","effect":"none"},
    "Peck": {"type":"flying","power":35,"accuracy":100,"pp":35,"category":"physical","effect":"none"},
    "Fury Attack": {"type":"normal","power":15,"accuracy":85,"pp":20,"category":"physical","effect":"none"},
    "Aerial Ace": {"type":"flying","power":60,"accuracy":100,"pp":20,"category":"physical","effect":"none"},
    "Wrap": {"type":"normal","power":15,"accuracy":90,"pp":20,"category":"physical","effect":"none"},
    "Acid": {"type":"poison","power":40,"accuracy":100,"pp":30,"category":"special","effect":"lower_def"},
    "Sing": {"type":"normal","power":0,"accuracy":55,"pp":15,"category":"status","effect":"sleep"},
    "Double Slap": {"type":"normal","power":15,"accuracy":85,"pp":10,"category":"physical","effect":"none"},
    "Absorb": {"type":"grass","power":20,"accuracy":100,"pp":25,"category":"special","effect":"leech"},
    "Pay Day": {"type":"normal","power":40,"accuracy":100,"pp":20,"category":"physical","effect":"none"},
    "Low Kick": {"type":"fighting","power":50,"accuracy":100,"pp":20,"category":"physical","effect":"none"},
    "Focus Energy": {"type":"normal","power":0,"accuracy":100,"pp":30,"category":"status","effect":"raise_atk"},
    "Cross Chop": {"type":"fighting","power":100,"accuracy":80,"pp":5,"category":"physical","effect":"none"},
    "Headbutt": {"type":"normal","power":70,"accuracy":100,"pp":15,"category":"physical","effect":"none"},
    "Sonic Boom": {"type":"normal","power":0,"accuracy":90,"pp":20,"category":"special","effect":"fixed_40"},
    "Bone Club": {"type":"ground","power":65,"accuracy":85,"pp":20,"category":"physical","effect":"none"},
    "Bonemerang": {"type":"ground","power":50,"accuracy":90,"pp":10,"category":"physical","effect":"none"},
    "Horn Attack": {"type":"normal","power":65,"accuracy":100,"pp":25,"category":"physical","effect":"none"},
    "Stomp": {"type":"normal","power":65,"accuracy":100,"pp":20,"category":"physical","effect":"none"},
    "Twister": {"type":"dragon","power":40,"accuracy":100,"pp":20,"category":"special","effect":"none"},
    "Splash": {"type":"normal","power":0,"accuracy":100,"pp":40,"category":"status","effect":"none"},
    "Flail": {"type":"normal","power":0,"accuracy":100,"pp":15,"category":"physical","effect":"none"},
    "Swift": {"type":"normal","power":60,"accuracy":100,"pp":20,"category":"special","effect":"none"},
    "Take Down": {"type":"normal","power":90,"accuracy":85,"pp":20,"category":"physical","effect":"none"},
    "Confuse Ray": {"type":"ghost","power":0,"accuracy":100,"pp":10,"category":"status","effect":"none"},
    "Body Slam": {"type":"normal","power":85,"accuracy":100,"pp":15,"category":"physical","effect":"paralyze"},
    "Disable": {"type":"normal","power":0,"accuracy":100,"pp":20,"category":"status","effect":"none"},
    "Fury Swipes": {"type":"normal","power":18,"accuracy":80,"pp":15,"category":"physical","effect":"none"},
    "String Shot": {"type":"grass","power":0,"accuracy":95,"pp":40,"category":"status","effect":"lower_atk"},
    "Rapid Spin": {"type":"normal","power":50,"accuracy":100,"pp":40,"category":"physical","effect":"none"},
    "Slash": {"type":"normal","power":70,"accuracy":100,"pp":20,"category":"physical","effect":"none"},
    "Supersonic": {"type":"normal","power":0,"accuracy":55,"pp":20,"category":"status","effect":"none"},
}

# Default movesets per species (by pokemon_db id)
var default_movesets: Dictionary = {
    1:  ["Vine Whip", "Tackle", "Leech Seed", "Razor Leaf"],       # Bulbasaur
    2:  ["Ember", "Scratch", "Growl", "Fire Spin"],                  # Charmander
    3:  ["Water Gun", "Tackle", "Surf", "Bite"],                     # Squirtle — knows Surf!
    4:  ["Thunder Shock", "Quick Attack", "Thunder Wave", "Tackle"], # Pikachu
    5:  ["Rock Throw", "Tackle", "Rock Slide", "Dig"],              # Geodude
    6:  ["Lick", "Shadow Ball", "Confusion", "Bite"],               # Gastly
    7:  ["Ice Shard", "Icy Wind", "Quick Attack", "Bite"],          # Sneasel
    8:  ["Poison Sting", "Scratch", "Bite", "Tackle"],              # Nidoran
    9:  ["Confusion", "Psychic", "Flash", "Tackle"],                # Abra
    10: ["Scratch", "Dig", "Poison Sting", "Quick Attack"],         # Sandshrew
    11: ["Gust", "Quick Attack", "Wing Attack", "Fly"],             # Pidgey — knows Fly!
    12: ["Bite", "Dark Pulse", "Wing Attack", "Gust"],              # Murkrow
    13: ["Metal Claw", "Rock Throw", "Tackle", "Iron Tail"],        # Aron
    14: ["Dragon Rage", "Tackle", "Water Gun", "Dragon Claw"],      # Dratini
    15: ["Pound", "Dazzling Gleam", "Moonblast", "Growl"],          # Clefairy
    16: ["Flamethrower", "Bite", "Fire Spin", "Quick Attack"],      # Arcanine
    17: ["Surf", "Bite", "Dragon Rage", "Tackle"],                  # Gyarados
    18: ["Thunderbolt", "Quick Attack", "Thunder Wave", "Iron Tail"], # Raichu
    19: ["Psychic", "Shadow Ball", "Ice Beam", "Confusion"],        # Mewtwo
    20: ["Dark Pulse", "Shadow Ball", "Ice Beam", "Psychic"],       # Darkrai
    21: ["Vine Whip", "Razor Leaf", "Leech Seed", "Tackle"],        # Ivysaur
    22: ["Solar Beam", "Razor Leaf", "Leech Seed", "Sludge Bomb"],  # Venusaur
    23: ["Ember", "Slash", "Dragon Rage", "Tackle"],                # Charmeleon
    24: ["Flamethrower", "Dragon Rage", "Slash", "Fire Blast"],     # Charizard
    25: ["Water Gun", "Bite", "Rapid Spin", "Tackle"],              # Wartortle
    26: ["Hydro Pump", "Ice Beam", "Bite", "Surf"],                 # Blastoise
    27: ["Tackle", "String Shot", "Bug Bite", "Tackle"],            # Caterpie
    28: ["Poison Sting", "String Shot", "Bug Bite", "Tackle"],      # Weedle
    29: ["Tackle", "Quick Attack", "Bite", "Hyper Fang"],           # Rattata
    30: ["Peck", "Fury Attack", "Quick Attack", "Aerial Ace"],      # Spearow
    31: ["Bite", "Poison Sting", "Wrap", "Acid"],                   # Ekans
    32: ["Ember", "Quick Attack", "Flamethrower", "Confuse Ray"],   # Vulpix
    33: ["Sing", "Pound", "Double Slap", "Body Slam"],              # Jigglypuff
    34: ["Bite", "Supersonic", "Poison Sting", "Wing Attack"],      # Zubat
    35: ["Absorb", "Acid", "Sleep Powder", "Razor Leaf"],           # Oddish
    36: ["Scratch", "Bite", "Pay Day", "Slash"],                    # Meowth
    37: ["Water Gun", "Confusion", "Scratch", "Disable"],           # Psyduck
    38: ["Low Kick", "Karate Chop", "Fury Swipes", "Cross Chop"],   # Mankey
    39: ["Ember", "Bite", "Flamethrower", "Take Down"],             # Growlithe
    40: ["Low Kick", "Karate Chop", "Focus Energy", "Cross Chop"],  # Machop
    41: ["Water Gun", "Confusion", "Headbutt", "Psychic"],          # Slowpoke
    42: ["Thunder Shock", "Sonic Boom", "Thunder Wave", "Thunderbolt"],  # Magnemite
    43: ["Rock Throw", "Tackle", "Rock Slide", "Iron Tail"],        # Onix
    44: ["Bone Club", "Headbutt", "Bonemerang", "Earthquake"],      # Cubone
    45: ["Horn Attack", "Rock Throw", "Stomp", "Earthquake"],       # Rhyhorn
    46: ["Water Gun", "Bubble", "Twister", "Hydro Pump"],           # Horsea
    47: ["Quick Attack", "Slash", "Wing Attack", "Swords Dance"],   # Scyther
    48: ["Splash", "Tackle", "Flail", "Tackle"],                    # Magikarp
    49: ["Ice Beam", "Surf", "Body Slam", "Psychic"],               # Lapras
    50: ["Tackle", "Quick Attack", "Bite", "Swift"],                # Eevee
}

func get_move(move_name: String) -> Dictionary:
    if move_name in moves:
        return moves[move_name].duplicate()
    return {}

func get_default_moves(species_id: int) -> Array:
    if species_id in default_movesets:
        return default_movesets[species_id].duplicate()
    return ["Tackle", "Growl", "Scratch", "Pound"]
