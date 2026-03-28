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

# Party switch
var party_ref: Array = []
var show_party_select: bool = false

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

# Move animation
var move_anim_name: String = ""
var move_anim_timer: float = 0.0
var move_anim_type: String = ""
var move_anim_target: String = ""  # "wild" or "player"
var move_particles: Array = []

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
    # Reset trainer battle state
    is_trainer_battle = false
    trainer_name = ""
    trainer_team = []
    trainer_current = 0

    party_ref = GameManager.party
    player_pokemon = party[0] if party.size() > 0 else null
    wild_pokemon = wild
    inventory = inv
    wild_sprite = PokemonDB.get_sprite_texture(wild.id)
    if player_pokemon:
        player_sprite = PokemonDB.get_sprite_texture(player_pokemon.id)
    phase = Phase.INTRO
    message = "A wild %s appeared!" % wild.pokemon_name
    # Ability: Intimidate (lower wild ATK on entry)
    if player_pokemon and player_pokemon.ability == "Intimidate":
        wild_pokemon.atk = int(wild_pokemon.atk * 0.8)
        message += " %s intimidated %s!" % [player_pokemon.pokemon_name, wild_pokemon.pokemon_name]
    intro_timer = 2.0
    message_timer = 0.0
    result = ""
    leveled_up = false
    selected_move_index = -1
    ball_active = false
    shake_count = 0
    shake_timer = 0.0
    poison_timer = 0.0
    move_anim_timer = 0.0
    move_particles = []
    # Reset stat stages at battle start
    if player_pokemon: player_pokemon.reset_stages()
    if wild_pokemon: wild_pokemon.reset_stages()
    visible = true
    print("[BATTLE] Started wild battle: %s (Lv.%d) vs %s (Lv.%d)" % [
        wild.pokemon_name, wild.level,
        player_pokemon.pokemon_name if player_pokemon else "NONE",
        player_pokemon.level if player_pokemon else 0])
    EventTracker.log_event("BATTLE_START", {"wild": wild.pokemon_name, "wild_lv": wild.level, "wild_hp": wild.max_hp, "player": player_pokemon.pokemon_name if player_pokemon else "NONE", "player_lv": player_pokemon.level if player_pokemon else 0, "player_moves": player_pokemon.known_moves.size() if player_pokemon else 0})

func set_inventory(inv):
    inventory = inv

func start_trainer_battle(t_name: String, team: Array):
    is_trainer_battle = true
    trainer_name = t_name
    trainer_team = team
    trainer_current = 0

    party_ref = GameManager.party
    # Set player pokemon from party
    player_pokemon = GameManager.party[0] if GameManager.party.size() > 0 else null
    if player_pokemon:
        player_sprite = PokemonDB.get_sprite_texture(player_pokemon.id)

    if trainer_team.size() > 0:
        wild_pokemon = trainer_team[trainer_current]
        wild_sprite = PokemonDB.get_sprite_texture(wild_pokemon.id)
    phase = Phase.INTRO
    message = "%s sent out %s!" % [trainer_name, wild_pokemon.pokemon_name if wild_pokemon else "???"]
    # Ability: Intimidate (lower opponent ATK on entry)
    if player_pokemon and player_pokemon.ability == "Intimidate" and wild_pokemon:
        wild_pokemon.atk = int(wild_pokemon.atk * 0.8)
        message += " %s intimidated %s!" % [player_pokemon.pokemon_name, wild_pokemon.pokemon_name]
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
    EventTracker.log_event("TRAINER_BATTLE_START", {"trainer": t_name, "team_size": team.size()})

# ─── Process loop ─────────────────────────────────────────────────────────────
func _process(delta):
    if not visible:
        return

    # Animation decay
    wild_shake = move_toward(wild_shake, 0.0, delta * 12.0)
    player_shake = move_toward(player_shake, 0.0, delta * 12.0)
    wild_flash = move_toward(wild_flash, 0.0, delta * 3.0)
    player_flash = move_toward(player_flash, 0.0, delta * 3.0)

    # Move animation timer
    if move_anim_timer > 0:
        move_anim_timer -= delta

    # Update move particles
    for p in move_particles:
        p["x"] += p["vx"] * delta
        p["y"] += p["vy"] * delta
        p["vy"] += 40 * delta  # gravity
        p["life"] -= delta
    move_particles = move_particles.filter(func(p): return p["life"] > 0)

    match phase:
        Phase.INTRO:
            intro_timer -= delta
            if intro_timer <= 0:
                phase = Phase.MENU
                message = "What will %s do?" % (player_pokemon.pokemon_name if player_pokemon else "you")
                print("[BATTLE] Phase → MENU. Click FIGHT or press F to attack.")

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
                    # After wild attack message finishes, return to menu
                    if player_pokemon and not player_pokemon.is_alive():
                        _on_player_fainted()
                    else:
                        phase = Phase.MENU
                        message = "What will %s do?" % (player_pokemon.pokemon_name if player_pokemon else "you")

        Phase.CATCH_THROW:
            ball_pos += ball_vel * delta
            ball_vel.y += 100.0 * delta  # gravity
            var _vp = get_viewport_rect().size
            var target = Vector2(_vp.x * 0.72, _vp.y * 0.28)
            if ball_pos.distance_to(target) < 35:
                ball_active = false
                _evaluate_catch()
            elif ball_pos.y > _vp.y + 40 or ball_pos.x < -40 or ball_pos.x > _vp.x + 40:
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
                    message = "...".repeat(shake_count + 1)

        Phase.END:
            if message_timer > 0:
                message_timer -= delta
                if message_timer <= 0:
                    EventTracker.log_event("BATTLE_END", {"result": result})
                    battle_ended.emit(result, wild_pokemon)
                    visible = false

    queue_redraw()

