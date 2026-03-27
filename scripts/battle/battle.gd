extends Control

# ─── Phase definitions ───────────────────────────────────────────────────────
enum Phase {
    INTRO,
    MENU,
    FIGHT,          # move selection sub-menu
    BAG,            # ball selection sub-menu
    MOVE_SELECT,    # alias - same UI as FIGHT
    PLAYER_ATK,
    WILD_ATK,
    CATCH_THROW,
    CATCH_SHAKE,
    END
}

# ─── State ────────────────────────────────────────────────────────────────────
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

# Trainer battle state
var is_trainer_battle: bool = false
var trainer_name: String = ""
var trainer_team: Array = []
var trainer_current: int = 0

# Attack animation
var wild_shake: float = 0.0
var player_shake: float = 0.0
var wild_flash: float = 0.0
var player_flash: float = 0.0
var intro_timer: float = 2.0

# Ball throw / shake
var ball_pos: Vector2 = Vector2.ZERO
var ball_vel: Vector2 = Vector2.ZERO
var ball_active: bool = false
var ball_type_used: String = "pokeball"   # which ball was thrown
var shake_count: int = 0
var shake_timer: float = 0.0
var max_shakes: int = 0   # 0-3 shakes before break or catch

# Poison chip damage
var poison_timer: float = 0.0

# Wild HP at start of each turn (for red-flash transition)
var selected_move_index: int = -1

# ─── Signal ───────────────────────────────────────────────────────────────────
signal battle_ended(result_str: String, wild)

# ─── Type colours for move buttons ───────────────────────────────────────────
const TYPE_COLORS: Dictionary = {
    "normal":   Color("#aaa"),
    "fire":     Color("#f44"),
    "water":    Color("#4af"),
    "grass":    Color("#4c4"),
    "electric": Color("#fd2"),
    "rock":     Color("#b96"),
    "ground":   Color("#d94"),
    "ghost":    Color("#86b"),
    "dark":     Color("#654"),
    "ice":      Color("#6df"),
    "psychic":  Color("#f6a"),
    "fairy":    Color("#f9c"),
    "poison":   Color("#a5a"),
    "flying":   Color("#8af"),
    "steel":    Color("#9af"),
    "dragon":   Color("#66f"),
    "fighting": Color("#c64"),
}

# ─── Setup ────────────────────────────────────────────────────────────────────
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
    selected_move_index = -1
    ball_active = false
    shake_count = 0
    shake_timer = 0.0
    poison_timer = 0.0
    visible = true

func set_inventory(inv):
    inventory = inv

func start_trainer_battle(t_name: String, team: Array):
    is_trainer_battle = true
    trainer_name = t_name
    trainer_team = team
    trainer_current = 0
    if trainer_team.size() > 0:
        wild_pokemon = trainer_team[trainer_current]
        wild_sprite = PokemonDB.get_sprite_texture(wild_pokemon.id)
    phase = Phase.INTRO
    message = "%s sent out %s!" % [trainer_name, wild_pokemon.pokemon_name if wild_pokemon else "???"]
    intro_timer = 2.0
    message_timer = 0.0
    result = ""
    leveled_up = false
    selected_move_index = -1
    ball_active = false
    shake_count = 0
    shake_timer = 0.0
    poison_timer = 0.0
    visible = true

