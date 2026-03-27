extends CanvasLayer
class_name GameHUD

var hotbar: Control
var minimap: Control
var top_bar: Control

func _ready() -> void:
	layer = 10
	# Will be instantiated from scene — build UI in code for now
	_build_ui()

func _build_ui() -> void:
	# Top info bar
	top_bar = Control.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size = Vector2(0, 32)
	add_child(top_bar)

	# Hotbar (bottom center — like Minecraft)
	hotbar = preload("res://scripts/ui/hotbar.gd").new()
	add_child(hotbar)

	# Minimap (top right corner)
	minimap = preload("res://scripts/ui/minimap.gd").new()
	add_child(minimap)

func _process(_delta: float) -> void:
	top_bar.queue_redraw()

func _top_bar_draw() -> void:
	pass  # drawn by top_bar's _draw override — see hud scene
