extends Node
class_name PokemonSpawner

var step_accum: float = 0.0

func check_encounter(player: PlayerCharacter) -> Pokemon:
	if not player.is_moving:
		return null

	var tile := player.get_current_tile()
	var habitat: String = WorldGenerator.TILE_HABITAT.get(tile, "")
	if habitat.is_empty():
		return null

	var threshold: float = WorldGenerator.ENCOUNTER_STEPS.get(habitat, 0.0)
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
	return Pokemon.new(chosen["id"], level)
