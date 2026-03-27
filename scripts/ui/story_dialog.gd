extends Control

var messages: Array[String] = []
var current_index: int = 0
var char_timer: float = 0.0
var chars_shown: int = 0
var speaker: String = ""
var on_complete: Callable

func _ready():
    visible = false
    mouse_filter = Control.MOUSE_FILTER_STOP

func show_dialog(speaker_name: String, msgs: Array, callback: Callable = Callable()):
    speaker = speaker_name
    messages = []
    for m in msgs:
        messages.append(str(m))
    current_index = 0
    chars_shown = 0
    char_timer = 0.0
    on_complete = callback
    visible = true
    GameManager.change_state(GameManager.GameState.PAUSED)
    queue_redraw()

func _process(delta):
    if not visible:
        return
    if current_index < messages.size():
        char_timer += delta * 40  # chars per second
        chars_shown = int(char_timer)
    queue_redraw()

func _unhandled_input(event):
    if not visible:
        return
    if event is InputEventKey and event.pressed or event is InputEventMouseButton and event.pressed:
        get_viewport().set_input_as_handled()
        if chars_shown < messages[current_index].length():
            # Skip to full message
            chars_shown = messages[current_index].length()
            char_timer = chars_shown
        else:
            # Next message
            current_index += 1
            chars_shown = 0
            char_timer = 0.0
            if current_index >= messages.size():
                visible = false
                GameManager.change_state(GameManager.GameState.WORLD)
                if on_complete.is_valid():
                    on_complete.call()

func _draw():
    if not visible or current_index >= messages.size():
        return
    var w = get_viewport_rect().size.x
    var h = get_viewport_rect().size.y

    # Dialog box at bottom
    var box_h = 90.0
    var box_y = h - box_h - 10

    # Box background
    draw_rect(Rect2(10, box_y, w - 20, box_h), Color(0.06, 0.1, 0.16, 0.95))
    draw_rect(Rect2(10, box_y, w - 20, box_h), Color(0.31, 0.76, 0.97), false, 2.0)

    # Speaker name tag
    if speaker:
        draw_rect(Rect2(20, box_y - 22, 100, 24), Color(0.06, 0.1, 0.16, 0.95))
        draw_rect(Rect2(20, box_y - 22, 100, 24), Color(0.31, 0.76, 0.97), false, 1.5)
        draw_string(ThemeDB.fallback_font, Vector2(28, box_y - 4), speaker,
            HORIZONTAL_ALIGNMENT_LEFT, 84, 13, Color(0.31, 0.76, 0.97))

    # Message text (typewriter)
    var text = messages[current_index].substr(0, chars_shown)
    draw_string(ThemeDB.fallback_font, Vector2(24, box_y + 24), text,
        HORIZONTAL_ALIGNMENT_LEFT, w - 48, 13, Color(0.88, 0.9, 0.92))

    # Continue indicator
    if chars_shown >= messages[current_index].length():
        var blink = sin(Time.get_ticks_msec() * 0.005) * 0.5 + 0.5
        draw_string(ThemeDB.fallback_font, Vector2(w - 50, box_y + box_h - 12),
            ">>>", HORIZONTAL_ALIGNMENT_LEFT, 40, 11, Color(1, 1, 1, blink))
