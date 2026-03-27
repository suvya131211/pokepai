extends Control

var expanded: bool = false
var tab_hovered: bool = false

func _ready():
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta):
    if Input.is_action_just_pressed("toggle_map"):  # M key
        expanded = !expanded
    queue_redraw()

func _draw():
    if GameManager.state != GameManager.GameState.WORLD:
        return

    var vp = get_viewport_rect().size
    var panel_w = 200.0
    var panel_h = 320.0
    var tab_w = 24.0
    var tab_h = 80.0

    if expanded:
        # Panel background
        var px = vp.x - panel_w
        var py = 40.0
        draw_rect(Rect2(px, py, panel_w, panel_h), Color(0.04, 0.06, 0.12, 0.9))
        draw_rect(Rect2(px, py, panel_w, panel_h), Color("#4fc3f7"), false, 1.5)

        # Title
        draw_string(ThemeDB.fallback_font, Vector2(px + 10, py + 20), "CONTROLS", HORIZONTAL_ALIGNMENT_LEFT, panel_w - 20, 14, Color("#4fc3f7"))

        # Instructions
        var lines = [
            "[WASD] Move",
            "[Shift] Sprint",
            "[P] Pokedex",
            "[I] Inventory",
            "[M] Toggle this panel",
            "[ESC] Pause",
            "",
            "BATTLE:",
            "Click FIGHT to attack",
            "Click CATCH to throw ball",
            "Click BERRY to use berry",
            "Click RUN to flee",
            "",
            "CATCHING:",
            "Wait for small circle",
            "Click to throw Pokeball",
            "Smaller circle = better catch!",
            "",
            "GOAL:",
            "Catch all 20 Pokemon!",
            "Defeat DARKRAI to win!",
        ]
        var ly = py + 40
        for line in lines:
            if line == "":
                ly += 6
                continue
            var col = Color("#4fc3f7") if line.begins_with("[") or line.ends_with(":") else Color("#bbb")
            if line == "Defeat DARKRAI to win!":
                col = Color("#ffd700")
            draw_string(ThemeDB.fallback_font, Vector2(px + 12, ly), line, HORIZONTAL_ALIGNMENT_LEFT, panel_w - 24, 11, col)
            ly += 14

        # Close hint
        draw_string(ThemeDB.fallback_font, Vector2(px + 10, py + panel_h - 10), "Press [M] to close", HORIZONTAL_ALIGNMENT_LEFT, panel_w - 20, 10, Color("#666"))

    # Tab on the right edge (always visible)
    var tab_x = vp.x - tab_w
    var tab_y = 80.0
    draw_rect(Rect2(tab_x, tab_y, tab_w, tab_h), Color(0.04, 0.06, 0.12, 0.8))
    draw_rect(Rect2(tab_x, tab_y, tab_w, tab_h), Color("#4fc3f7"), false, 1.0)
    # "?" icon
    draw_string(ThemeDB.fallback_font, Vector2(tab_x + 6, tab_y + 30), "?", HORIZONTAL_ALIGNMENT_LEFT, 16, 18, Color("#4fc3f7"))
    draw_string(ThemeDB.fallback_font, Vector2(tab_x + 3, tab_y + 50), "[M]", HORIZONTAL_ALIGNMENT_LEFT, 20, 9, Color("#888"))