# ─── Input handling ───────────────────────────────────────────────────────────
func _input(event):
    if not visible or GameManager.state != GameManager.GameState.BATTLE:
        return

    # Party select overlay input
    if show_party_select and event is InputEventKey and event.pressed:
        get_viewport().set_input_as_handled()
        if event.keycode == KEY_ESCAPE:
            show_party_select = false
            message = "What will %s do?" % (player_pokemon.pokemon_name if player_pokemon else "you")
        elif event.keycode >= KEY_1 and event.keycode <= KEY_6:
            var idx = event.keycode - KEY_1
            if idx < party_ref.size() and party_ref[idx] != player_pokemon and party_ref[idx].hp > 0:
                _switch_pokemon(idx)
        return
    if show_party_select and event is InputEventMouseButton and event.pressed:
        get_viewport().set_input_as_handled()
        var vp = get_viewport_rect().size
        var click_pos = get_viewport().get_mouse_position()
        # Party list is drawn vertically, each slot 40px tall starting at y=100
        for i in party_ref.size():
            var slot_rect = Rect2(vp.x * 0.3, 80 + i * 50, vp.x * 0.4, 45)
            if slot_rect.has_point(click_pos) and party_ref[i] != player_pokemon and party_ref[i].hp > 0:
                _switch_pokemon(i)
                return
        # Click outside = cancel
        show_party_select = false
        message = "What will %s do?" % (player_pokemon.pokemon_name if player_pokemon else "you")
        return

    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        get_viewport().set_input_as_handled()
        var pos = get_viewport().get_mouse_position()
        var vp = get_viewport_rect().size
        var w = vp.x
        var h = vp.y
        print("[BATTLE] Click at %s, phase=%d, viewport=%s" % [str(pos), phase, str(vp)])
        EventTracker.log_event("BATTLE_CLICK", {"pos": str(pos), "phase": phase, "viewport": str(vp)})
        match phase:
            Phase.MENU:
                _handle_menu_click(pos, w, h)
            Phase.FIGHT:
                _handle_fight_click(pos, w, h)
            Phase.BAG:
                _handle_bag_click(pos, w, h)
    # Keyboard shortcuts for battle
    elif event is InputEventKey and event.pressed:
        get_viewport().set_input_as_handled()
        if phase == Phase.MENU:
            if event.keycode == KEY_1 or event.keycode == KEY_F:
                _handle_menu_action("fight")
            elif event.keycode == KEY_2 or event.keycode == KEY_B:
                _handle_menu_action("bag")
            elif event.keycode == KEY_3:
                _handle_menu_action("pokemon")
            elif event.keycode == KEY_4 or event.keycode == KEY_R:
                _handle_menu_action("run")
        elif phase == Phase.FIGHT:
            if event.keycode == KEY_ESCAPE or event.keycode == KEY_BACKSPACE:
                phase = Phase.MENU
                message = "What will %s do?" % (player_pokemon.pokemon_name if player_pokemon else "you")
            elif event.keycode == KEY_F:
                # F again in FIGHT phase = use first move
                if player_pokemon and player_pokemon.known_moves.size() > 0:
                    print("[BATTLE] F key → auto-use move 0")
                    _player_attack_move(0)
            elif event.keycode >= KEY_1 and event.keycode <= KEY_4:
                var idx = event.keycode - KEY_1
                if player_pokemon and idx < player_pokemon.known_moves.size():
                    print("[BATTLE] Key %d → use move %d" % [idx + 1, idx])
                    _player_attack_move(idx)
        elif phase == Phase.BAG:
            if event.keycode == KEY_ESCAPE or event.keycode == KEY_BACKSPACE:
                phase = Phase.MENU
                message = "What will %s do?" % (player_pokemon.pokemon_name if player_pokemon else "you")

func _handle_menu_action(action: String):
    print("[BATTLE] Menu action: %s, player_pokemon=%s, moves=%d" % [
        action,
        player_pokemon.pokemon_name if player_pokemon else "NULL",
        player_pokemon.known_moves.size() if player_pokemon else 0])
    EventTracker.log_event("BATTLE_ACTION", {"action": action, "phase": phase})
    match action:
        "fight":
            if player_pokemon and player_pokemon.known_moves.size() > 0:
                phase = Phase.FIGHT
                message = "Choose a move! (Press 1-%d or click)" % player_pokemon.known_moves.size()
                print("[BATTLE] Phase → FIGHT. %d moves available." % player_pokemon.known_moves.size())
            else:
                print("[BATTLE] No moves! Using fallback attack.")
                _player_attack_move(-1)
        "bag":
            if is_trainer_battle:
                message = "Can't catch trainer Pokemon!"
            elif wild_pokemon and wild_pokemon.hp > wild_pokemon.max_hp / 2:
                message = "The wild Pokemon is too healthy! Weaken it first!"
            elif not inventory or inventory.total_balls() <= 0:
                message = "No Pokeballs left!"
            else:
                phase = Phase.BAG
                message = "Choose a ball!"
        "pokemon":
            if party_ref.size() <= 1:
                message = "No other Pokemon to switch to!"
            else:
                show_party_select = true
                phase = Phase.MENU  # stays in menu but shows party overlay
                message = "Choose a Pokemon! (1-%d or click)" % party_ref.size()
        "run":
            _flee()

