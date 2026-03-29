extends CanvasLayer

var alpha: float = 0.0
var fading_in: bool = false
var fading_out: bool = false
var fade_speed: float = 3.0
var on_midpoint: Callable
var _control: Control

func _ready():
	layer = 40  # above UI, below controls overlay
	_control = Control.new()
	_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_control)
	_control.connect("draw", _on_draw)

func _process(delta):
	if fading_out:
		alpha = minf(alpha + delta * fade_speed, 1.0)
		if alpha >= 1.0:
			fading_out = false
			if on_midpoint.is_valid():
				on_midpoint.call()
			# Start fading back in
			fading_in = true
		_control.queue_redraw()
	elif fading_in:
		alpha = maxf(alpha - delta * fade_speed, 0.0)
		if alpha <= 0.0:
			fading_in = false
		_control.queue_redraw()

func transition(callback: Callable = Callable()):
	on_midpoint = callback
	alpha = 0.0
	fading_out = true

func battle_transition():
	# Quick flash for battle encounters
	alpha = 0.8
	fading_in = true
	_control.queue_redraw()

func _on_draw():
	if alpha > 0.01:
		_control.draw_rect(Rect2(Vector2.ZERO, _control.get_viewport_rect().size), Color(0, 0, 0, alpha))
