extends Node2D
# Peluru musuh. Kalau di-parry, dipantulkan dan melukai musuh.

var vel := Vector2.ZERO
var damage := 12
var hostile := true
var life := 3.0

func _ready() -> void:
	add_to_group("projectiles")

func hit_rect() -> Rect2:
	return Rect2(global_position - Vector2(8, 8), Vector2(16, 16))

func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	var from := global_position
	var to := from + vel * delta
	var q := PhysicsRayQueryParameters2D.create(from, to, 1)
	if not get_world_2d().direct_space_state.intersect_ray(q).is_empty():
		queue_free()
		return
	global_position = to
	if hostile:
		var p := get_tree().get_first_node_in_group("player")
		if p and hit_rect().intersects(p.hit_rect()):
			var res: int = p.receive_attack(damage, self)
			if res == 1 or res == 2:
				vel = -vel * 1.4
				hostile = false
				life = 3.0
			elif res == 0:
				queue_free()
				return
	else:
		for e in get_tree().get_nodes_in_group("enemies"):
			if not e.dead and hit_rect().intersects(e.hit_rect()):
				e.take_damage(30, 1 if vel.x > 0.0 else -1, 200.0, 0.5)
				queue_free()
				return
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, Color(1.0, 0.4, 0.9) if hostile else Color(0.4, 1.0, 1.0))
