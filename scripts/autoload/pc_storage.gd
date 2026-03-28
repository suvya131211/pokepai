extends Node

var boxes: Array = []  # Array of Arrays, each box holds up to 30 Pokemon
const NUM_BOXES = 8
const BOX_SIZE = 30

func _ready():
	for i in NUM_BOXES:
		boxes.append([])

func deposit(pokemon) -> bool:
	# Find first box with space
	for box in boxes:
		if box.size() < BOX_SIZE:
			box.append(pokemon)
			return true
	return false  # all full

func withdraw(box_index: int, pokemon_index: int):
	if box_index < boxes.size() and pokemon_index < boxes[box_index].size():
		if GameManager.party.size() < 6:
			var pkmn = boxes[box_index][pokemon_index]
			boxes[box_index].remove_at(pokemon_index)
			GameManager.party.append(pkmn)
			return pkmn
	return null

func get_total_stored() -> int:
	var count = 0
	for box in boxes:
		count += box.size()
	return count

func get_box(index: int) -> Array:
	if index < boxes.size():
		return boxes[index]
	return []
