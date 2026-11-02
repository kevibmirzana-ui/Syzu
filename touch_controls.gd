extends CanvasLayer
# Joystick + tombol ikon + HUD (potret, HP, Energy, gem, pause, bar boss).

const VERSION_LABEL := "SYZU DEMO 0.3"
var canvas: Control
var pix: Control
var touches := {}
var buttons := {}
var icons := {}
var portrait: Texture2D
var gem_tex: Texture2D
var stick_index := -1
var stick_c := Vector2.ZERO
var stick_r := 100.0
var stick_vec := Vector2.ZERO
var pause_rect := Rect2()
var paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	canvas.draw.connect(_draw_ui)
	add_child(canvas)
	pix = Control.new()
	pix.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pix.set_anchors_preset(Control.PRESET_FULL_RECT)
	pix.draw.connect(_draw_pix)
	add_child(pix)
	for n in ["sword", "shield", "dash", "jump", "run", "water", "ult"]:
		icons[n] = load("res://art_icon_%s.png" % n)
	portrait = load("res://art_portrait.png")
	gem_tex = load("res://art_gem.png")
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var s := get_viewport().get_visible_rect().size
	stick_c = Vector2(160, s.y - 150)
	# Semua tombol di bawah garis tanah supaya tidak menutupi musuh
	buttons = {
		"attack": {"pos": Vector2(s.x - 130, s.y - 130), "r": 88.0, "icon": "sword"},
		"jump": {"pos": Vector2(s.x - 280, s.y - 60), "r": 54.0, "icon": "jump"},
		"dash": {"pos": Vector2(s.x - 300, s.y - 200), "r": 58.0, "icon": "dash"},
		"parry": {"pos": Vector2(s.x - 440, s.y - 80), "r": 48.0, "icon": "shield"},
		"run": {"pos": Vector2(s.x - 440, s.y - 200), "r": 44.0, "icon": "run"},
		"skill": {"pos": Vector2(s.x - 590, s.y - 70), "r": 50.0, "icon": "water"},
		"ult": {"pos": Vector2(s.x - 590, s.y - 190), "r": 44.0, "icon": "ult"},
	}
	pause_rect = Rect2(s.x - 84, 18, 64, 64)

func _process(_delta: float) -> void:
	canvas.queue_redraw()
	pix.queue_redraw()

func _toggle_pause() -> void:
	paused = not paused
	get_tree().paused = paused
	if paused:
		for i in touches.keys():
			_release(i)
		if stick_index != -1:
			_release(stick_index)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if pause_rect.has_point(event.position):
				_toggle_pause()
				return
			_press(event.index, event.position, true)
		else:
			_release(event.index)
	elif event is InputEventScreenDrag:
		_press(event.index, event.position, false)

func _hit(pos: Vector2) -> String:
	var best := ""
	var best_d := INF
	for a in buttons:
		var b = buttons[a]
		var d: float = pos.distance_to(b["pos"])
		if d <= b["r"] * 1.2 and d < best_d:
			best = a
			best_d = d
	return best

func _set_dir(a: String, on: bool) -> void:
	if on and not Input.is_action_pressed(a):
		Input.action_press(a)
	elif not on and Input.is_action_pressed(a):
		Input.action_release(a)

func _update_stick(pos: Vector2) -> void:
	var v := pos - stick_c
	if v.length() > stick_r:
		v = v.normalized() * stick_r
	stick_vec = v / stick_r
	_set_dir("left", stick_vec.x < -0.35)
	_set_dir("right", stick_vec.x > 0.35)
	_set_dir("up", stick_vec.y < -0.55)
	_set_dir("down", stick_vec.y > 0.55)

func _press(index: int, pos: Vector2, is_new: bool) -> void:
	if paused:
		return
	if index == stick_index:
		_update_stick(pos)
		return
	if is_new and stick_index == -1 and pos.distance_to(stick_c) <= stick_r * 1.6:
		stick_index = index
		_update_stick(pos)
		return
	var a := _hit(pos)
	if touches.get(index, "") == a:
		return
	_release(index)
	if a != "":
		touches[index] = a
		Input.action_press(a)

func _release(index: int) -> void:
	if index == stick_index:
		stick_index = -1
		stick_vec = Vector2.ZERO
		for d in ["left", "right", "up", "down"]:
			_set_dir(d, false)
		return
	if touches.has(index):
		var a: String = touches[index]
		touches.erase(index)
		if not touches.values().has(a):
			Input.action_release(a)

func _para(x: float, y: float, w: float, h: float, slant: float, col: Color) -> void:
	if w < 1.0:
		return
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(x + slant, y), Vector2(x + w + slant, y), Vector2(x + w, y + h), Vector2(x, y + h)]), col)

