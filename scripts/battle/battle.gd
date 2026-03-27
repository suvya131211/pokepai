extends Control

enum Phase { INTRO, MENU, PLAYER_ATK, WILD_ATK, CATCH_AIM, CATCH_THROW, CATCH_SHAKE, CATCH_BREAK, CATCH_RESULT, END }

var player_pokemon = null
var wild_pokemon = null
var inventory = null
var player_sprite: Texture2D = null
var wild_sprite: Texture2D = null

var phase = Phase.INTRO
var message: String = ""
var message_timer: float = 0.0
var result: String = ""
var leveled_up: bool = false

# Attack animation
var wild_shake: float = 0.0
var player_shake: float = 0.0
var wild_flash: float = 0.0
var player_flash: float = 0.0
var intro_timer: float = 2.0

# Catch state
var circle_radius: float = 80.0
var circle_min: float = 20.0
var circle_max: float = 80.0
var circle_speed: float = 40.0
var circle_shrinking: bool = true
var ball_pos: Vector2
var ball_vel: Vector2
var ball_active: bool = false
var shake_count: int = 0
var shake_timer: float = 0.0
var result_timer: float = 0.0
var throw_rating: String = ""
var throw_bonus: float = 1.0

signal battle_ended(result_str: String, wild)

func _ready():
    mouse_filter = Control.MOUSE_FILTER_STOP

func start(party: Array, wild, inv = null):
    player_pokemon = party[0] if party.size() > 0 else null
    wild_pokemon = wild
    inventory = inv
    wild_sprite = PokemonDB.get_sprite_texture(wild.id)
    if player_pokemon:
        player_sprite = PokemonDB.get_sprite_texture(player_pokemon.id)
    phase = Phase.INTRO
    message = "A wild %s appeared!" % wild.pokemon_name
    intro_timer = 2.0
    message_timer = 0.0
    result = ""
    leveled_up = false
    throw_rating = ""
    visible = true

func set_inventory(inv):
    inventory = inv

func _process(delta):
    if not visible:
        return

    # Animation decay
    wild_shake = move_toward(wild_shake, 0.0, delta * 12.0)
    player_shake = move_toward(player_shake, 0.0, delta * 12.0)
    wild_flash = move_toward(wild_flash, 0.0, delta * 3.0)
    player_flash = move_toward(player_flash, 0.0, delta * 3.0)

    match phase:
        Phase.INTRO:
            intro_timer -= delta
            if intro_timer <= 0:
                phase = Phase.MENU

        Phase.PLAYER_ATK:
            if message_timer > 0:
                message_timer -= delta
                if message_timer <= 0:
                    if not wild_pokemon.is_alive():
                        phase = Phase.END
                        result = "defeated"
                        var xp = wild_pokemon.level * 10
                        leveled_up = player_pokemon.gain_xp(xp)
                        message = "%s fainted! +%d XP" % [wild_pokemon.pokemon_name, xp]
                        message_timer = 2.0
                    else:
                        _wild_attack()

        Phase.WILD_ATK:
            if message_timer > 0:
                message_timer -= delta
                if message_timer <= 0:
                    if not player_pokemon.is_alive():
                        phase = Phase.END
                        result = "fled"
                        message = "%s fainted! You blacked out..." % player_pokemon.pokemon_name
                        message_timer = 2.0
                    else:
                        phase = Phase.MENU

        Phase.CATCH_AIM:
            if circle_shrinking:
                circle_radius -= circle_speed * delta
                if circle_radius <= circle_min:
                    circle_shrinking = false
            else:
                circle_radius += circle_speed * delta
                if circle_radius >= circle_max:
                    circle_shrinking = true

        Phase.CATCH_THROW:
            ball_pos += ball_vel * delta
            ball_vel.y += 80.0 * delta
            var target = Vector2(size.x * 0.7, size.y * 0.28)
            if ball_pos.distance_to(target) < 40:
                ball_active = false
                _evaluate_catch()
            elif ball_pos.y > size.y + 20 or ball_pos.x < -20 or ball_pos.x > size.x + 20:
                ball_active = false
                phase = Phase.CATCH_AIM
                message = "Missed! Try again."

        Phase.CATCH_SHAKE:
            shake_timer -= delta
            if shake_timer <= 0:
                shake_count += 1
                if shake_count >= 3:
                    phase = Phase.END
                    result = "caught"
                    message = "Gotcha! %s was caught!" % wild_pokemon.pokemon_name
                    message_timer = 2.5
                else:
                    shake_timer = 0.5
                    message = "...%d..." % shake_count

        Phase.CATCH_BREAK:
            shake_timer -= delta
            if shake_timer <= 0:
                phase = Phase.MENU
                shake_count = 0
                message = "%s broke free!" % wild_pokemon.pokemon_name

        Phase.END:
            if message_timer > 0:
                message_timer -= delta
                if message_timer <= 0:
                    battle_ended.emit(result, wild_pokemon)
                    visible = false

    queue_redraw()

