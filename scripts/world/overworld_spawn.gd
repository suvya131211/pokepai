extends Node2D
class_name OverworldPokemon

var pokemon_data: Dictionary  # species data from PokemonDB
var level: int = 1
var despawn_timer: float = 60.0  # disappears after 60 seconds
var bob_offset: float = 0.0
var sprite_texture: Texture2D = null

func setup(species: Dictionary, lvl: int) -> void:
	pokemon_data = species
	level = lvl
	bob_offset = randf() * TAU
	# Load sprite
	sprite_texture = PokemonDB.get_sprite_texture(species["id"])

func _process(delta: float) -> void:
	despawn_timer -= delta
	if despawn_timer <= 0:
		queue_free()
	bob_offset += delta * 2.0
	queue_redraw()

func _draw() -> void:
	var bob_y = sin(bob_offset) * 2.0
	if sprite_texture:
		# Draw the sprite scaled down to 24x24 (original is 96x96)
		var src_rect = Rect2(Vector2.ZERO, sprite_texture.get_size())
		var dst_rect = Rect2(-12, -12 + bob_y, 24, 24)
		draw_texture_rect(sprite_texture, dst_rect, false)
	else:
		# Fallback colored circle
		draw_circle(Vector2(0, bob_y), 8, pokemon_data.get("color", Color.WHITE))

	# Shadow
	_draw_shadow(Vector2(0, 10), Vector2(8, 3), Color(0, 0, 0, 0.3))

func _draw_shadow(center: Vector2, sz: Vector2, color: Color) -> void:
	var points: PackedVector2Array = []
	for i in 16:
		var angle = (float(i) / 16.0) * TAU
		points.append(center + Vector2(cos(angle) * sz.x, sin(angle) * sz.y))
	draw_colored_polygon(points, color)
