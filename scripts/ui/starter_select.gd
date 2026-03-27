extends Control

signal starter_chosen(species_id: int)

var selected: int = -1
var hover: int = -1

const STARTERS = [
    {"id": 1, "name": "Bulbasaur", "type": "Grass/Poison", "desc": "Easy mode. Strong early game."},
    {"id": 2, "name": "Charmander", "type": "Fire", "desc": "Hard mode. Powerful late game."},
    {"id": 3, "name": "Squirtle", "type": "Water", "desc": "Balanced. Good all-around."},
]

func _ready():
    visible = false
    mouse_filter = Control.MOUSE_FILTER_STOP

func show_selection():
    visible = true
    selected = -1
    GameManager.change_state(GameManager.GameState.PAUSED)
    queue_redraw()

func _gui_input(event):
    if not visible:
        return
    if event is InputEventMouseMotion:
        hover = _get_slot(event.position)
        queue_redraw()
    if event is InputEventMouseButton and event.pressed:
        var slot = _get_slot(event.position)
        if slot >= 0 and slot < 3:
            selected = slot
            visible = false
            starter_chosen.emit(STARTERS[slot]["id"])

func _get_slot(pos: Vector2) -> int:
    var w = get_viewport_rect().size.x
    var h = get_viewport_rect().size.y
    var card_w = w * 0.25
    var card_h = h * 0.45
    var start_x = (w - card_w * 3 - 40) / 2
    var card_y = h * 0.35

    for i in 3:
        var cx = start_x + i * (card_w + 20)
        if Rect2(cx, card_y, card_w, card_h).has_point(pos):
            return i
    return -1

func _draw():
    if not visible:
        return
    var w = get_viewport_rect().size.x
    var h = get_viewport_rect().size.y

    # Background
    draw_rect(Rect2(0, 0, w, h), Color(0.04, 0.06, 0.12, 0.95))

    # Title
    draw_string(ThemeDB.fallback_font, Vector2(w/2 - 100, h * 0.12), "Choose Your Partner!", HORIZONTAL_ALIGNMENT_CENTER, 200, 22, Color("#ffd700"))
    draw_string(ThemeDB.fallback_font, Vector2(w/2 - 120, h * 0.2), "Prof. Oak: Pick one of these three Pokemon!", HORIZONTAL_ALIGNMENT_CENTER, 240, 12, Color("#aaa"))

    var card_w = w * 0.25
    var card_h = h * 0.45
    var start_x = (w - card_w * 3 - 40) / 2
    var card_y = h * 0.35

    for i in 3:
        var s = STARTERS[i]
        var cx = start_x + i * (card_w + 20)
        var is_hover = (hover == i)

        # Card bg
        var bg_color = Color(0.12, 0.16, 0.25) if not is_hover else Color(0.18, 0.22, 0.35)
        draw_rect(Rect2(cx, card_y, card_w, card_h), bg_color)
        var border_color = Color("#4fc3f7") if not is_hover else Color("#ffd700")
        draw_rect(Rect2(cx, card_y, card_w, card_h), border_color, false, 2.0 if not is_hover else 3.0)

        # Sprite
        var tex = PokemonDB.get_sprite_texture(s["id"])
        if tex:
            var spr_size = card_w * 0.6
            draw_texture_rect(tex, Rect2(cx + (card_w - spr_size)/2, card_y + 15, spr_size, spr_size), false)

        # Name
        draw_string(ThemeDB.fallback_font, Vector2(cx + 10, card_y + card_h * 0.6), s["name"], HORIZONTAL_ALIGNMENT_LEFT, card_w - 20, 16, Color.WHITE)

        # Type
        draw_string(ThemeDB.fallback_font, Vector2(cx + 10, card_y + card_h * 0.7), s["type"], HORIZONTAL_ALIGNMENT_LEFT, card_w - 20, 12, Color("#4fc3f7"))

        # Description
        draw_string(ThemeDB.fallback_font, Vector2(cx + 10, card_y + card_h * 0.82), s["desc"], HORIZONTAL_ALIGNMENT_LEFT, card_w - 20, 10, Color("#888"))

    # Bottom hint
    draw_string(ThemeDB.fallback_font, Vector2(w/2 - 60, h * 0.9), "Click to choose", HORIZONTAL_ALIGNMENT_CENTER, 120, 13, Color(1, 1, 1, sin(Time.get_ticks_msec() * 0.003) * 0.4 + 0.6))

func _process(_delta):
    if visible:
        queue_redraw()
