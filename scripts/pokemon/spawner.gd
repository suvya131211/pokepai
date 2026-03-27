extends Node
class_name PokemonSpawner

const WorldGeneratorScript = preload("res://scripts/world/world_generator.gd")
const PokemonScript = preload("res://scripts/pokemon/pokemon.gd")

var step_accum: float = 0.0

func check_encounter(player):
	if not player.is_moving:
		return null

	var tile: int = player.get_current_tile()
	var habitat = WorldGeneratorScript.TILE_HABITAT.get(tile, "")
	if habitat.is_empty():
		return null

	var threshold = WorldGeneratorScript.ENCOUNTER_STEPS.get(habitat, 0.0)
	if threshold <= 0:
		return null

	if not player.consume_steps(threshold + randf() * threshold):
		return null

	# Spawn!
	var pool := PokemonDB.get_species_for_habitat(
		habitat, GameManager.time_of_day, GameManager.weather
	)
	if pool.is_empty():
		return null

	var chosen := PokemonDB.weighted_random_pick(pool)
	if chosen.is_empty():
		return null

	var level := randi_range(1, 8)
	return PokemonScript.new(chosen["id"], level)