# ─── Process loop ─────────────────────────────────────────────────────────────
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
                message = "What will %s do?" % (player_pokemon.pokemon_name if player_pokemon else "you")

        Phase.PLAYER_ATK:
            if message_timer > 0:
                message_timer -= delta
                if message_timer <= 0:
                    if not wild_pokemon.is_alive():
                        _on_wild_fainted()
                    else:
                        _wild_attack()

        Phase.WILD_ATK:
            if message_timer > 0:
                message_timer -= delta
                if message_timer <= 0:
                    # Apply poison chip to wild
                    if wild_pokemon.status == "poisoned":
                        var chip = maxi(1, wild_pokemon.max_hp / 8)
                        wild_pokemon.hp = maxi(0, wild_pokemon.hp - chip)
                        message = "%s is hurt by poison!" % wild_pokemon.pokemon_name
                        wild_flash = 0.7
                        message_timer = 1.0
                        # Check if wild fainted from poison
                        if not wild_pokemon.is_alive():
                            _on_wild_fainted()
                            return
                    # Apply poison chip to player
                    if player_pokemon and player_pokemon.status == "poisoned":
                        var chip = maxi(1, player_pokemon.max_hp / 8)
                        player_pokemon.hp = maxi(0, player_pokemon.hp - chip)
                        player_flash = 0.7
                        if message_timer <= 0:
                            message = "%s is hurt by poison!" % player_pokemon.pokemon_name
                            message_timer = 1.0
                            if not player_pokemon.is_alive():
                                _on_player_fainted()
                                return
                    if message_timer <= 0:
                        if player_pokemon and not player_pokemon.is_alive():
                            _on_player_fainted()
                        else:
                            phase = Phase.MENU
                            message = "What will %s do?" % (player_pokemon.pokemon_name if player_pokemon else "you")

        Phase.CATCH_THROW:
            ball_pos += ball_vel * delta
            ball_vel.y += 100.0 * delta  # gravity
            var target = Vector2(size.x * 0.72, size.y * 0.28)
            if ball_pos.distance_to(target) < 35:
                ball_active = false
                _evaluate_catch()
            elif ball_pos.y > size.y + 40 or ball_pos.x < -40 or ball_pos.x > size.x + 40:
                ball_active = false
                phase = Phase.MENU
                message = "Oh no! The ball missed!"

        Phase.CATCH_SHAKE:
            shake_timer -= delta
            if shake_timer <= 0:
                shake_count += 1
                if shake_count >= max_shakes:
                    if max_shakes >= 3:
                        # Caught!
                        phase = Phase.END
                        result = "caught"
                        message = "Gotcha! %s was caught!" % wild_pokemon.pokemon_name
                        message_timer = 2.5
                    else:
                        # Broke free
                        phase = Phase.MENU
                        message = "%s broke free!" % wild_pokemon.pokemon_name
                else:
                    shake_timer = 0.55
                    message = "..." * (shake_count + 1)

        Phase.END:
            if message_timer > 0:
                message_timer -= delta
                if message_timer <= 0:
                    battle_ended.emit(result, wild_pokemon)
                    visible = false

    queue_redraw()

# ─── Input handling ───────────────────────────────────────────────────────────
func _gui_input(event):
    if not visible:
        return
    if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
        return
    var pos = event.position
    var w = size.x
    var h = size.y

    match phase:
        Phase.MENU:
            _handle_menu_click(pos, w, h)
        Phase.FIGHT:
            _handle_fight_click(pos, w, h)
        Phase.BAG:
            _handle_bag_click(pos, w, h)

# ─── Menu button layout helpers ───────────────────────────────────────────────
func _main_button_rects(w: float, h: float) -> Array:
    # 2x2 grid in bottom-right quadrant: FIGHT | BAG / POKEMON | RUN
    var bw = w * 0.2
    var bh = 38.0
    var x0 = w * 0.56
    var y0 = h - 95
    return [
        {"label": "FIGHT",   "rect": Rect2(x0,       y0,      bw, bh), "action": "fight",   "color": Color("#e53935")},
        {"label": "BAG",     "rect": Rect2(x0 + bw + 6, y0,  bw, bh), "action": "bag",     "color": Color("#2196f3")},
        {"label": "POKEMON", "rect": Rect2(x0,       y0 + bh + 6, bw, bh), "action": "pokemon", "color": Color("#4caf50")},
        {"label": "RUN",     "rect": Rect2(x0 + bw + 6, y0 + bh + 6, bw, bh), "action": "run", "color": Color("#ff9800")},
    ]

func _move_button_rects(w: float, h: float) -> Array:
    var bw = w * 0.43
    var bh = 36.0
    var x0 = w * 0.02
    var y0 = h - 115
    var rects = []
    for i in 4:
        var col = i % 2
        var row = i / 2
        rects.append(Rect2(x0 + col * (bw + 8), y0 + row * (bh + 6), bw, bh))
    return rects

func _ball_button_rects(w: float, h: float) -> Array:
    var balls_list = [
        {"key": "pokeball",  "label": "Pokeball",   "color": Color("#e53935")},
        {"key": "greatball", "label": "Great Ball",  "color": Color("#2196f3")},
        {"key": "ultraball", "label": "Ultra Ball",  "color": Color("#ffd700")},
        {"key": "masterball","label": "Master Ball", "color": Color("#ab47bc")},
    ]
    var bw = w * 0.43
    var bh = 34.0
    var x0 = w * 0.02
    var y0 = h - 115
    var result_list = []
    for i in balls_list.size():
        var col = i % 2
        var row = i / 2
        balls_list[i]["rect"] = Rect2(x0 + col * (bw + 8), y0 + row * (bh + 6), bw, bh)
        result_list.append(balls_list[i])
    return result_list