# ─── Menu button layout helpers ───────────────────────────────────────────────
func _main_button_rects(w: float, h: float) -> Array:
    var bottom_y = h * 0.78
    var btn_area_x = w * 0.52
    var btn_area_y = bottom_y + 8
    var btn_w = w * 0.22
    var btn_h = (h - bottom_y - 24) / 2.0
    var gap = 6.0
    var actions = ["fight", "bag", "pokemon", "run"]
    var result = []
    for i in 4:
        var col = i % 2
        var row = i / 2
        var bx = btn_area_x + col * (btn_w + gap)
        var by = btn_area_y + row * (btn_h + gap)
        result.append({"label": actions[i].to_upper(), "rect": Rect2(bx, by, btn_w, btn_h), "action": actions[i], "color": Color.WHITE})
    return result

func _move_button_rects(w: float, h: float) -> Array:
    var bottom_y = h * 0.78
    var btn_area_x = w * 0.02
    var btn_area_y = bottom_y + 8
    var btn_w = w * 0.46
    var btn_h = (h - bottom_y - 24) / 2.0
    var gap = 6.0
    var rects = []
    for i in 4:
        var col = i % 2
        var row = i / 2
        rects.append(Rect2(btn_area_x + col * (btn_w + gap), btn_area_y + row * (btn_h + gap), btn_w, btn_h))
    return rects

func _ball_button_rects(w: float, h: float) -> Array:
    var balls_list = [
        {"key": "pokeball",   "label": "Pokeball",    "color": Color("#e53935")},
        {"key": "greatball",  "label": "Great Ball",   "color": Color("#2196f3")},
        {"key": "ultraball",  "label": "Ultra Ball",   "color": Color("#ffd700")},
        {"key": "masterball", "label": "Master Ball",  "color": Color("#ab47bc")},
    ]
    var bottom_y = h * 0.78
    var btn_area_x = w * 0.02
    var btn_area_y = bottom_y + 8
    var btn_w = w * 0.46
    var btn_h = (h - bottom_y - 24) / 2.0
    var gap = 6.0
    var result_list = []
    for i in 4:
        var col = i % 2
        var row = i / 2
        balls_list[i]["rect"] = Rect2(btn_area_x + col * (btn_w + gap), btn_area_y + row * (btn_h + gap), btn_w, btn_h)
        result_list.append(balls_list[i])
    return result_list

# ─── Click handlers ───────────────────────────────────────────────────────────
func _handle_menu_click(pos: Vector2, w: float, h: float):
    for btn in _main_button_rects(w, h):
        if btn["rect"].has_point(pos):
            _handle_menu_action(btn["action"])
            return

func _handle_fight_click(pos: Vector2, w: float, h: float):
    # Back button
    var vp = get_viewport_rect().size
    var back_rect = Rect2(vp.x - 100, vp.y * 0.78 + 8, 90, 34)
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
    var vp = get_viewport_rect().size
    var back_rect = Rect2(vp.x - 100, vp.y * 0.78 + 8, 90, 34)
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
    print("[BATTLE] _player_attack_move(%d) — %s HP:%d/%d" % [
        move_index, player_pokemon.pokemon_name if player_pokemon else "NULL",
        player_pokemon.hp if player_pokemon else 0,
        player_pokemon.max_hp if player_pokemon else 0])
    EventTracker.log_event("PLAYER_ATTACK", {"move_index": move_index, "player_hp": player_pokemon.hp if player_pokemon else 0, "wild_hp": wild_pokemon.hp if wild_pokemon else 0})
    phase = Phase.PLAYER_ATK
    selected_move_index = move_index
    if player_pokemon == null:
        _wild_attack()
        return

    # Status blocks/modifies player attack
    if player_pokemon.status == "frozen":
        if randf() < 0.2:
            player_pokemon.status = ""
            message = "%s thawed out!" % player_pokemon.pokemon_name
            message_timer = 1.2
        else:
            message = "%s is frozen solid!" % player_pokemon.pokemon_name
            message_timer = 1.2
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
        # Ability: Overgrow/Blaze/Torrent (+50% same-type when HP < 33%)
        if player_pokemon.ability in ["Overgrow", "Blaze", "Torrent"]:
            var ability_type = {"Overgrow": "grass", "Blaze": "fire", "Torrent": "water"}.get(player_pokemon.ability, "")
            if move.get("type", "") == ability_type and player_pokemon.hp < player_pokemon.max_hp / 3:
                dmg_data["damage"] = int(dmg_data["damage"] * 1.5)
        # Ability: Levitate (wild immune to Ground moves)
        if wild_pokemon.ability == "Levitate" and move.get("type", "") == "ground":
            dmg_data["damage"] = 0
            dmg_data["text"] = "Levitate — no effect!"
        # Ability: Lightning Rod (wild immune to Electric moves)
        if wild_pokemon.ability == "Lightning Rod" and move.get("type", "") == "electric":
            dmg_data["damage"] = 0
            dmg_data["text"] = "Lightning Rod — immune!"
        # Ability: Sturdy (wild survives OHKO with 1 HP)
        if wild_pokemon.ability == "Sturdy" and wild_pokemon.hp > 1 and dmg_data["damage"] >= wild_pokemon.hp and dmg_data["damage"] < wild_pokemon.max_hp:
            dmg_data["damage"] = wild_pokemon.hp - 1
            dmg_data["text"] = (dmg_data["text"] + " Sturdy kept it standing!").strip_edges()
        wild_pokemon.hp = maxi(0, wild_pokemon.hp - dmg_data["damage"])
        EventTracker.log_event("DAMAGE_DEALT", {"target": "wild", "damage": dmg_data["damage"], "remaining_hp": wild_pokemon.hp, "move": dmg_data.get("move_name", ""), "effectiveness": dmg_data.get("text", "")})
        wild_shake = 1.0
        wild_flash = 1.0
        # Trigger move animation
        move_anim_name = move.get("name", "Attack")
        move_anim_type = move.get("type", "normal")
        move_anim_target = "wild"
        move_anim_timer = 1.2
        _spawn_move_particles(move_anim_type, "wild")
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
        EventTracker.log_event("DAMAGE_DEALT", {"target": "wild", "damage": dmg_data["damage"], "remaining_hp": wild_pokemon.hp, "move": dmg_data.get("move_name", ""), "effectiveness": dmg_data.get("text", "")})
        wild_shake = 1.0
        wild_flash = 1.0
        # Trigger move animation
        move_anim_name = "Attack"
        move_anim_type = "normal"
        move_anim_target = "wild"
        move_anim_timer = 1.2
        _spawn_move_particles(move_anim_type, "wild")
        var eff_text = (" " + dmg_data["text"]) if dmg_data["text"] != "" else ""
        message = "%s attacks! %d dmg.%s" % [player_pokemon.pokemon_name, dmg_data["damage"], eff_text]

    _apply_end_of_turn_effects()
    message_timer = 1.5

