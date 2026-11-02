extends Node2D
# Efek dan proyektil elemen Air milik Syzu: needle, wave, geyser, burst.

var mode := "needle"
var vel := Vector2.ZERO
var damage := 9
var life := 1.0
var size := Vector2(22, 6)
var t := 0.0
var hit_ids := {}
var fired := false

func _ready() -> void:
	z_index = 2

func _hit_rect() -> Rect2:
	if mode == "geyser":
		return Rect2(global_position.x - size.x / 2.0, global_position.y - size.y, size.x, size.y)
	return Rect2(global_position - size / 2.0, size)

func _physics_process(delta: float) -> void:
	t += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if mode == "needle" or mode == "wave":
		var from := global_position
		var to := from + vel * delta
		var q := PhysicsRayQueryParameters2D.create(from, to, 1)
		if not get_world_2d().direct_space_state.intersect_ray(q).is_empty():
			queue_free()
			return
		global_position = to
	if mode == "geyser" or mode == "burst":
		if fired:
			queue_redraw()
			return
		fired = true
	_hit_enemies()
	queue_redraw()

func _hit_enemies() -> void:
	if damage <= 0:
		return
	var rect := _hit_rect()
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead or hit_ids.has(e.get_instance_id()):
			continue
		if rect.intersects(e.hit_rect()):
			hit_ids[e.get_instance_id()] = true
			var dir := 1 if e.global_position.x > global_position.x else -1
			var knock := 120.0
			var stun := 0.12
			if mode == "wave":
				knock = 260.0
				stun = 0.25
			elif mode == "geyser":
				knock = 40.0
				stun = 0.0
			elif mode == "burst":
				knock = 380.0
				stun = 0.4
			e.take_damage(damage, dir, knock, stun, false)
			if mode == "geyser":
				e.launch(-760.0, 0.9)
			if mode == "needle":
				queue_free()
				return

func _draw() -> void:
	if mode == "needle":
		var d := vel.normalized()
		draw_line(-d * 12.0, d * 12.0, Color(0.45, 0.8, 1.0), 4.0)
		draw_line(-d * 8.0, d * 12.0, Color(0.9, 0.98, 1.0), 2.0)
	elif mode == "wave":
		var base := 0.0 if vel.x > 0.0 else PI
		var c := Vector2(-10.0 * signf(vel.x), 0.0)
		draw_arc(c, 46.0, base - 1.0, base + 1.0, 16, Color(0.4, 0.75, 1.0, 0.9), 14.0)
		draw_arc(c, 46.0, base - 0.8, base + 0.8, 16, Color(0.9, 0.98, 1.0, 0.9), 5.0)
	elif mode == "geyser":
		var k := minf(t / 0.12, 1.0)
		var fade := clampf(life / 0.3, 0.0, 1.0)
		var h := size.y * k
		draw_rect(Rect2(-size.x * 0.5, -h, size.x, h), Color(0.35, 0.7, 1.0, 0.55 * fade))
		draw_rect(Rect2(-size.x * 0.28, -h, size.x * 0.56, h), Color(0.85, 0.96, 1.0, 0.7 * fade))
		for i in 6:
			draw_circle(Vector2(sin(t * 9.0 + float(i)) * size.x * 0.4, -h * (float(i) + 1.0) / 7.0), 4.0, Color(0.9, 0.98, 1.0, 0.8 * fade))
	elif mode == "burst":
		var kk := clampf(t / 0.3, 0.0, 1.0)
		draw_arc(Vector2.ZERO, size.x * 0.5 * kk, 0.0, TAU, 40, Color(0.5, 0.82, 1.0, 1.0 - kk), 10.0)
