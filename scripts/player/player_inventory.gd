extends Node
class_name PlayerInventory

var balls: Dictionary = {"pokeball": 15, "greatball": 5, "ultraball": 2}
var berries: Dictionary = {"razz": 5, "nanab": 3, "pinap": 2}
var potions: Dictionary = {"potion": 3, "super_potion": 1, "full_restore": 0}
var medicine: Dictionary = {"antidote": 2, "awakening": 2, "paralyze_heal": 1}
var key_items: Dictionary = {"repel": 0, "escape_rope": 0}
var repel_steps: int = 0  # remaining repel steps

func _ready() -> void:
	GameManager.item_collected.connect(_on_item_collected)

func _on_item_collected(item_type: String) -> void:
	if item_type in balls:
		balls[item_type] += 1
	elif item_type in berries:
		berries[item_type] += 1

func total_balls() -> int:
	var total := 0
	for count in balls.values():
		total += count
	return total

func use_ball() -> String:
	# Use best available
	for ball_type in ["ultraball", "greatball", "pokeball"]:
		if balls.get(ball_type, 0) > 0:
			balls[ball_type] -= 1
			return ball_type
	return ""

func use_berry(berry_type: String) -> bool:
	if berries.get(berry_type, 0) > 0:
		berries[berry_type] -= 1
		return true
	return false

func use_potion(type: String, pokemon) -> int:
	if potions.get(type, 0) <= 0:
		return 0
	potions[type] -= 1
	var heal = {"potion": 20, "super_potion": 50, "full_restore": 999}.get(type, 20)
	var actual = mini(heal, pokemon.max_hp - pokemon.hp)
	pokemon.hp = mini(pokemon.max_hp, pokemon.hp + heal)
	return actual

func use_medicine(type: String, pokemon) -> bool:
	if medicine.get(type, 0) <= 0:
		return false
	medicine[type] -= 1
	pokemon.status = ""
	return true