# ─── Click handlers ───────────────────────────────────────────────────────────
func _handle_menu_click(pos: Vector2, w: float, h: float):
    for btn in _main_button_rects(w, h):
        if btn["rect"].has_point(pos):
            match btn["action"]:
                "fight":
                    if player_pokemon and player_pokemon.known_moves.size() > 0:
                        phase = Phase.FIGHT
                        message = "Choose a move!"
                    else:
                        _player_attack_move(-1)
                "bag":
                    if is_trainer_battle:
                        message = "You can't catch trainer Pokemon!"
                    elif not inventory or inventory.total_balls() <= 0:
                        message = "No Pokeballs left!"
                    else:
                        phase = Phase.BAG
                        message = "Choose a ball!"
                "pokemon":
                    message = "No other Pokemon available."
                "run":
                    _flee()
            return

func _handle_fight_click(pos: Vector2, w: float, h: float):
    # Back button
    var back_rect = Rect2(size.x - 105, size.y - 45, 90, 34)
    if back_rect.has_point(pos):
        phase = Phase.MENU
        message = "What will %s do?" % (player_pokemon.pokemon_name if player_pokemon else "you")
        return
    var move_rects = _move_button_rects(w, h)
    var moves = player_pokemon.known_moves if player_pokemon else []
    for i in mini(moves.size(), move_rects.size()):
        if move_rects[i].has_point(pos):
            _player_attack_move(i)
            return

func _handle_bag_click(pos: Vector2, w: float, h: float):
    # Back button
    var back_rect = Rect2(size.x - 105, size.y - 45, 90, 34)
    if back_rect.has_point(pos):
        phase = Phase.MENU
        message = "What will %s do?" % (player_pokemon.pokemon_name if player_pokemon else "you")
        return
    var ball_btns = _ball_button_rects(w, h)
    for btn in ball_btns:
        if btn["rect"].has_point(pos):
            _throw_ball(btn["key"])
            return

# ─── Combat actions ───────────────────────────────────────────────────────────
func _player_attack_move(move_index: int):
    phase = Phase.PLAYER_ATK
    selected_move_index = move_index
    if player_pokemon == null:
        _wild_attack()
        return

    var dmg_data: Dictionary
    if move_index >= 0 and move_index < player_pokemon.known_moves.size():
        var move = player_pokemon.use_move(move_index)
        if move.is_empty():
            message = "No PP left!"
            message_timer = 1.2
            phase = Phase.FIGHT
            return
        dmg_data = player_pokemon.calc_damage_with_move(wild_pokemon, move)
        wild_pokemon.hp = maxi(0, wild_pokemon.hp - dmg_data["damage"])
        wild_shake = 1.0
        wild_flash = 1.0
        var mname = move.get("name", "Attack")
        var eff_text = (" " + dmg_data["text"]) if dmg_data["text"] != "" else ""
        if dmg_data["damage"] > 0:
            message = "%s used %s! %d dmg.%s" % [player_pokemon.pokemon_name, mname, dmg_data["damage"], eff_text]
        else:
            message = "%s used %s!%s" % [player_pokemon.pokemon_name, mname, eff_text]
    else:
        # Fallback: use first move or type-based
        dmg_data = player_pokemon.calc_damage(wild_pokemon)
        wild_pokemon.hp = maxi(0, wild_pokemon.hp - dmg_data["damage"])
        wild_shake = 1.0
        wild_flash = 1.0
        var eff_text = (" " + dmg_data["text"]) if dmg_data["text"] != "" else ""
        message = "%s attacks! %d dmg.%s" % [player_pokemon.pokemon_name, dmg_data["damage"], eff_text]

    message_timer = 1.5