func _gui_input(event):
    if not visible:
        return
    if not (event is InputEventMouseButton and event.pressed):
        return
    var pos = event.position
    var w = size.x
    var h = size.y

    if phase == Phase.MENU:
        var btn_w = w * 0.22
        var btn_h = 40.0
        var btn_y = h - 130
        var btns = [
            {"label": "FIGHT", "x": w * 0.02, "action": "fight"},
            {"label": "CATCH", "x": w * 0.26, "action": "catch"},
            {"label": "BERRY", "x": w * 0.50, "action": "berry"},
            {"label": "RUN",   "x": w * 0.74, "action": "flee"},
        ]
        for btn in btns:
            if Rect2(btn["x"], btn_y, btn_w, btn_h).has_point(pos):
                match btn["action"]:
                    "fight": _player_attack()
                    "catch": _start_catch()
                    "berry": _use_berry()
                    "flee": _flee()

    elif phase == Phase.CATCH_AIM:
        # Check back button first
        var back_rect = Rect2(w - 110, h - 55, 90, 40)
        if back_rect.has_point(pos):
            phase = Phase.MENU
            message = "What will you do?"
        else:
            _throw_ball(pos)

func _player_attack():
    phase = Phase.PLAYER_ATK
    var dmg_data = player_pokemon.calc_damage(wild_pokemon)
    wild_pokemon.hp = maxi(0, wild_pokemon.hp - dmg_data["damage"])
    wild_shake = 1.0
    wild_flash = 1.0
    var eff_text = dmg_data["text"]
    message = "%s attacks! %d dmg. %s" % [player_pokemon.pokemon_name, dmg_data["damage"], eff_text]
    message_timer = 1.5

func _wild_attack():
    phase = Phase.WILD_ATK
    if wild_pokemon.status == "sleep":
        message = "%s is asleep..." % wild_pokemon.pokemon_name
        message_timer = 1.2
        return
    var dmg_data = wild_pokemon.calc_damage(player_pokemon)
    player_pokemon.hp = maxi(0, player_pokemon.hp - dmg_data["damage"])
    player_shake = 1.0
    player_flash = 1.0
    message = "%s attacks! %d dmg." % [wild_pokemon.pokemon_name, dmg_data["damage"]]
    message_timer = 1.5

func _start_catch():
    if not inventory or inventory.total_balls() <= 0:
        message = "No Pokeballs!"
        return
    phase = Phase.CATCH_AIM
    circle_radius = circle_max
    circle_shrinking = true
    throw_rating = ""
    message = "Click to throw Pokeball!"

func _throw_ball(click_pos: Vector2):
    inventory.use_ball()
    var start = Vector2(size.x / 2, size.y - 60)
    ball_pos = start
    var dir = (click_pos - start).normalized()
    ball_vel = dir * 350.0 + Vector2(0, -100)
    ball_active = true
    phase = Phase.CATCH_THROW

func _evaluate_catch():
    var ratio = (circle_radius - circle_min) / (circle_max - circle_min)
    if ratio < 0.25:
        throw_rating = "Excellent!"
        throw_bonus = 1.75
    elif ratio < 0.5:
        throw_rating = "Great!"
        throw_bonus = 1.5
    elif ratio < 0.75:
        throw_rating = "Nice!"
        throw_bonus = 1.2
    else:
        throw_rating = ""
        throw_bonus = 1.0

    # Lower HP = higher catch rate
    var base_rate = wild_pokemon.get_catch_rate()
    var final_rate = minf(0.95, base_rate * throw_bonus)

    if randf() < final_rate:
        phase = Phase.CATCH_SHAKE
        shake_count = 0
        shake_timer = 0.6
        message = throw_rating + " ..." if throw_rating else "..."
    else:
        phase = Phase.CATCH_BREAK
        shake_timer = 1.2
        circle_radius = circle_max
        message = "%s broke free!" % wild_pokemon.pokemon_name

