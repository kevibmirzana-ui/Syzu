extends Node2D
# Efek cincin kecil (parry, slam, shockwave).

var max_radius := 100.0
var color := Color(1, 1, 1)
var t := 0.0

func _process(delta: float) -> void:
	t += delta
	if t > 0.3:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var k := t / 0.3
	draw_arc(Vector2.ZERO, max_radius * k, 0.0, TAU, 32, Color(color.r, color.g, color.b, 1.0 - k), 6.0)
