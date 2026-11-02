extends CanvasLayer
# Kelopak sakura yang jatuh pelan di depan layar.

var canvas: Node2D
var petals: Array = []
var t := 0.0

func _ready() -> void:
	layer = 3
	canvas = Node2D.new()
	canvas.draw.connect(_draw_petals)
	add_child(canvas)
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 7
	for i in 26:
		petals.append({"x": rnd.randf() * 1700.0, "y": rnd.randf() * 760.0, "v": 24.0 + rnd.randf() * 30.0, "w": 14.0 + rnd.randf() * 22.0, "p": rnd.randf() * 6.28, "s": 2.0 + float(rnd.randi() % 3)})

func _process(delta: float) -> void:
	t += delta
	var vp := get_viewport().get_visible_rect().size
	for p in petals:
		p["y"] += p["v"] * delta
		p["x"] += (12.0 + 10.0 * sin(t * 0.7 + p["p"])) * delta
		if p["y"] > vp.y + 10.0:
			p["y"] = -10.0
			p["x"] = randf() * vp.x
		if p["x"] > vp.x + 10.0:
			p["x"] = -10.0
	canvas.queue_redraw()

func _draw_petals() -> void:
	for p in petals:
		var sway: float = sin(t * 2.0 + p["p"]) * p["w"] * 0.2
		canvas.draw_rect(Rect2(p["x"] + sway, p["y"], p["s"] * 2.0, p["s"]), Color(1.0, 0.6, 0.78, 0.85))