func _wild_attack():
    phase = Phase.WILD_ATK
    if wild_pokemon.status == "sleep":
        message = "%s is fast asleep..." % wild_pokemon.pokemon_name
        message_timer = 1.2
        return
    if wild_pokemon.status == "frozen":
        if randf() < 0.2:
            wild_pokemon.status = ""
            message = "%s thawed out!" % wild_pokemon.pokemon_name
        else:
            message = "%s is frozen solid!" % wild_pokemon.pokemon_name
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
    # Burn reduces physical damage by 50%
    if wild_pokemon.status == "burned" and dmg_data.get("category", "") == "physical":
        dmg_data["damage"] = int(dmg_data["damage"] * 0.5)
    player_pokemon.hp = maxi(0, player_pokemon.hp - dmg_data["damage"])
    EventTracker.log_event("DAMAGE_DEALT", {"target": "player", "damage": dmg_data["damage"], "remaining_hp": player_pokemon.hp, "move": dmg_data.get("move_name", "")})
    player_shake = 1.0
    player_flash = 1.0
    var mname = dmg_data.get("move_name", "")
    # Trigger move animation
    move_anim_name = mname if mname != "" else "Attack"
    move_anim_type = dmg_data.get("move_type", wild_pokemon.type) if dmg_data.has("move_type") else wild_pokemon.type
    move_anim_target = "player"
    move_anim_timer = 1.2
    _spawn_move_particles(move_anim_type, "player")
    var eff_text = (" " + dmg_data["text"]) if dmg_data["text"] != "" else ""
    if mname != "" and dmg_data["damage"] > 0:
        message = "%s used %s! %d dmg.%s" % [wild_pokemon.pokemon_name, mname, dmg_data["damage"], eff_text]
    elif dmg_data["damage"] > 0:
        message = "%s attacks! %d dmg.%s" % [wild_pokemon.pokemon_name, dmg_data["damage"], eff_text]
    else:
        message = "%s used %s!%s" % [wild_pokemon.pokemon_name, mname if mname != "" else "an attack", eff_text]
    # Ability: Static (30% paralyze attacker on contact)
    if player_pokemon.ability == "Static" and dmg_data["damage"] > 0 and randf() < 0.3 and wild_pokemon.status == "":
        wild_pokemon.status = "paralyzed"
        message += " Static paralyzed the attacker!"
    # Ability: Poison Point (30% poison attacker on contact)
    if player_pokemon.ability == "Poison Point" and dmg_data["damage"] > 0 and randf() < 0.3 and wild_pokemon.status == "":
        wild_pokemon.status = "poisoned"
        message += " Poison Point poisoned the attacker!"
    message_timer = 1.5

func _apply_end_of_turn_effects():
    # Poison chip damage at end of turn (1/8 max HP)
    if wild_pokemon and wild_pokemon.status == "poisoned" and wild_pokemon.is_alive():
        var chip = maxi(1, wild_pokemon.max_hp / 8)
        wild_pokemon.hp = maxi(0, wild_pokemon.hp - chip)
        wild_flash = 0.5
    if player_pokemon and player_pokemon.status == "poisoned" and player_pokemon.is_alive():
        var chip = maxi(1, player_pokemon.max_hp / 8)
        player_pokemon.hp = maxi(0, player_pokemon.hp - chip)
        player_flash = 0.5
    # Burn chip damage at end of turn (1/16 max HP)
    if wild_pokemon and wild_pokemon.status == "burned" and wild_pokemon.is_alive():
        var chip = maxi(1, wild_pokemon.max_hp / 16)
        wild_pokemon.hp = maxi(0, wild_pokemon.hp - chip)
        wild_flash = 0.5
    if player_pokemon and player_pokemon.status == "burned" and player_pokemon.is_alive():
        var chip = maxi(1, player_pokemon.max_hp / 16)
        player_pokemon.hp = maxi(0, player_pokemon.hp - chip)
        player_flash = 0.5
    # Ability: Shed Skin (33% chance to cure status each turn)
    if player_pokemon and player_pokemon.ability == "Shed Skin" and player_pokemon.status != "" and randf() < 0.33:
        player_pokemon.status = ""
    if wild_pokemon and wild_pokemon.ability == "Shed Skin" and wild_pokemon.status != "" and randf() < 0.33:
        wild_pokemon.status = ""
    # Ability: Bad Dreams (sleeping opponent loses 1/8 HP per turn)
    if player_pokemon and wild_pokemon and wild_pokemon.ability == "Bad Dreams" and player_pokemon.status == "sleep" and player_pokemon.is_alive():
        var bd_dmg = maxi(1, player_pokemon.max_hp / 8)
        player_pokemon.hp = maxi(0, player_pokemon.hp - bd_dmg)
        player_flash = 0.5
    if player_pokemon and wild_pokemon and player_pokemon.ability == "Bad Dreams" and wild_pokemon.status == "sleep" and wild_pokemon.is_alive():
        var bd_dmg = maxi(1, wild_pokemon.max_hp / 8)
        wild_pokemon.hp = maxi(0, wild_pokemon.hp - bd_dmg)
        wild_flash = 0.5

