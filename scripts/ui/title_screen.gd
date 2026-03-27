extends Control

signal start_game

var title_alpha: float = 0.0
var subtitle_alpha: float = 0.0
var press_alpha: float = 0.0
var timer: float = 0.0
var started: bool = false

func _ready():
    visible = true
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_process(true)

func _process(delta):
    timer += delta
    title_alpha = minf(timer / 1.5, 1.0)
    subtitle_alpha = maxf(0.0, minf((timer - 1.0) / 1.0, 1.0))
    press_alpha = maxf(0.0, sin(timer * 2.0) * 0.5 + 0.5) if timer > 2.0 else 0.0
    queue_redraw()

func _gui_input(event):
    if not visible or started:
        return
    if timer > 2.0:
        if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
            started = true
            visible = false
            start_game.emit()

func _draw():
    if not visible:
        return
    var w = get_viewport_rect().size.x
    var h = get_viewport_rect().size.y

    # Background gradient
    for i in 20:
        var y = h * i / 20.0
        var color = Color(0.05 + i * 0.005, 0.08 + i * 0.003, 0.15 + i * 0.01)
        draw_rect(Rect2(0, y, w, h / 20.0 + 1), color)

    # Decorative pokeball (large, centered)
    var cx = w / 2.0
    var cy = h * 0.38
    var r = 60.0
    # Red top
    draw_arc(Vector2(cx, cy), r, PI, TAU, 24, Color(0.9, 0.2, 0.2, title_alpha * 0.4), r)
    draw_circle(Vector2(cx, cy - r * 0.25), r * 0.6, Color(0.9, 0.2, 0.2, title_alpha * 0.3))
    # White bottom
    draw_circle(Vector2(cx, cy + r * 0.25), r * 0.6, Color(1, 1, 1, title_alpha * 0.2))
    # Center line
    draw_line(Vector2(cx - r, cy), Vector2(cx + r, cy), Color(0.2, 0.2, 0.2, title_alpha * 0.5), 3.0)
    # Button
    draw_circle(Vector2(cx, cy), 12, Color(1, 1, 1, title_alpha * 0.5))
    draw_arc(Vector2(cx, cy), 12, 0, TAU, 12, Color(0.2, 0.2, 0.2, title_alpha * 0.5), 2.0)

    # Title
    draw_string(ThemeDB.fallback_font, Vector2(cx - 80, h * 0.15), "POKEPAI",
        HORIZONTAL_ALIGNMENT_CENTER, 160, 36, Color(1, 0.85, 0.2, title_alpha))

    # Subtitle -- story hook
    var lines = [
        "The world of Pokemon awaits...",
        "A mysterious darkness threatens the land.",
        "Only YOU can stop VOIDREX and save COSMEON.",
    ]
    for i in lines.size():
        var line_alpha = maxf(0.0, minf((timer - 1.0 - i * 0.8) / 0.8, 1.0))
        draw_string(ThemeDB.fallback_font, Vector2(cx - 160, h * 0.58 + i * 22),
            lines[i], HORIZONTAL_ALIGNMENT_CENTER, 320, 13, Color(0.8, 0.85, 0.9, line_alpha))

    # Press any key
    draw_string(ThemeDB.fallback_font, Vector2(cx - 80, h * 0.85),
        "Press any key to start", HORIZONTAL_ALIGNMENT_CENTER, 160, 14,
        Color(1, 1, 1, press_alpha))