func _wild_attack():
    phase = Phase.WILD_ATK
    if wild_pokemon.status == "sleep":
        message = "%s is fast asleep..." % wild_pokemon.pokemon_name
        message_timer = 1.2
        return
    if wild_pokemon.status == "paralyzed" and randf() < 0.25:
        message = "%s is paralyzed! It can't move!" % wild_pokemon.pokemon_name
        message_timer = 1.2
        return
    if player_pokemon == null:
        phase = Phase.MENU
        return
    # Wild uses a random move
    var dmg_data: Dictionary
    if wild_pokemon.known_moves.size() > 0:
        var idx = randi_range(0, wild_pokemon.known_moves.size() - 1)
        var move = wild_pokemon.known_moves[idx].duplicate()
        # Wild pokemon don't run out of PP in battles
        dmg_data = wild_pokemon.calc_damage_with_move(player_pokemon, move)
    else:
        dmg_data = wild_pokemon.calc_damage(player_pokemon)
    player_pokemon.hp = maxi(0, player_pokemon.hp - dmg_data["damage"])
    player_shake = 1.0
    player_flash = 1.0
    var mname = dmg_data.get("move_name", "")
    var eff_text = (" " + dmg_data["text"]) if dmg_data["text"] != "" else ""
    if mname != "" and dmg_data["damage"] > 0:
        message = "%s used %s! %d dmg.%s" % [wild_pokemon.pokemon_name, mname, dmg_data["damage"], eff_text]
    elif dmg_data["damage"] > 0:
        message = "%s attacks! %d dmg.%s" % [wild_pokemon.pokemon_name, dmg_data["damage"], eff_text]
    else:
        message = "%s used %s!%s" % [wild_pokemon.pokemon_name, mname if mname != "" else "an attack", eff_text]
    message_timer = 1.5

func _on_wild_fainted():
    var xp_gain = wild_pokemon.level * 10
    leveled_up = player_pokemon.gain_xp(xp_gain) if player_pokemon else false

    if is_trainer_battle:
        trainer_current += 1
        if trainer_current < trainer_team.size():
            # Trainer sends out next Pokemon
            wild_pokemon = trainer_team[trainer_current]
            wild_sprite = PokemonDB.get_sprite_texture(wild_pokemon.id)
            phase = Phase.INTRO
            intro_timer = 1.5
            if leveled_up:
                message = "%s fainted! +%d XP — %s leveled up! %s sends out %s!" % [
                    trainer_team[trainer_current - 1].pokemon_name, xp_gain,
                    player_pokemon.pokemon_name, trainer_name, wild_pokemon.pokemon_name]
            else:
                message = "%s fainted! %s sends out %s!" % [
                    trainer_team[trainer_current - 1].pokemon_name,
                    trainer_name, wild_pokemon.pokemon_name]
            message_timer = 2.0
        else:
            # All trainer Pokemon defeated
            phase = Phase.END
            result = "trainer_defeated"
            if leveled_up:
                message = "%s fainted! +%d XP — %s leveled up! You defeated %s!" % [
                    wild_pokemon.pokemon_name, xp_gain,
                    player_pokemon.pokemon_name, trainer_name]
            else:
                message = "%s fainted! +%d XP\nYou defeated %s!" % [
                    wild_pokemon.pokemon_name, xp_gain, trainer_name]
            message_timer = 2.5
    else:
        phase = Phase.END
        result = "defeated"
        if leveled_up:
            message = "%s fainted! +%d XP — %s leveled up!" % [wild_pokemon.pokemon_name, xp_gain, player_pokemon.pokemon_name]
        else:
            message = "%s fainted! +%d XP" % [wild_pokemon.pokemon_name, xp_gain]
        message_timer = 2.5

func _on_player_fainted():
    phase = Phase.END
    result = "fled"
    message = "%s fainted! You blacked out..." % player_pokemon.pokemon_name
    message_timer = 2.5

func _throw_ball(ball_key: String):
    if not inventory:
        return
    var count = inventory.balls.get(ball_key, 0)
    if count <= 0:
        message = "No %s left!" % ball_key
        return
    inventory.balls[ball_key] -= 1
    ball_type_used = ball_key
    # Arc from bottom-centre toward wild pokemon
    ball_pos = Vector2(size.x * 0.22, size.y * 0.6)
    var target = Vector2(size.x * 0.72, size.y * 0.28)
    var dist = target - ball_pos
    # Give it enough upward velocity to arc nicely
    var travel_time = 0.7
    ball_vel = Vector2(dist.x / travel_time, dist.y / travel_time - 0.5 * 100.0 * travel_time)
    ball_active = true
    phase = Phase.CATCH_THROW
    message = "You threw a %s!" % ball_key.capitalize()