func _on_wild_fainted():
    var xp_gain = wild_pokemon.level * 10
    leveled_up = player_pokemon.gain_xp(xp_gain) if player_pokemon else false
    EventTracker.log_event("WILD_FAINTED", {"name": wild_pokemon.pokemon_name, "xp_gained": xp_gain, "leveled_up": leveled_up})

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
    EventTracker.log_event("PLAYER_FAINTED", {"name": player_pokemon.pokemon_name})
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
    var _throw_vp = get_viewport_rect().size
    ball_pos = Vector2(_throw_vp.x * 0.22, _throw_vp.y * 0.6)
    var target = Vector2(_throw_vp.x * 0.72, _throw_vp.y * 0.28)
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

    EventTracker.log_event("CATCH_ATTEMPT", {"ball": ball_type_used, "catch_value": catch_value, "shakes": shakes, "wild_hp": wild_pokemon.hp, "max_hp": wild_pokemon.max_hp, "status": wild_pokemon.status})
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

func _switch_pokemon(index: int):
    show_party_select = false
    var old_name = player_pokemon.pokemon_name if player_pokemon else "???"
    player_pokemon = party_ref[index]
    player_sprite = PokemonDB.get_sprite_texture(player_pokemon.id)
    message = "Come back %s! Go, %s!" % [old_name, player_pokemon.pokemon_name]
    phase = Phase.PLAYER_ATK  # switching costs a turn - wild attacks after
    message_timer = 1.5
    EventTracker.log_event("POKEMON_SWITCH", {"to": player_pokemon.pokemon_name, "index": index})

func _flee():
    EventTracker.log_event("BATTLE_FLEE", {})
    phase = Phase.END
    result = "fled"
    message = "Got away safely!"
    message_timer = 1.0

func _spawn_move_particles(move_type: String, target: String):
    var vp = get_viewport_rect().size
    var cx = vp.x * 0.72 if target == "wild" else vp.x * 0.22
    var cy = vp.y * 0.28 if target == "wild" else vp.y * 0.52
    var color = TYPE_COLORS.get(move_type, Color.WHITE)

    for i in 15:
        var angle = randf() * TAU
        var speed = randf_range(30, 80)
        move_particles.append({
            "x": cx, "y": cy,
            "vx": cos(angle) * speed,
            "vy": sin(angle) * speed - 20,
            "life": 0.8,
            "max_life": 0.8,
            "color": color,
            "size": randf_range(3, 8),
        })