func _use_berry():
    if inventory and inventory.use_berry("nanab"):
        wild_pokemon.status = "sleep"
        message = "Used Nanab Berry! %s fell asleep!" % wild_pokemon.pokemon_name
    else:
        message = "No berries!"

func _flee():
    phase = Phase.END
    result = "fled"
    message = "Got away safely!"
    message_timer = 1.0

func _draw():
    if not visible:
        return
    var w = size.x
    var h = size.y

    # Background
    draw_rect(Rect2(0, 0, w, h), Color(0.04, 0.06, 0.1))
    # Arena gradient
    for i in 8:
        draw_rect(Rect2(0, h * 0.2 + i * h * 0.06, w, h * 0.06), Color(0.06 + i*0.008, 0.1 + i*0.005, 0.18 + i*0.01, 0.5))

    # Ground platforms
    draw_rect(Rect2(w * 0.05, h * 0.6, w * 0.35, 8), Color(0.3, 0.25, 0.2, 0.6))
    draw_rect(Rect2(w * 0.55, h * 0.42, w * 0.35, 8), Color(0.3, 0.25, 0.2, 0.6))

    # === PLAYER POKEMON (bottom left) ===
    var px = w * 0.22
    var py = h * 0.52
    if player_sprite and player_pokemon:
        var shake_x = sin(player_shake * 20.0) * player_shake * 12.0
        var spr_size = minf(w, h) * 0.22
        if player_flash > 0:
            draw_circle(Vector2(px + shake_x, py), spr_size * 0.5, Color(1, 0.3, 0.3, player_flash * 0.3))
        draw_texture_rect(player_sprite, Rect2(px - spr_size/2 + shake_x, py - spr_size/2, spr_size, spr_size), false)

    # Player HP bar (bottom left area)
    if player_pokemon:
        _draw_hp_bar(Vector2(w * 0.52, h * 0.62), w * 0.4, player_pokemon)

    # === WILD POKEMON (top right) ===
    var wx_pos = w * 0.72
    var wy_pos = h * 0.28
    if wild_sprite and wild_pokemon:
        var shake_x = sin(wild_shake * 20.0) * wild_shake * 12.0
        var wobble = sin(shake_timer * 25.0) * 10.0 if phase == Phase.CATCH_SHAKE else 0.0
        var bob = sin(Time.get_ticks_msec() * 0.003) * 3.0
        var spr_size = minf(w, h) * 0.25
        if wild_flash > 0:
            draw_circle(Vector2(wx_pos + shake_x + wobble, wy_pos + bob), spr_size * 0.5, Color(1, 1, 1, wild_flash * 0.3))
        draw_texture_rect(wild_sprite, Rect2(wx_pos - spr_size/2 + shake_x + wobble, wy_pos - spr_size/2 + bob, spr_size, spr_size), false)

    # Wild HP bar (top right area)
    if wild_pokemon:
        _draw_hp_bar(Vector2(w * 0.05, h * 0.08), w * 0.4, wild_pokemon)

    # === CATCH CIRCLE (over wild pokemon) ===
    if phase == Phase.CATCH_AIM:
        var target = Vector2(wx_pos, wy_pos)
        draw_arc(target, circle_max, 0, TAU, 48, Color(1, 1, 1, 0.25), 2.0)
        var c_ratio = circle_radius / circle_max
        var c_color = Color("#4caf50") if c_ratio > 0.6 else (Color("#ff9800") if c_ratio > 0.35 else Color("#f44336"))
        draw_arc(target, circle_radius, 0, TAU, 48, c_color, 3.0)

    # === POKEBALL (during catch) ===
    if phase in [Phase.CATCH_AIM, Phase.CATCH_THROW]:
        var bp = ball_pos if ball_active else Vector2(w / 2, h - 60)
        _draw_pokeball(bp, 12.0)

    # === THROW RATING ===
    if throw_rating and phase in [Phase.CATCH_SHAKE, Phase.END]:
        var rc = Color("#ffd700") if "Excellent" in throw_rating else (Color("#ff9800") if "Great" in throw_rating else Color("#4caf50"))
        draw_string(ThemeDB.fallback_font, Vector2(w/2 - 40, h * 0.5), throw_rating, HORIZONTAL_ALIGNMENT_CENTER, 80, 20, rc)

    # === MESSAGE BOX ===
    draw_rect(Rect2(w * 0.02, h - 80, w * 0.96, 65), Color(0.08, 0.12, 0.2, 0.95))
    draw_rect(Rect2(w * 0.02, h - 80, w * 0.96, 65), Color("#4fc3f7"), false, 2.0)
    draw_string(ThemeDB.fallback_font, Vector2(w * 0.04, h - 52), message, HORIZONTAL_ALIGNMENT_LEFT, w * 0.92, 14, Color("#e0e0e0"))

    # === BUTTONS ===
    if phase == Phase.MENU:
        var btn_y = h - 130
        var btn_w = w * 0.22
        var labels = ["FIGHT", "CATCH", "BERRY", "RUN"]
        var colors = [Color("#e53935"), Color("#2196f3"), Color("#4caf50"), Color("#ff9800")]
        for i in 4:
            var bx = w * (0.02 + i * 0.24)
            draw_rect(Rect2(bx, btn_y, btn_w, 40), Color(0.08, 0.08, 0.12, 0.9))
            draw_rect(Rect2(bx, btn_y, btn_w, 40), colors[i], false, 2.0)
            draw_string(ThemeDB.fallback_font, Vector2(bx + 10, btn_y + 28), labels[i], HORIZONTAL_ALIGNMENT_LEFT, btn_w - 20, 14, colors[i])

    # Back button during catch aim
    if phase == Phase.CATCH_AIM:
        draw_rect(Rect2(w - 110, h - 55, 90, 40), Color(0.1, 0.1, 0.15, 0.9))
        draw_rect(Rect2(w - 110, h - 55, 90, 40), Color("#ff9800"), false, 1.5)
        draw_string(ThemeDB.fallback_font, Vector2(w - 100, h - 28), "BACK", HORIZONTAL_ALIGNMENT_LEFT, 70, 13, Color("#ff9800"))
        # Ball count
        if inventory:
            draw_string(ThemeDB.fallback_font, Vector2(20, h - 95), "Balls: %d" % inventory.total_balls(), HORIZONTAL_ALIGNMENT_LEFT, 100, 11, Color("#aaa"))

