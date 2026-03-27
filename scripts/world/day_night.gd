extends CanvasModulate
class_name DayNightCycle

var time: float = 8.0  # hours (0-24)
var speed: float = 1.0  # 1 game-hour per real second

func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.WORLD:
		return

	time = fmod(time + delta * speed, 24.0)
	GameManager.game_time = time

	# Set phase
	if time >= 5.0 and time < 7.0:
		GameManager.time_of_day = "dawn"
	elif time >= 7.0 and time < 18.0:
		GameManager.time_of_day = "day"
	elif time >= 18.0 and time < 20.0:
		GameManager.time_of_day = "dusk"
	else:
		GameManager.time_of_day = "night"

	# Modulate canvas color
	color = _get_tint()

func _get_tint() -> Color:
	if time >= 7.0 and time < 17.0:
		return Color.WHITE
	elif time >= 17.0 and time < 18.0:
		var t := (time - 17.0)
		return Color.WHITE.lerp(Color(0.9, 0.7, 0.5), t)
	elif time >= 18.0 and time < 20.0:
		var t := (time - 18.0) / 2.0
		return Color(0.9, 0.7, 0.5).lerp(Color(0.3, 0.3, 0.5), t)
	elif time >= 20.0 or time < 5.0:
		return Color(0.2, 0.2, 0.4)
	else:  # dawn 5-7
		var t := (time - 5.0) / 2.0
		return Color(0.2, 0.2, 0.4).lerp(Color.WHITE, t)

func get_time_string() -> String:
	var h := int(time)
	var m := int(fmod(time, 1.0) * 60.0)
	return "%02d:%02d" % [h, m]