# ─── Draw ─────────────────────────────────────────────────────────────────────
func _draw():
    if not visible:
        return
    var vp = get_viewport_rect().size
    var w = vp.x
    var h = vp.y

    # === LEAFGREEN BACKGROUND ===
    # Sky gradient (light green → cyan at top)
    for i in 10:
        var t = float(i) / 10.0
        var sky_color = Color(0.55 + t * 0.15, 0.85 - t * 0.1, 0.45 + t * 0.25)
        draw_rect(Rect2(0, i * h * 0.05, w, h * 0.05 + 1), sky_color)

    # Ground (green gradient bottom half)
    for i in 10:
        var t = float(i) / 10.0
        var ground_color = Color(0.35 + t * 0.15, 0.6 - t * 0.15, 0.2 + t * 0.05)
        draw_rect(Rect2(0, h * 0.5 + i * h * 0.05, w, h * 0.05 + 1), ground_color)

    # === GRASS PLATFORMS ===
    # Enemy platform (top-right)
    _draw_grass_platform(Vector2(w * 0.7, h * 0.42), w * 0.3, 16)
    # Player platform (bottom-left)
    _draw_grass_platform(Vector2(w * 0.25, h * 0.68), w * 0.35, 20)

    # === ENEMY POKEMON (top-right, on platform) ===
    var enemy_x = w * 0.7
    var enemy_y = h * 0.28
    if wild_pokemon:
        var shake_x = sin(wild_shake * 20.0) * wild_shake * 12.0
        var wobble = 0.0
        if phase == Phase.CATCH_SHAKE and shake_count > 0:
            wobble = sin(Time.get_ticks_msec() * 0.04) * 8.0
        var spr_size = w * 0.18
        if wild_sprite:
            draw_texture_rect(wild_sprite,
                Rect2(enemy_x - spr_size/2 + shake_x + wobble, enemy_y - spr_size + 10, spr_size, spr_size), false)
        else:
            draw_circle(Vector2(enemy_x + shake_x + wobble, enemy_y - spr_size * 0.3), spr_size * 0.4, wild_pokemon.color)
            draw_arc(Vector2(enemy_x + shake_x + wobble, enemy_y - spr_size * 0.3), spr_size * 0.4, 0, TAU, 16, Color.WHITE, 2.0)
        # Flash overlay
        if wild_flash > 0:
            draw_circle(Vector2(enemy_x + shake_x, enemy_y - spr_size * 0.3), spr_size * 0.45, Color(1, 1, 1, wild_flash * 0.4))

    # === PLAYER POKEMON (bottom-left, on platform, shown from behind = larger) ===
    var player_x = w * 0.25
    var player_y = h * 0.55
    if player_pokemon:
        var shake_x = sin(player_shake * 20.0) * player_shake * 12.0
        var spr_size = w * 0.22
        if player_sprite:
            draw_texture_rect(player_sprite,
                Rect2(player_x - spr_size/2 + shake_x, player_y - spr_size + 15, spr_size, spr_size), false)
        else:
            draw_circle(Vector2(player_x + shake_x, player_y - spr_size * 0.25), spr_size * 0.45, player_pokemon.color)
            draw_arc(Vector2(player_x + shake_x, player_y - spr_size * 0.25), spr_size * 0.45, 0, TAU, 16, Color.WHITE, 2.0)
        if player_flash > 0:
            draw_circle(Vector2(player_x + shake_x, player_y - spr_size * 0.25), spr_size * 0.5, Color(1, 0.3, 0.3, player_flash * 0.4))

    # === ENEMY INFO PANEL (top-left) ===
    if wild_pokemon:
        _draw_info_panel_leafgreen(Vector2(w * 0.02, h * 0.03), w * 0.45, wild_pokemon, true)
        if is_trainer_battle and trainer_name != "":
            draw_string(ThemeDB.fallback_font, Vector2(w * 0.02, h * 0.02),
                trainer_name, HORIZONTAL_ALIGNMENT_LEFT, w * 0.45, 11, Color("#ffd700"))

    # === PLAYER INFO PANEL (bottom-right, above buttons) ===
    if player_pokemon:
        _draw_info_panel_leafgreen(Vector2(w * 0.5, h * 0.6), w * 0.48, player_pokemon, false)

    # === POKEBALL (during throw) ===
    if phase == Phase.CATCH_THROW and ball_active:
        _draw_pokeball(ball_pos, 14.0, ball_type_used)
    elif phase == Phase.CATCH_SHAKE:
        var wobble = sin(Time.get_ticks_msec() * 0.04) * 8.0 if shake_count > 0 else 0.0
        _draw_pokeball(Vector2(enemy_x + wobble, enemy_y - 30), 14.0, ball_type_used)

    # === MOVE ANIMATION ===
    if move_anim_timer > 0:
        var alpha = minf(move_anim_timer / 0.5, 1.0)
        var mc = TYPE_COLORS.get(move_anim_type, Color.WHITE)
        mc.a = alpha
        var tx = w * 0.55 if move_anim_target == "wild" else w * 0.1
        var ty = h * 0.2 if move_anim_target == "wild" else h * 0.4
        draw_string(ThemeDB.fallback_font, Vector2(tx, ty), move_anim_name, HORIZONTAL_ALIGNMENT_LEFT, 120, 18, mc)
    for p in move_particles:
        var alpha = p["life"] / p["max_life"]
        var c = p["color"]
        c.a = alpha
        draw_circle(Vector2(p["x"], p["y"]), p["size"] * alpha, c)

    # === BOTTOM SECTION: MESSAGE + BUTTONS ===
    # Dark bottom bar
    var bottom_y = h * 0.78
    var bottom_h = h - bottom_y
    draw_rect(Rect2(0, bottom_y, w, bottom_h), Color(0.08, 0.1, 0.15))
    draw_line(Vector2(0, bottom_y), Vector2(w, bottom_y), Color(0.2, 0.25, 0.35), 2.0)

    # Message box (left half)
    var msg_x = w * 0.02
    var msg_y = bottom_y + 8
    var msg_w = w * 0.48
    var msg_h = bottom_h - 16
    draw_rect(Rect2(msg_x, msg_y, msg_w, msg_h), Color(0.12, 0.16, 0.22))
    draw_rect(Rect2(msg_x, msg_y, msg_w, msg_h), Color("#4fc3f7"), false, 2.0)
    # Message text
    draw_string(ThemeDB.fallback_font, Vector2(msg_x + 14, msg_y + msg_h * 0.45),
        message, HORIZONTAL_ALIGNMENT_LEFT, msg_w - 28, 14, Color("#e8e8e8"))

    # === PHASE-SPECIFIC BUTTONS (right half) ===
    match phase:
        Phase.MENU:
            _draw_main_menu_leafgreen(w, h, bottom_y)
        Phase.FIGHT:
            _draw_move_menu_leafgreen(w, h, bottom_y)
        Phase.BAG:
            _draw_bag_menu_leafgreen(w, h, bottom_y)

    # Party select overlay
    if show_party_select:
        var vp_w = get_viewport_rect().size.x
        var vp_h = get_viewport_rect().size.y
        draw_rect(Rect2(0, 0, vp_w, vp_h), Color(0, 0, 0, 0.6))
        draw_string(ThemeDB.fallback_font, Vector2(vp_w * 0.35, 60), "Choose Pokemon:", HORIZONTAL_ALIGNMENT_LEFT, vp_w * 0.3, 16, Color("#4fc3f7"))
        for i in party_ref.size():
            var pkmn = party_ref[i]
            var slot_y = 80 + i * 50
            var is_current = (pkmn == player_pokemon)
            var is_fainted = pkmn.hp <= 0
            var bg = Color(0.1, 0.15, 0.25) if not is_current else Color(0.15, 0.25, 0.15)
            if is_fainted: bg = Color(0.2, 0.1, 0.1)
            draw_rect(Rect2(vp_w * 0.3, slot_y, vp_w * 0.4, 45), bg)
            draw_rect(Rect2(vp_w * 0.3, slot_y, vp_w * 0.4, 45), Color("#4fc3f7") if not is_fainted else Color("#666"), false, 1.5)
            # Sprite
            var tex = PokemonDB.get_sprite_texture(pkmn.id)
            if tex:
                draw_texture_rect(tex, Rect2(vp_w * 0.31, slot_y + 2, 40, 40), false)
            # Name + HP
            var label = "%d. %s  Lv.%d  HP:%d/%d" % [i + 1, pkmn.pokemon_name, pkmn.level, pkmn.hp, pkmn.max_hp]
            if is_current: label += " (current)"
            if is_fainted: label += " (fainted)"
            draw_string(ThemeDB.fallback_font, Vector2(vp_w * 0.31 + 45, slot_y + 28), label, HORIZONTAL_ALIGNMENT_LEFT, vp_w * 0.35, 12, Color.WHITE if not is_fainted else Color("#666"))
        draw_string(ThemeDB.fallback_font, Vector2(vp_w * 0.35, 80 + party_ref.size() * 50 + 20), "Press ESC to cancel", HORIZONTAL_ALIGNMENT_LEFT, vp_w * 0.3, 11, Color("#888"))