func _evaluate_catch():
    # Classic formula adapted: ((3*maxHP - 2*currentHP) * speciesRate * ballBonus) / (3*maxHP)
    var species = wild_pokemon.species
    # Map rarity 1-4 to catch_rate 255-45
    var rarity_to_rate = {1: 200, 2: 120, 3: 60, 4: 30}
    var species_rate = float(rarity_to_rate.get(species.get("rarity", 2), 100))

    var ball_bonuses = {"pokeball": 1.0, "greatball": 1.5, "ultraball": 2.0, "masterball": 255.0}
    var ball_bonus = ball_bonuses.get(ball_type_used, 1.0)

    # Status modifier
    var status_mod = 1.0
    match wild_pokemon.status:
        "sleep":    status_mod = 2.0
        "paralyzed": status_mod = 1.5
        "poisoned": status_mod = 1.5

    # Master ball always catches
    if ball_type_used == "masterball":
        max_shakes = 3
        phase = Phase.CATCH_SHAKE
        shake_count = 0
        shake_timer = 0.5
        message = "..."
        return

    var max_hp_f = float(wild_pokemon.max_hp)
    var cur_hp_f = float(wild_pokemon.hp)
    var catch_value = ((3.0 * max_hp_f - 2.0 * cur_hp_f) * species_rate * ball_bonus * status_mod) / (3.0 * max_hp_f)
    # Clamp to reasonable range
    catch_value = clampf(catch_value, 0.0, 255.0)

    # Number of shakes (0-3) — each shake requires passing a check
    # p(shake) = (catch_value / 255)^(1/4) approximation
    var shake_prob = pow(catch_value / 255.0, 0.25)
    var shakes = 0
    for _i in 3:
        if randf() < shake_prob:
            shakes += 1
        else:
            break

    max_shakes = shakes
    shake_count = 0
    shake_timer = 0.55

    if shakes >= 3:
        # Caught after 3 shakes
        phase = Phase.CATCH_SHAKE
        message = "..."
    else:
        # Will break free after `shakes` shakes
        phase = Phase.CATCH_SHAKE
        message = "..."

func _flee():
    phase = Phase.END
    result = "fled"
    message = "Got away safely!"
    message_timer = 1.0

