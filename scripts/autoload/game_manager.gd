extends Node

# Game state
enum GameState { WORLD, BATTLE, CATCH, POKEDEX, INVENTORY, TOWN_MENU, PAUSED }
var state: GameState = GameState.WORLD

# Player data
var party: Array = []  # Array of Pokemon instances
var pokedex_caught: Dictionary = {}  # id -> true
var pokedex_seen: Dictionary = {}    # id -> true

# World state
var player_chunk: Vector2i = Vector2i.ZERO
var time_of_day: String = "day"  # dawn/day/dusk/night
var weather: String = "clear"    # clear/rain/snow/storm/fog
var game_time: float = 8.0       # 0-24 hours

# Towns visited (for fast travel)
var towns_visited: Array[String] = ["Starter Town"]

# Fly menu state
var show_fly_menu: bool = false

# Badge progress
var badges_earned: int = 0

# Signals
signal state_changed(new_state: GameState)
signal pokemon_caught(pokemon)
signal item_collected(item_type: String)

func change_state(new_state: GameState) -> void:
	state = new_state
	state_changed.emit(new_state)

func add_to_pokedex(id: int, caught: bool = false) -> void:
	pokedex_seen[id] = true
	if caught:
		pokedex_caught[id] = true

func get_pokedex_count() -> Dictionary:
	return {"caught": pokedex_caught.size(), "seen": pokedex_seen.size(), "total": PokemonDB.get_total_species()}
