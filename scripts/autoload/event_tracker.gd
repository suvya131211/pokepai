extends Node

# AI Event Tracker — logs all game events to a file for debugging
# Read logs at: user://pokepai_events.log
# Clear with: EventTracker.clear_logs()

var log_file: FileAccess = null
var log_path: String = "user://pokepai_events.log"
var session_id: String = ""
var event_count: int = 0

func _ready():
	session_id = Time.get_datetime_string_from_system().replace(":", "-")
	# Append to existing log (don't overwrite)
	if FileAccess.file_exists(log_path):
		log_file = FileAccess.open(log_path, FileAccess.READ_WRITE)
		log_file.seek_end()
	else:
		log_file = FileAccess.open(log_path, FileAccess.WRITE)

	_log("SESSION_START", {"session": session_id, "time": Time.get_datetime_string_from_system()})

	# Connect to GameManager signals
	GameManager.state_changed.connect(func(s): _log("STATE_CHANGE", {"to": str(s), "state_name": _state_name(s)}))
	GameManager.pokemon_caught.connect(func(p): _log("POKEMON_CAUGHT", {"name": p.pokemon_name, "level": p.level, "id": p.id}))
	GameManager.item_collected.connect(func(t): _log("ITEM_COLLECTED", {"type": t}))

func _process(_delta):
	# Periodic state snapshot every 5 seconds
	if Engine.get_process_frames() % 300 == 0 and GameManager.state == GameManager.GameState.WORLD:
		var player = get_tree().get_first_node_in_group("player") if get_tree().has_group("player") else null
		_log("HEARTBEAT", {
			"state": _state_name(GameManager.state),
			"party_size": GameManager.party.size(),
			"party_hp": _party_hp_summary(),
			"time": GameManager.game_time,
			"weather": GameManager.weather,
		})

func log_event(category: String, data: Dictionary = {}):
	_log(category, data)

func _log(category: String, data: Dictionary = {}):
	event_count += 1
	var timestamp = "%.2f" % (Time.get_ticks_msec() / 1000.0)
	var line = "[%s] #%d %s: %s" % [timestamp, event_count, category, str(data)]
	if log_file:
		log_file.store_line(line)
		log_file.flush()
	# Also print to console
	print(line)

func _state_name(s) -> String:
	match s:
		GameManager.GameState.WORLD: return "WORLD"
		GameManager.GameState.BATTLE: return "BATTLE"
		GameManager.GameState.CATCH: return "CATCH"
		GameManager.GameState.POKEDEX: return "POKEDEX"
		GameManager.GameState.INVENTORY: return "INVENTORY"
		GameManager.GameState.TOWN_MENU: return "TOWN_MENU"
		GameManager.GameState.PAUSED: return "PAUSED"
	return "UNKNOWN(%s)" % str(s)

func _party_hp_summary() -> String:
	var parts = []
	for p in GameManager.party:
		parts.append("%s:%d/%d" % [p.pokemon_name, p.hp, p.max_hp])
	return ", ".join(parts)

func clear_logs():
	if log_file:
		log_file.close()
	log_file = FileAccess.open(log_path, FileAccess.WRITE)
	_log("LOGS_CLEARED", {})

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_log("SESSION_END", {"total_events": event_count})
		if log_file:
			log_file.close()

func get_log_path() -> String:
	return ProjectSettings.globalize_path(log_path)