func _draw_grass_platform(center: Vector2, width: float, height: float):
    # Draw a green grass ellipse (like LeafGreen)
    var points: PackedVector2Array = []
    for i in 24:
        var angle = float(i) / 24.0 * TAU
        points.append(center + Vector2(cos(angle) * width * 0.5, sin(angle) * height * 0.5))
    draw_colored_polygon(points, Color(0.35, 0.55, 0.25, 0.8))
    # Grass edge highlight
    draw_arc(center, width * 0.5, 0, PI, 24, Color(0.45, 0.65, 0.3), 2.0)
    # Grass texture lines
    for i in 5:
        var gx = center.x - width * 0.3 + i * width * 0.15
        draw_line(Vector2(gx, center.y), Vector2(gx + 3, center.y - 6), Color(0.3, 0.5, 0.2, 0.5), 1.5)

func _draw_info_panel_leafgreen(pos: Vector2, width: float, pkmn, is_enemy: bool):
    var panel_h = 56.0
    # Panel background (grey like LeafGreen)
    draw_rect(Rect2(pos.x, pos.y, width, panel_h), Color(0.15, 0.18, 0.25, 0.95))
    draw_rect(Rect2(pos.x, pos.y, width, panel_h), Color("#4fc3f7"), false, 2.0)

    # Name + Level
    draw_string(ThemeDB.fallback_font, Vector2(pos.x + 10, pos.y + 20),
        pkmn.pokemon_name, HORIZONTAL_ALIGNMENT_LEFT, width * 0.5, 15, Color.WHITE)
    draw_string(ThemeDB.fallback_font, Vector2(pos.x + width - 80, pos.y + 20),
        "Lv.%d" % pkmn.level, HORIZONTAL_ALIGNMENT_LEFT, 70, 13, Color("#ccc"))

    # Status icon
    var status_txt = ""
    var status_col = Color.WHITE
    match pkmn.status:
        "sleep": status_txt = "SLP"; status_col = Color("#9c27b0")
        "paralyzed": status_txt = "PAR"; status_col = Color("#ffd600")
        "poisoned": status_txt = "PSN"; status_col = Color("#ab47bc")
    if status_txt != "":
        draw_string(ThemeDB.fallback_font, Vector2(pos.x + width * 0.45, pos.y + 20),
            status_txt, HORIZONTAL_ALIGNMENT_LEFT, 40, 11, status_col)

    # HP label
    draw_string(ThemeDB.fallback_font, Vector2(pos.x + 10, pos.y + 36),
        "HP", HORIZONTAL_ALIGNMENT_LEFT, 24, 11, Color("#ffd700"))

    # HP bar
    var bar_x = pos.x + 34
    var bar_y = pos.y + 28
    var bar_w = width - 44
    draw_rect(Rect2(bar_x, bar_y, bar_w, 10), Color("#333"))
    var ratio = float(pkmn.hp) / float(pkmn.max_hp)
    var bar_color = Color("#4caf50") if ratio > 0.5 else (Color("#ff9800") if ratio > 0.25 else Color("#f44336"))
    draw_rect(Rect2(bar_x, bar_y, bar_w * ratio, 10), bar_color)

    # HP numbers (only on player's panel)
    if not is_enemy:
        draw_string(ThemeDB.fallback_font, Vector2(pos.x + width - 90, pos.y + 50),
            "%d/%d" % [pkmn.hp, pkmn.max_hp], HORIZONTAL_ALIGNMENT_RIGHT, 80, 12, Color("#ccc"))

func _draw_main_menu_leafgreen(w: float, h: float, bottom_y: float):
    # 2x2 grid: FIGHT | BAG / POKEMON | RUN
    var btn_area_x = w * 0.52
    var btn_area_y = bottom_y + 8
    var btn_w = w * 0.22
    var btn_h = (h - bottom_y - 24) / 2.0
    var gap = 6.0

    var buttons = [
        {"label": "FIGHT",   "color": Color(0.85, 0.45, 0.5),  "action": "fight"},
        {"label": "BAG",     "color": Color(0.85, 0.65, 0.35), "action": "bag"},
        {"label": "POKEMON", "color": Color(0.4, 0.7, 0.45),   "action": "pokemon"},
        {"label": "RUN",     "color": Color(0.35, 0.5, 0.8),   "action": "run"},
    ]
    for i in 4:
        var col = i % 2
        var row = i / 2
        var bx = btn_area_x + col * (btn_w + gap)
        var by = btn_area_y + row * (btn_h + gap)
        var btn = buttons[i]
        var bg_color = btn["color"]
        # Grey out BAG during trainer battle
        if is_trainer_battle and btn["action"] == "bag":
            bg_color = Color(0.3, 0.3, 0.3)
        draw_rect(Rect2(bx, by, btn_w, btn_h), bg_color)
        draw_rect(Rect2(bx, by, btn_w, btn_h), bg_color.lightened(0.3), false, 2.0)
        # Label centered
        draw_string(ThemeDB.fallback_font, Vector2(bx + 8, by + btn_h * 0.65),
            btn["label"], HORIZONTAL_ALIGNMENT_LEFT, btn_w - 16, 15, Color.WHITE)

