extends Node

# Story progress flags
var flags: Dictionary = {
    "intro_done": false,
    "starter_chosen": false,
    "first_catch": false,
    "brock_defeated": false,
    "mt_moon_shadow": false,
    "rival_battle_1": false,
    "misty_defeated": false,
    "surge_defeated": false,
    "shadow_base_cleared": false,
    "erika_defeated": false,
    "sabrina_defeated": false,
    "void_revealed": false,
    "mewtwo_found": false,
    "champion": false,
}

func set_flag(flag: String):
    flags[flag] = true

func has_flag(flag: String) -> bool:
    return flags.get(flag, false)

# Returns story dialogs to show when entering an area
func get_area_events(area_name: String) -> Array:
    var events = []

    match area_name:
        "Pallet Town":
            if not has_flag("intro_done"):
                set_flag("intro_done")
                # Prof Oak intro is handled separately

        "Route 1":
            if not has_flag("first_route_tip"):
                set_flag("first_route_tip")
                events.append({
                    "speaker": "",
                    "lines": ["The tall grass rustles... Wild Pokemon live here!", "Walk through the dark green grass to find Pokemon."]
                })

        "Pewter City":
            if not has_flag("pewter_arrival"):
                set_flag("pewter_arrival")
                events.append({
                    "speaker": "Old Man",
                    "lines": [
                        "Welcome to Pewter City, young trainer!",
                        "Brock runs the Gym here. He uses Rock-type Pokemon.",
                        "Water and Grass moves are super effective against Rock!",
                        "Visit Nurse Joy at the Pokemon Center to heal up first.",
                    ]
                })
            if not has_flag("brock_defeated"):
                events.append({
                    "speaker": "",
                    "lines": ["Brock's Gym is to the west. Face him and press E to challenge!"]
                })

        "Mt. Moon":
            if not has_flag("mt_moon_shadow"):
                set_flag("mt_moon_shadow")
                events.append({
                    "speaker": "???",
                    "lines": [
                        "...",
                        "The shadows grow deeper in this cave...",
                        "Something dark stirs beneath the mountain.",
                        "Team Shadow has been seen here, stealing rare Pokemon!",
                    ]
                })
                events.append({
                    "speaker": "Shadow Grunt",
                    "lines": [
                        "Hey! You're not supposed to be here!",
                        "Team Shadow owns this cave now!",
                        "We're harvesting Void Energy from the rare Pokemon here.",
                        "Get lost, kid!",
                    ]
                })

        "Cerulean City":
            if has_flag("brock_defeated") and not has_flag("rival_cerulean"):
                set_flag("rival_cerulean")
                events.append({
                    "speaker": "Rival",
                    "lines": [
                        "Well, look who finally made it to Cerulean!",
                        "I already beat Misty. Her Water Pokemon were tough.",
                        "But I heard something strange... Pokemon near the river are acting aggressive.",
                        "Some kind of dark energy is affecting them.",
                        "Whatever. I'm heading east. Don't fall behind!",
                    ]
                })
            if not has_flag("misty_defeated"):
                events.append({
                    "speaker": "Swimmer",
                    "lines": ["Misty's Gym is north of the Pokemon Center.", "She uses Water-types. Grass and Electric moves work well!"]
                })

        "Route 3":
            if has_flag("misty_defeated") and not has_flag("route3_warning"):
                set_flag("route3_warning")
                events.append({
                    "speaker": "Hiker",
                    "lines": [
                        "The Pokemon on this route are stronger than before.",
                        "I've noticed some of them have a strange purple aura...",
                        "Be careful out there, trainer!",
                    ]
                })

        "Vermilion City":
            if not has_flag("vermilion_arrival"):
                set_flag("vermilion_arrival")
                events.append({
                    "speaker": "Sailor",
                    "lines": [
                        "Ahoy! Welcome to Vermilion City, the port town!",
                        "Lt. Surge runs the Gym here. Ex-military, Electric specialist.",
                        "Ground-type moves are the key to beating Electric Pokemon!",
                        "Also, there's been reports of Team Shadow activity nearby...",
                    ]
                })

        "Celadon City":
            if not has_flag("celadon_arrival"):
                set_flag("celadon_arrival")
                events.append({
                    "speaker": "Police Officer",
                    "lines": [
                        "Celadon City... the biggest city in the region.",
                        "We have TWO Gyms here — Erika (Grass) and Koga (Poison).",
                        "But more importantly... Team Shadow has a hidden base somewhere in the city.",
                        "They've been abducting rare Pokemon and exposing them to Void Energy.",
                        "If you're strong enough, we could use your help stopping them.",
                    ]
                })
            if has_flag("erika_defeated") and not has_flag("shadow_base_cleared"):
                events.append({
                    "speaker": "Police Officer",
                    "lines": [
                        "We've located Team Shadow's base! It's in the south part of town.",
                        "Defeat their leader to free the captured Pokemon!",
                    ]
                })

        "Saffron City":
            if not has_flag("saffron_arrival"):
                set_flag("saffron_arrival")
                events.append({
                    "speaker": "Mysterious Figure",
                    "lines": [
                        "...",
                        "You've come far, young trainer.",
                        "The Void Energy grows stronger. DARKRAI stirs in the shadows.",
                        "But there is hope. MEWTWO, the guardian of balance, waits at the Pokemon League.",
                        "Collect all 8 badges... and you may be worthy to face what lies ahead.",
                        "Sabrina, the Psychic Gym Leader, can sense the Void. Seek her wisdom.",
                    ]
                })
            if has_flag("sabrina_defeated") and not has_flag("void_revealed"):
                set_flag("void_revealed")
                events.append({
                    "speaker": "Sabrina",
                    "lines": [
                        "I can see it now... The Void Energy originates from DARKRAI.",
                        "It feeds on fear and darkness in the hearts of Pokemon and humans alike.",
                        "MEWTWO created a barrier to contain it, but the barrier is weakening.",
                        "You must reach the Pokemon League and find MEWTWO before it's too late!",
                        "Giovanni, the final Gym Leader, guards the path. He was once part of Team Shadow...",
                        "But he left when he realized the true danger of the Void.",
                    ]
                })

        "Pokemon League":
            if not has_flag("league_arrival"):
                set_flag("league_arrival")
                events.append({
                    "speaker": "Guard",
                    "lines": [
                        "Welcome to the Pokemon League!",
                        "Only trainers with all 8 badges may enter.",
                        "The Elite Four await inside. Defeat all four, and you'll face the Champion.",
                        "Beyond the Champion... MEWTWO waits. The fate of the region rests on your shoulders.",
                    ]
                })

    return events

