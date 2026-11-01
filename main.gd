extends Node2D
# Syzu - Milestone 1+2: foundation + movement prototype.
# Level dan input dibuat lewat kode supaya mudah diedit tanpa editor Godot.

func _ready() -> void:
	_setup_input()
	RenderingServer.set_default_clear_color(Color("#14121c"))
	_build_level()
	var player := preload("res://player.gd").new()
	player.position = Vector2(200, 560)
	add_child(player)
	add_child(preload("res://touch_controls.gd").new())

func _setup_input() -> void:
	# Keyboard hanya untuk tes di PC. Di HP dipakai tombol sentuh.
	var map := {
		"left": [KEY_A, KEY_LEFT],
		"right": [KEY_D, KEY_RIGHT],
		"down": [KEY_S, KEY_DOWN],
		"jump": [KEY_SPACE, KEY_W, KEY_UP],
		"dash": [KEY_SHIFT, KEY_K],
		"run": [KEY_CTRL, KEY_L],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)

func _plat(x: float, y: float, w: float, h: float, group: String = "", color: Color = Color("#3b3550")) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x + w / 2.0, y + h / 2.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, h)
	shape.shape = rect
	body.add_child(shape)
	var vis := ColorRect.new()
	vis.size = Vector2(w, h)
	vis.position = -Vector2(w, h) / 2.0
	vis.color = color
	body.add_child(vis)
	if group != "":
		body.add_to_group(group)
	add_child(body)

func _build_level() -> void:
	var wall_color := Color("#5a4e7a")
	# Tembok batas kiri
	_plat(-240, -800, 40, 1600, "wall", wall_color)
	# Area 1: tanah + tangga platform
	_plat(-200, 600, 1600, 200)
	_plat(500, 520, 200, 24)
	_plat(760, 440, 200, 24)
	_plat(1020, 360, 200, 24)
	# Jurang (butuh dash / double jump)
	# Area 2: tanah
	_plat(1800, 600, 2440, 200)
	# Poros wall jump (dinding kiri terbuka di bawah untuk masuk)
	_plat(2200, -500, 40, 880, "wall", wall_color)
	_plat(2440, -500, 40, 1100, "wall", wall_color)
	# Jalur atas (ledge grab di ujung dinding kanan), lalu platform rapuh
	_plat(2480, -500, 700, 40)
	_plat(3180, -300, 160, 24, "fragile", Color("#c2602a"))
	_plat(3340, 120, 160, 24)
	# Platform rapuh di jalur bawah (hancur kena downward dash)
	_plat(3500, 440, 180, 24, "fragile", Color("#c2602a"))
	# Tembok batas kanan
	_plat(4200, -800, 40, 1600, "wall", wall_color)
