extends Node

var PokemonScript = preload("res://scripts/pokemon/pokemon.gd")

# Track defeated trainers so they don't re-battle
var defeated_trainers: Dictionary = {}  # "area:npc_name" -> true
var defeated_gyms: Array = []  # list of badge names
var defeated_elite4: Array = []  # list of elite4 names
var rival_battles_done: Array = []  # [0, 1, 2] indices

signal npc_battle_start(npc_data: Dictionary)
signal npc_dialog_start(speaker: String, messages: Array)
signal heal_pokemon
signal open_shop
signal gym_battle_start(gym_data: Dictionary)

func interact_with_npc(npc: Dictionary, area_name: String) -> void:
    var npc_key = area_name + ":" + npc.get("name", "")

    match npc.get("type", "npc"):
        "npc":
            npc_dialog_start.emit(npc.get("name", ""), npc.get("dialog", ["..."]))

        "professor":
            npc_dialog_start.emit(npc.get("name", "Prof. Oak"), npc.get("dialog", ["Welcome!"]))

        "nurse":
            heal_pokemon.emit()
            npc_dialog_start.emit("Nurse Joy", ["Your Pokemon have been fully healed!", "Come back anytime!"])

        "shop":
            npc_dialog_start.emit("Shopkeeper", ["Welcome! Here are some items."])
            open_shop.emit()

        "trainer":
            if npc_key in defeated_trainers:
                npc_dialog_start.emit(npc.get("name", ""), ["You beat me already... I need to train more."])
            else:
                # Only emit battle — main.gd will show dialog then start battle
                var team = _build_team(npc.get("team", []))
                npc_battle_start.emit({"name": npc.get("name", "Trainer"), "team": team, "key": npc_key, "dialog": npc.get("dialog", ["Let's battle!"])})

        "rival":
            var battle_idx = npc.get("battle_index", 0)
            if battle_idx in rival_battles_done:
                npc_dialog_start.emit("Rival", ["Next time I'll definitely win!"])
            else:
                var team = _build_team(npc.get("team", []))
                npc_battle_start.emit({"name": "Rival", "team": team, "key": npc_key, "is_rival": true, "battle_index": battle_idx, "dialog": npc.get("dialog", ["Let's go!"])})

        "rocket":
            if npc_key in defeated_trainers:
                npc_dialog_start.emit(npc.get("name", ""), ["Team Rocket... blasting off..."])
            else:
                var team = _build_team(npc.get("team", []))
                npc_battle_start.emit({"name": npc.get("name", "Rocket Grunt"), "team": team, "key": npc_key, "dialog": npc.get("dialog", ["Prepare for trouble!"])})

        "gym_leader":
            # Handled separately via gym system
            pass

        "elite4":
            if npc.get("name", "") in defeated_elite4:
                npc_dialog_start.emit(npc.get("name", ""), ["You've proven your strength..."])
            else:
                npc_dialog_start.emit(npc.get("name", ""), npc.get("dialog", []))
                var team = _build_team(npc.get("team", []))
                npc_battle_start.emit({"name": npc.get("name", ""), "team": team, "key": npc_key, "is_elite4": true})

        "champion":
            npc_dialog_start.emit("Champion", npc.get("dialog", []))
            var team = _build_team(npc.get("team", []))
            npc_battle_start.emit({"name": "Champion", "team": team, "key": npc_key, "is_champion": true})

func mark_defeated(key: String) -> void:
    defeated_trainers[key] = true

func mark_gym_defeated(badge: String) -> void:
    if badge not in defeated_gyms:
        defeated_gyms.append(badge)

func mark_elite4_defeated(name: String) -> void:
    if name not in defeated_elite4:
        defeated_elite4.append(name)

func mark_rival_defeated(index: int) -> void:
    if index not in rival_battles_done:
        rival_battles_done.append(index)

func get_badge_count() -> int:
    return defeated_gyms.size()

func _build_team(team_data: Array) -> Array:
    var team = []
    for entry in team_data:
        var pkmn = PokemonScript.new(entry["id"], entry["level"])
        team.append(pkmn)
    return team