func _draw_hp_bar(pos: Vector2, width: float, pkmn):
    draw_string(ThemeDB.fallback_font, pos, "%s Lv.%d" % [pkmn.pokemon_name, pkmn.level], HORIZONTAL_ALIGNMENT_LEFT, width, 13, Color.WHITE)
    var bar_y = pos.y + 6
    draw_rect(Rect2(pos.x, bar_y, width, 10), Color("#222"))
    var ratio = float(pkmn.hp) / float(pkmn.max_hp)
    var bar_color = Color("#4caf50") if ratio > 0.5 else (Color("#ff9800") if ratio > 0.25 else Color("#f44336"))
    draw_rect(Rect2(pos.x, bar_y, width * ratio, 10), bar_color)
    draw_string(ThemeDB.fallback_font, Vector2(pos.x + width + 5, bar_y + 10), "%d/%d" % [pkmn.hp, pkmn.max_hp], HORIZONTAL_ALIGNMENT_LEFT, 80, 10, Color("#aaa"))

func _draw_pokeball(pos: Vector2, radius: float):
    draw_circle(pos + Vector2(0, -2), radius, Color("#e53935"))
    draw_circle(pos + Vector2(0, 3), radius, Color.WHITE)
    draw_line(pos + Vector2(-radius, 0), pos + Vector2(radius, 0), Color("#333"), 2.5)
    draw_circle(pos, 4, Color.WHITE)
    draw_arc(pos, 4, 0, TAU, 8, Color("#333"), 2.0)
