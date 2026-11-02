extends Node2D
# Syzu - demo level: level, musuh, dekor, checkpoint dibuat lewat kode.

func _ready() -> void:
	_setup_input()
	RenderingServer.set_default_clear_color(Color("#14121c"))
	add_child(preload("res://background.gd").new())
	_build_level()
	var player := preload("res://player.gd").new()
	player.position = Vector2(200, 560)
	add_child(player)
	add_child(preload("res://petals.gd").new())
	add_child(preload("res://touch_controls.gd").new())

func _setup_input() -> void:
	# Keyboard hanya untuk tes di PC. Di HP dipakai joystick dan tombol sentuh.
	var map := {
		"left": [KEY_A, KEY_LEFT],
		"right": [KEY_D, KEY_RIGHT],
		"down": [KEY_S, KEY_DOWN],
		"up": [KEY_Q],
		"jump": [KEY_SPACE, KEY_W, KEY_UP],
		"dash": [KEY_SHIFT, KEY_K],
		"run": [KEY_CTRL, KEY_L],
		"attack": [KEY_J],
		"skill": [KEY_O],
		"ult": [KEY_P],
		"parry": [KEY_I],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)

func _plat(x: float, y: float, w: float, h: float, group: String = "") -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x + w / 2.0, y + h / 2.0)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, h)
	shape.shape = rect
	body.add_child(shape)
	var vis := preload("res://tiles.gd").new()
	vis.size = Vector2(w, h)
	vis.kind = group
	vis.position = -Vector2(w, h) / 2.0
	body.add_child(vis)
	if group != "":
		body.add_to_group(group)
	add_child(body)

func _spawn(kind: String, x: float, y: float) -> void:
	var e := preload("res://enemy.gd").new()
	e.kind = kind
	e.position = Vector2(x, y)
	add_child(e)

func _lamp_sprite() -> Sprite2D:
	var spr := Sprite2D.new()
	spr.texture = load("res://art_lamp.png")
	spr.centered = false
	spr.scale = Vector2(2, 2)
	return spr

func _checkpoint(x: float, y: float) -> void:
	var c := Node2D.new()
	c.position = Vector2(x, y)
	var spr := _lamp_sprite()
	spr.position = Vector2(-16, 30 - 96)
	spr.modulate = Color(0.45, 0.45, 0.6, 1.0)
	c.add_child(spr)
	c.add_to_group("checkpoint")
	add_child(c)

func _decor(path: String, x: float, y_bottom: float, scale: float, glow: bool) -> void:
	var t: Texture2D = load(path)
	var spr := Sprite2D.new()
	spr.texture = t
	spr.centered = false
	spr.scale = Vector2(scale, scale)
	spr.position = Vector2(x - t.get_width() * scale / 2.0, y_bottom - t.get_height() * scale)
	spr.z_index = -2
	if glow:
		var g := Sprite2D.new()
		g.texture = load("res://art_glow.png")
		g.position = Vector2(8.0, 14.0)
		g.scale = Vector2(1.3, 1.3)
		g.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		g.material = m
		spr.add_child(g)
	add_child(spr)

func _build_level() -> void:
	# Dekor (di belakang pemain)
	_decor("res://art_tree.png", 330, 600, 2.0, false)
	_decor("res://art_lamp.png", 90, 600, 2.0, true)
	_decor("res://art_lamp.png", 900, 600, 2.0, true)
	_decor("res://art_lamp.png", 2050, 600, 2.0, true)
	_decor("res://art_lamp.png", 2900, 600, 2.0, true)
	_decor("res://art_lamp.png", 3750, 600, 2.0, true)

	_plat(-240, -800, 40, 1600, "wall")
	# Area 1: latihan + tangga platform
	_plat(-200, 600, 1600, 600)
	_plat(500, 520, 200, 24)
	_plat(760, 440, 200, 24)
	_plat(1020, 360, 200, 24)
	# Jurang, lalu area 2
	_plat(1800, 600, 2440, 600)
	# Poros wall jump (dinding kiri terbuka di bawah)
	_plat(2200, -500, 40, 880, "wall")
	_plat(2440, -500, 40, 1100, "wall")
	# Jalur atas + platform rapuh
	_plat(2480, -500, 700, 40)
	_plat(3180, -300, 160, 24, "fragile")
	_plat(3340, 120, 160, 24)
	_plat(3500, 440, 180, 24, "fragile")
	_plat(4200, -800, 40, 1600, "wall")

	# Musuh
	_spawn("dummy", 450, 540)
	_spawn("fighter", 1000, 540)
	_spawn("shooter", 1120, 320)
	_spawn("fighter", 2000, 540)
	_spawn("fighter", 2100, 540)
	_spawn("shooter", 2800, 540)
	_spawn("heavy", 3000, 540)
	_spawn("fighter", 3100, 540)
	_spawn("extreme", 3250, 540)
	_spawn("extreme", 3800, 540)
	_spawn("boss", 4000, 520)

	# Checkpoint
	_checkpoint(1880, 570)
	_checkpoint(3600, 570)