# Returns NPC-specific story dialog based on progress
func get_npc_story(npc_name: String, area_name: String) -> Array:
    match npc_name:
        "Nurse Joy":
            match area_name:
                "Pewter City":
                    if not has_flag("brock_defeated"):
                        return ["Your Pokemon look tired! Let me heal them.", "Brock's Pokemon are tough. Make sure you have Grass or Water moves!", "Your Pokemon are fully healed!"]
                "Cerulean City":
                    return ["Welcome! I'll heal your Pokemon.", "Have you noticed the strange energy around here? The water Pokemon seem agitated...", "Your Pokemon are fully healed!"]
                "Vermilion City":
                    return ["Let me heal your team!", "Lt. Surge's Raichu is no joke. Ground-types are your best bet.", "All healed up!"]
                "Celadon City":
                    return ["Welcome to the Pokemon Center!", "Two Gyms in one city... you'll need to be at full strength!", "Your Pokemon are fully healed!"]
    return []

# Called after gym victories
func on_gym_defeated(gym_name: String, badge: String):
    match gym_name:
        "Brock":
            set_flag("brock_defeated")
        "Misty":
            set_flag("misty_defeated")
        "Lt. Surge":
            set_flag("surge_defeated")
        "Erika":
            set_flag("erika_defeated")
        "Sabrina":
            set_flag("sabrina_defeated")

# Called after champion victory
func on_champion_defeated():
    set_flag("champion")