# ─── Draw ─────────────────────────────────────────────────────────────────────
func _draw():
    if not visible:
        return
    var w = size.x
    var h = size.y

    # Background
    draw_rect(Rect2(0, 0, w, h), Color(0.04, 0.06, 0.1))
    # Subtle arena stripes
    for i in 8:
        draw_rect(Rect2(0, h * 0.2 + i * h * 0.06, w, h * 0.06),
            Color(0.06 + i * 0.008, 0.1 + i * 0.005, 0.18 + i * 0.01, 0.4))

    # Ground platforms
    draw_rect(Rect2(w * 0.05, h * 0.6, w * 0.35, 8),  Color(0.3, 0.25, 0.2, 0.6))
    draw_rect(Rect2(w * 0.55, h * 0.42, w * 0.35, 8), Color(0.3, 0.25, 0.2, 0.6))

    # === PLAYER POKEMON (bottom-left) ===
    var px = w * 0.22
    var py = h * 0.52
    if player_sprite and player_pokemon:
        var shake_x = sin(player_shake * 20.0) * player_shake * 12.0
        var spr_size = minf(w, h) * 0.22
        if player_flash > 0:
            draw_circle(Vector2(px + shake_x, py), spr_size * 0.5,
                Color(1, 0.3, 0.3, player_flash * 0.3))
        draw_texture_rect(player_sprite,
            Rect2(px - spr_size / 2 + shake_x, py - spr_size / 2, spr_size, spr_size), false)

    # Player info panel (bottom-left quadrant)
    if player_pokemon:
        _draw_info_panel(Vector2(w * 0.03, h * 0.65), w * 0.46, player_pokemon, false)

    # === WILD POKEMON (top-right) ===
    var wx_pos = w * 0.72
    var wy_pos = h * 0.28
    if wild_sprite and wild_pokemon:
        var shake_x = sin(wild_shake * 20.0) * wild_shake * 12.0
        var wobble = 0.0
        if phase == Phase.CATCH_SHAKE and shake_count > 0:
            wobble = sin(Time.get_ticks_msec() * 0.04) * 8.0
        var bob = sin(Time.get_ticks_msec() * 0.003) * 3.0
        var spr_size = minf(w, h) * 0.25
        if wild_flash > 0:
            draw_circle(Vector2(wx_pos + shake_x + wobble, wy_pos + bob), spr_size * 0.5,
                Color(1, 1, 1, wild_flash * 0.3))
        draw_texture_rect(wild_sprite,
            Rect2(wx_pos - spr_size / 2 + shake_x + wobble, wy_pos - spr_size / 2 + bob, spr_size, spr_size), false)

    # Wild info panel (top area) — show trainer name header during trainer battles
    if wild_pokemon:
        if is_trainer_battle and trainer_name != "":
            var label_str = trainer_name
            draw_string(ThemeDB.fallback_font, Vector2(w * 0.52, h * 0.035),
                label_str, HORIZONTAL_ALIGNMENT_LEFT, w * 0.46, 11, Color("#ffd700"))
        _draw_info_panel(Vector2(w * 0.52, h * 0.06), w * 0.46, wild_pokemon, true)

    # === POKEBALL (during throw) ===
    if phase == Phase.CATCH_THROW and ball_active:
        _draw_pokeball(ball_pos, 12.0, ball_type_used)
    elif phase == Phase.CATCH_SHAKE:
        # Ball sits on top of wild pokemon
        var wobble = sin(Time.get_ticks_msec() * 0.04) * 8.0 if shake_count > 0 else 0.0
        _draw_pokeball(Vector2(wx_pos + wobble, wy_pos - 28), 12.0, ball_type_used)

    # === MESSAGE BOX ===
    var msg_rect = Rect2(w * 0.02, h - 78, w * 0.96, 62)
    draw_rect(msg_rect, Color(0.08, 0.12, 0.2, 0.96))
    draw_rect(msg_rect, Color("#4fc3f7"), false, 2.0)
    draw_string(ThemeDB.fallback_font, Vector2(w * 0.04, h - 50),
        message, HORIZONTAL_ALIGNMENT_LEFT, w * 0.92, 14, Color("#e0e0e0"))

    # === PHASE-SPECIFIC UI ===
    match phase:
        Phase.MENU:
            _draw_main_menu(w, h)
        Phase.FIGHT:
            _draw_move_menu(w, h)
        Phase.BAG:
            _draw_bag_menu(w, h)

func _draw_info_panel(pos: Vector2, width: float, pkmn, is_wild: bool):
    var panel_h = 52.0
    draw_rect(Rect2(pos.x, pos.y, width, panel_h), Color(0.06, 0.08, 0.14, 0.92))
    draw_rect(Rect2(pos.x, pos.y, width, panel_h), Color("#4fc3f7"), false, 1.5)

    # Name + Level
    var name_str = "%s    Lv.%d" % [pkmn.pokemon_name, pkmn.level]
    draw_string(ThemeDB.fallback_font, Vector2(pos.x + 8, pos.y + 18),
        name_str, HORIZONTAL_ALIGNMENT_LEFT, width - 16, 14, Color.WHITE)

    # Status icon
    var status_icon = ""
    var status_col = Color.WHITE
    match pkmn.status:
        "sleep":     status_icon = "ZZZ"; status_col = Color("#9c27b0")
        "paralyzed": status_icon = "PAR"; status_col = Color("#ffd600")
        "poisoned":  status_icon = "PSN"; status_col = Color("#ab47bc")
    if status_icon != "":
        draw_string(ThemeDB.fallback_font, Vector2(pos.x + width - 44, pos.y + 18),
            status_icon, HORIZONTAL_ALIGNMENT_LEFT, 40, 11, status_col)

    # HP bar
    var bar_y = pos.y + 26
    var bar_w = width - 16
    draw_rect(Rect2(pos.x + 8, bar_y, bar_w, 9), Color("#222"))
    var ratio = float(pkmn.hp) / float(pkmn.max_hp)
    var bar_color = Color("#4caf50") if ratio > 0.5 else (Color("#ff9800") if ratio > 0.25 else Color("#f44336"))
    draw_rect(Rect2(pos.x + 8, bar_y, bar_w * ratio, 9), bar_color)

    # HP numbers
    var hp_str = "HP: %d/%d" % [pkmn.hp, pkmn.max_hp]
    draw_string(ThemeDB.fallback_font, Vector2(pos.x + 8, bar_y + 20),
        hp_str, HORIZONTAL_ALIGNMENT_LEFT, bar_w, 11, Color("#aaa"))

