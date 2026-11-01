extends CanvasLayer
# Tombol sentuh multi-touch + HUD energy.

var canvas: Control
var touches := {}   # index jari -> nama aksi
var buttons := {}   # aksi -> {pos, r, label}

func _ready() -> void:
	layer = 10
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.draw.connect(_draw_ui)
	add_child(canvas)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var s := get_viewport().get_visible_rect().size
	buttons = {
		"left": {"pos": Vector2(110, s.y - 110), "r": 70.0, "label": "<"},
		"right": {"pos": Vector2(290, s.y - 110), "r": 70.0, "label": ">"},
		"down": {"pos": Vector2(200, s.y - 250), "r": 55.0, "label": "v"},
		"jump": {"pos": Vector2(s.x - 110, s.y - 130), "r": 80.0, "label": "JUMP"},
		"dash": {"pos": Vector2(s.x - 290, s.y - 100), "r": 62.0, "label": "DASH"},
		"run": {"pos": Vector2(s.x - 290, s.y - 230), "r": 50.0, "label": "RUN"},
	}

func _process(_delta: float) -> void:
	canvas.queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_press(event.index, event.position)
		else:
			_release(event.index)
	elif event is InputEventScreenDrag:
		_press(event.index, event.position)

func _hit(pos: Vector2) -> String:
	var best := ""
	var best_d := INF
	for a in buttons:
		var b = buttons[a]
		var d: float = pos.distance_to(b["pos"])
		if d <= b["r"] * 1.25 and d < best_d:
			best = a
			best_d = d
	return best

func _press(index: int, pos: Vector2) -> void:
	var a := _hit(pos)
	if touches.get(index, "") == a:
		return
	_release(index)
	if a != "":
		touches[index] = a
		Input.action_press(a)

func _release(index: int) -> void:
	if touches.has(index):
		var a: String = touches[index]
		touches.erase(index)
		if not touches.values().has(a):
			Input.action_release(a)

func _draw_ui() -> void:
	var font := ThemeDB.fallback_font
	for a in buttons:
		var b = buttons[a]
		var pressed := Input.is_action_pressed(a)
		canvas.draw_circle(b["pos"], b["r"], Color(1, 1, 1, 0.28 if pressed else 0.12))
		canvas.draw_arc(b["pos"], b["r"], 0.0, TAU, 40, Color(1, 1, 1, 0.5), 2.0)
		canvas.draw_string(font, b["pos"] + Vector2(-b["r"], 9), b["label"], HORIZONTAL_ALIGNMENT_CENTER, b["r"] * 2.0, 26)
	var p := get_tree().get_first_node_in_group("player")
	if p:
		var ratio := clampf(p.energy / 100.0, 0.0, 1.0)
		canvas.draw_rect(Rect2(30, 30, 300, 14), Color(0, 0, 0, 0.5))
		canvas.draw_rect(Rect2(30, 30, 300 * ratio, 14), Color("#4fc3f7"))
		canvas.draw_string(font, Vector2(30, 24), "ENERGY", HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