func _draw_move_menu_leafgreen(w: float, h: float, bottom_y: float):
    if not player_pokemon:
        return
    var moves = player_pokemon.known_moves
    var btn_area_x = w * 0.02
    var btn_area_y = bottom_y + 8
    var btn_w = w * 0.46
    var btn_h = (h - bottom_y - 24) / 2.0
    var gap = 6.0

    for i in mini(moves.size(), 4):
        var col = i % 2
        var row = i / 2
        var bx = btn_area_x + col * (btn_w + gap)
        var by = btn_area_y + row * (btn_h + gap)
        var mv = moves[i]
        var tc = TYPE_COLORS.get(mv.get("type", "normal"), Color("#aaa"))
        draw_rect(Rect2(bx, by, btn_w, btn_h), Color(0.1, 0.12, 0.18))
        draw_rect(Rect2(bx, by, btn_w, btn_h), tc, false, 2.0)
        # Move name
        var mname = mv.get("name", "???")
        draw_string(ThemeDB.fallback_font, Vector2(bx + 8, by + btn_h * 0.5),
            mname, HORIZONTAL_ALIGNMENT_LEFT, btn_w * 0.6, 13, Color.WHITE)
        # PP
        var pp_str = "PP %d/%d" % [mv.get("current_pp", 0), mv.get("pp", 0)]
        var pp_col = Color("#f44") if mv.get("current_pp", 0) == 0 else Color("#aaa")
        draw_string(ThemeDB.fallback_font, Vector2(bx + btn_w - 75, by + btn_h * 0.5),
            pp_str, HORIZONTAL_ALIGNMENT_LEFT, 70, 11, pp_col)
        # Type label
        draw_string(ThemeDB.fallback_font, Vector2(bx + 8, by + btn_h * 0.85),
            mv.get("type", "").to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 60, 9, tc)

    # Back button (far right)
    _draw_back_btn(w, h, bottom_y)

func _draw_bag_menu_leafgreen(w: float, h: float, bottom_y: float):
    var balls_info = [
        {"key": "pokeball",   "label": "Pokeball",    "color": Color("#e53935")},
        {"key": "greatball",  "label": "Great Ball",   "color": Color("#2196f3")},
        {"key": "ultraball",  "label": "Ultra Ball",   "color": Color("#ffd700")},
        {"key": "masterball", "label": "Master Ball",  "color": Color("#ab47bc")},
    ]
    var btn_area_x = w * 0.02
    var btn_area_y = bottom_y + 8
    var btn_w = w * 0.46
    var btn_h = (h - bottom_y - 24) / 2.0
    var gap = 6.0

    for i in 4:
        var col = i % 2
        var row = i / 2
        var bx = btn_area_x + col * (btn_w + gap)
        var by = btn_area_y + row * (btn_h + gap)
        var bi = balls_info[i]
        var count = inventory.balls.get(bi["key"], 0) if inventory else 0
        var col_v = bi["color"] if count > 0 else Color("#555")
        draw_rect(Rect2(bx, by, btn_w, btn_h), Color(0.1, 0.12, 0.18))
        draw_rect(Rect2(bx, by, btn_w, btn_h), col_v, false, 2.0)
        draw_string(ThemeDB.fallback_font, Vector2(bx + 8, by + btn_h * 0.65),
            "%s  x%d" % [bi["label"], count], HORIZONTAL_ALIGNMENT_LEFT, btn_w - 16, 13,
            Color.WHITE if count > 0 else Color("#555"))

    _draw_back_btn(w, h, bottom_y)

func _draw_back_btn(w: float, h: float, bottom_y: float):
    var r = Rect2(w - 100, bottom_y + 8, 90, 34)
    draw_rect(r, Color(0.25, 0.2, 0.1))
    draw_rect(r, Color("#ff9800"), false, 2.0)
    draw_string(ThemeDB.fallback_font, Vector2(r.position.x + 12, r.position.y + 23),
        "BACK", HORIZONTAL_ALIGNMENT_LEFT, 66, 14, Color("#ff9800"))

func _draw_pokeball(pos: Vector2, radius: float, ball_key: String = "pokeball"):
    var top_col = Color("#e53935")
    match ball_key:
        "greatball":  top_col = Color("#2196f3")
        "ultraball":  top_col = Color("#ffd700")
        "masterball": top_col = Color("#ab47bc")
    draw_circle(pos + Vector2(0, -2), radius, top_col)
    draw_circle(pos + Vector2(0, 3), radius, Color.WHITE)
    draw_line(pos + Vector2(-radius, 0), pos + Vector2(radius, 0), Color("#333"), 2.5)
    draw_circle(pos, 4.5, Color.WHITE)
    draw_arc(pos, 4.5, 0, TAU, 8, Color("#333"), 2.0)