func _draw_main_menu(w: float, h: float):
    for btn in _main_button_rects(w, h):
        # Hide BAG button during trainer battles (can't catch trainer Pokemon)
        if is_trainer_battle and btn["action"] == "bag":
            continue
        draw_rect(btn["rect"], Color(0.08, 0.08, 0.12, 0.92))
        draw_rect(btn["rect"], btn["color"], false, 2.0)
        draw_string(ThemeDB.fallback_font,
            Vector2(btn["rect"].position.x + 8, btn["rect"].position.y + 26),
            btn["label"], HORIZONTAL_ALIGNMENT_LEFT, btn["rect"].size.x - 16, 14, btn["color"])

func _draw_move_menu(w: float, h: float):
    if not player_pokemon:
        return
    var moves = player_pokemon.known_moves
    var move_rects = _move_button_rects(w, h)
    for i in mini(moves.size(), move_rects.size()):
        var mv = moves[i]
        var r = move_rects[i]
        var tc = TYPE_COLORS.get(mv.get("type", "normal"), Color("#aaa"))
        draw_rect(r, Color(0.06, 0.06, 0.12, 0.95))
        draw_rect(r, tc, false, 2.0)
        # Move name
        var mname = mv.get("name", "???")
        draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 6, r.position.y + 16),
            mname, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 12, 13, Color.WHITE)
        # Type label
        var type_str = mv.get("type", "").to_upper()
        draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 6, r.position.y + 30),
            type_str, HORIZONTAL_ALIGNMENT_LEFT, r.size.x * 0.5, 10, tc)
        # PP
        var pp_str = "PP %d/%d" % [mv.get("current_pp", 0), mv.get("pp", 0)]
        var pp_col = Color("#f44") if mv.get("current_pp", 0) == 0 else Color("#aaa")
        draw_string(ThemeDB.fallback_font,
            Vector2(r.position.x + r.size.x - 68, r.position.y + 30),
            pp_str, HORIZONTAL_ALIGNMENT_LEFT, 64, 10, pp_col)

    # Back button
    _draw_back_button(w, h)

func _draw_bag_menu(w: float, h: float):
    var ball_btns = _ball_button_rects(w, h)
    for btn in ball_btns:
        var count = inventory.balls.get(btn["key"], 0) if inventory else 0
        var col = btn["color"] if count > 0 else Color("#555")
        draw_rect(btn["rect"], Color(0.06, 0.06, 0.12, 0.95))
        draw_rect(btn["rect"], col, false, 2.0)
        var label = "%s  x%d" % [btn["label"], count]
        draw_string(ThemeDB.fallback_font,
            Vector2(btn["rect"].position.x + 8, btn["rect"].position.y + 22),
            label, HORIZONTAL_ALIGNMENT_LEFT, btn["rect"].size.x - 16, 13,
            Color.WHITE if count > 0 else Color("#555"))

    # Back button
    _draw_back_button(w, h)

func _draw_back_button(w: float, h: float):
    var r = Rect2(w - 105, h - 45, 90, 34)
    draw_rect(r, Color(0.1, 0.1, 0.15, 0.92))
    draw_rect(r, Color("#ff9800"), false, 1.5)
    draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 8, r.position.y + 23),
        "BACK", HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 16, 13, Color("#ff9800"))

func _draw_pokeball(pos: Vector2, radius: float, ball_key: String = "pokeball"):
    var top_col = Color("#e53935")
    match ball_key:
        "greatball":  top_col = Color("#2196f3")
        "ultraball":  top_col = Color("#ffd700")
        "masterball": top_col = Color("#ab47bc")
    draw_circle(pos + Vector2(0, -2), radius, top_col)
    draw_circle(pos + Vector2(0, 3), radius, Color.WHITE)
    draw_line(pos + Vector2(-radius, 0), pos + Vector2(radius, 0), Color("#333"), 2.5)
    draw_circle(pos, 4, Color.WHITE)
    draw_arc(pos, 4, 0, TAU, 8, Color("#333"), 2.0)
