extends Node2D
class_name WeatherSystem

const WEATHER_TYPES := ["clear", "clear", "clear", "rain", "rain", "storm", "snow", "fog"]

var current: String = "clear"
var timer: float = 60.0
var particles: Array = []
const MAX_PARTICLES := 400

var viewport_size: Vector2

func _ready() -> void:
	viewport_size = get_viewport_rect().size
	z_index = 100  # render above world

func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.WORLD:
		return

	timer -= delta
	if timer <= 0:
		current = WEATHER_TYPES[randi() % WEATHER_TYPES.size()]
		timer = randf_range(40.0, 80.0)
		GameManager.weather = current

	viewport_size = get_viewport_rect().size
	_update_particles(delta)
	queue_redraw()

func _update_particles(delta: float) -> void:
	# Spawn
	var rate = {"clear":0, "rain":10, "storm":15, "snow":5, "fog":2}.get(current, 0)
	for i in rate:
		if particles.size() < MAX_PARTICLES:
			particles.append(_new_particle())

	# Update
	for p in particles:
		p["x"] += p["vx"] * delta
		p["y"] += p["vy"] * delta
		p["life"] -= delta

	# Prune
	particles = particles.filter(func(p): return p["life"] > 0 and p["y"] < viewport_size.y + 10)

func _new_particle() -> Dictionary:
	# Particle position is in screen-local coords (camera-independent)
	match current:
		"rain", "storm":
			return {"x": randf() * viewport_size.x, "y": -5.0,
					"vx": -15.0, "vy": randf_range(300, 450),
					"life": 2.0, "type": current}
		"snow":
			return {"x": randf() * viewport_size.x, "y": -5.0,
					"vx": randf_range(-10, 10), "vy": randf_range(30, 60),
					"life": 8.0, "type": "snow"}
		"fog":
			return {"x": randf() * viewport_size.x,
					"y": randf() * viewport_size.y,
					"vx": 5.0, "vy": 0.0, "life": 6.0, "type": "fog"}
	return {"x":0,"y":0,"vx":0,"vy":0,"life":0,"type":""}

func _draw() -> void:
	if current == "clear":
		return
	for p in particles:
		match p["type"]:
			"rain":
				draw_line(Vector2(p["x"], p["y"]),
						  Vector2(p["x"] + p["vx"]*0.02, p["y"] + p["vy"]*0.02),
						  Color(0.5, 0.67, 1.0, 0.5), 1.0)
			"storm":
				draw_line(Vector2(p["x"], p["y"]),
						  Vector2(p["x"] + p["vx"]*0.02, p["y"] + p["vy"]*0.02),
						  Color(0.7, 0.82, 1.0, 0.6), 1.5)
			"snow":
				draw_circle(Vector2(p["x"], p["y"]), 2.0, Color(1, 1, 1, 0.7))
			"fog":
				draw_rect(Rect2(p["x"], p["y"], 60, 20), Color(0.8, 0.8, 0.86, 0.04))
	# Lightning
	if current == "storm" and randf() < 0.002:
		draw_rect(Rect2(0, 0, viewport_size.x, viewport_size.y), Color(1, 1, 0.8, 0.08))