func _draw_ui() -> void:
	var font := ThemeDB.fallback_font
	var s := get_viewport().get_visible_rect().size
	# Joystick
	canvas.draw_circle(stick_c, stick_r, Color(0.05, 0.03, 0.08, 0.45))
	canvas.draw_arc(stick_c, stick_r, 0.0, TAU, 48, Color(0.92, 0.88, 0.96, 0.6), 3.0)
	for a in [0.0, PI / 2.0, PI, -PI / 2.0]:
		var dir := Vector2(cos(a), sin(a))
		var ap := stick_c + dir * (stick_r - 24.0)
		var aq := dir.orthogonal()
		canvas.draw_colored_polygon(PackedVector2Array([ap + dir * 8.0, ap - dir * 6.0 + aq * 9.0, ap - dir * 6.0 - aq * 9.0]), Color(0.92, 0.88, 0.96, 0.55))
	canvas.draw_circle(stick_c + stick_vec * (stick_r * 0.6), 38.0, Color(0.62, 0.6, 0.7, 0.85))
	# Tombol
	var plr := get_tree().get_first_node_in_group("player")
	for a in buttons:
		var b = buttons[a]
		var pressed := Input.is_action_pressed(a)
		var can_use := true
		if plr:
			if a == "ult":
				can_use = plr.mana >= 67.0 and plr.energy >= 33.0
			elif a == "skill":
				can_use = plr.mana >= 10.0
		canvas.draw_circle(b["pos"], b["r"], Color(0.9, 0.9, 1.0, 0.35) if pressed else Color(0.06, 0.04, 0.1, 0.5))
		if a == "ult" and can_use:
			canvas.draw_arc(b["pos"], b["r"] + 6.0, 0.0, TAU, 40, Color(0.5, 0.85, 1.0, 0.9), 4.0)
		canvas.draw_arc(b["pos"], b["r"], 0.0, TAU, 40, Color(0.92, 0.9, 0.96, 0.75), 3.0)
		var ic: Texture2D = icons[b["icon"]]
		var isz: float = b["r"] * 1.15
		canvas.draw_texture_rect(ic, Rect2(b["pos"] - Vector2(isz, isz) / 2.0, Vector2(isz, isz)), false, Color(1, 1, 1, 1.0 if can_use else 0.35))
	# HP dan Energy
	var p := get_tree().get_first_node_in_group("player")
	if p:
		var hr := clampf(float(p.hp) / float(p.max_hp), 0.0, 1.0)
		var er := clampf(float(p.energy) / 100.0, 0.0, 1.0)
		_para(118.0, 30.0, 330.0, 22.0, 14.0, Color(0, 0, 0, 0.6))
		_para(118.0, 30.0, 330.0 * hr, 22.0, 14.0, Color(0.88, 0.14, 0.18))
		for i in range(1, 10):
			var lx := 118.0 + 330.0 * float(i) / 10.0
			canvas.draw_line(Vector2(lx + 14.0, 30.0), Vector2(lx, 52.0), Color(0, 0, 0, 0.45), 2.0)
		_para(112.0, 58.0, 270.0, 14.0, 10.0, Color(0, 0, 0, 0.6))
		_para(112.0, 58.0, 270.0 * er, 14.0, 10.0, Color(0.2, 0.7, 0.95))
		var mr := clampf(float(p.mana) / 100.0, 0.0, 1.0)
		_para(106.0, 78.0, 240.0, 12.0, 8.0, Color(0, 0, 0, 0.6))
		_para(106.0, 78.0, 240.0 * mr, 12.0, 8.0, Color(0.3, 0.9, 0.8))
	# Pause
	canvas.draw_rect(pause_rect, Color(0.1, 0.04, 0.08, 0.7))
	canvas.draw_rect(pause_rect, Color(0.8, 0.3, 0.35, 0.9), false, 3.0)
	canvas.draw_rect(Rect2(pause_rect.position + Vector2(20, 16), Vector2(8, 32)), Color(1, 0.85, 0.88))
	canvas.draw_rect(Rect2(pause_rect.position + Vector2(36, 16), Vector2(8, 32)), Color(1, 0.85, 0.88))
	# Gem
	var gems: int = get_tree().root.get_meta("gems", 0)
	canvas.draw_string(font, Vector2(s.x - 255.0, 56.0), "%03d" % gems, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1, 1, 1))
	# Bar boss
	var boss := get_tree().get_first_node_in_group("boss")
	if boss and not boss.dead and boss.state != 0:
		var br := clampf(float(boss.hp) / float(boss.max_hp), 0.0, 1.0)
		var bw := minf(s.x * 0.4, 520.0)
		var bx := (s.x - bw) / 2.0
		canvas.draw_string(font, Vector2(bx, 100.0), "MINI-BOSS", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.9, 0.8))
		_para(bx, 108.0, bw, 14.0, 10.0, Color(0, 0, 0, 0.6))
		_para(bx, 108.0, bw * br, 14.0, 10.0, Color(0.95, 0.45, 0.15))
	canvas.draw_string(font, Vector2(s.x - 330.0, s.y - 12.0), VERSION_LABEL, HORIZONTAL_ALIGNMENT_RIGHT, 310.0, 14, Color(1, 1, 1, 0.5))
	if get_tree().root.has_meta("boss_dead"):
		canvas.draw_string(font, Vector2(0, s.y * 0.35), "DEMO COMPLETE", HORIZONTAL_ALIGNMENT_CENTER, s.x, 64)
	if paused:
		canvas.draw_rect(Rect2(0, 0, s.x, s.y), Color(0, 0, 0, 0.6))
		canvas.draw_string(font, Vector2(0, s.y * 0.45), "PAUSED", HORIZONTAL_ALIGNMENT_CENTER, s.x, 64)
		canvas.draw_string(font, Vector2(0, s.y * 0.45 + 50.0), "tekan tombol pause untuk lanjut", HORIZONTAL_ALIGNMENT_CENTER, s.x, 22)

func _draw_pix() -> void:
	var s := get_viewport().get_visible_rect().size
	var pts := PackedVector2Array([Vector2(62, 14), Vector2(110, 62), Vector2(62, 110), Vector2(14, 62)])
	var uvs := PackedVector2Array([Vector2(0.5, 0.0), Vector2(1.0, 0.5), Vector2(0.5, 1.0), Vector2(0.0, 0.5)])
	var cols := PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE])
	pix.draw_colored_polygon(pts, Color(0.1, 0.04, 0.1, 0.9))
	pix.draw_polygon(pts, cols, uvs, portrait)
	pix.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color(0.85, 0.2, 0.28), 4.0)
	pix.draw_texture_rect(gem_tex, Rect2(s.x - 300.0, 30.0, 24.0, 28.0), false)
