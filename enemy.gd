extends CharacterBody2D
# Musuh prototype: fighter, shooter, boss (mini-boss), dummy (latihan).
# Semua serangan musuh bisa di-parry dan dihindari dengan dash i-frame.

const R_HIT := 0
const R_PARRY := 1
const R_PERFECT := 2
const R_MISS := 3
const GRAVITY := 2300.0

enum S { IDLE, CHASE, WINDUP, ATTACK, RECOVER, STUN }

var kind := "fighter"
var max_hp := 60
var hp := 60
var speed := 130.0
var body_size := Vector2(30, 52)
var attack_range := 70.0
var attack_damage := 15
var windup_time := 0.45
var recover_time := 0.7
var stun_resist := 1.0
var facing := -1
var state := S.IDLE
var timer := 0.0
var stun_t := 0.0
var dead := false
var slammed := false
var pattern := 0
var hit_done := false
var shot_cd := 1.0
var flash := 0.0
var player = null
var spr: Sprite2D
var anim_t := 0.0
var sc := 2.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	match kind:
		"shooter":
			max_hp = 40
			speed = 0.0
			body_size = Vector2(28, 50)
		"boss":
			max_hp = 320
			speed = 165.0
			body_size = Vector2(46, 76)
			attack_range = 110.0
			windup_time = 0.4
			recover_time = 0.9
			stun_resist = 0.35
			add_to_group("boss")
		"heavy":
			max_hp = 130
			speed = 85.0
			body_size = Vector2(40, 58)
			attack_range = 80.0
			attack_damage = 28
			windup_time = 0.65
			recover_time = 0.95
			stun_resist = 0.6
		"extreme":
			max_hp = 90
			speed = 190.0
			body_size = Vector2(34, 54)
			attack_range = 75.0
			attack_damage = 20
			windup_time = 0.3
			recover_time = 0.5
			stun_resist = 0.8
		"dummy":
			max_hp = 400
			body_size = Vector2(34, 92)
	hp = max_hp
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = body_size
	shape.shape = rect
	add_child(shape)
	spr = Sprite2D.new()
	var path := "res://art_wolf_fighter.png"
	if kind == "shooter":
		path = "res://art_wolf_shooter.png"
	elif kind == "boss":
		path = "res://art_wolf_boss.png"
	elif kind == "heavy":
		path = "res://art_wolf_heavy.png"
	elif kind == "extreme":
		path = "res://art_wolf_extreme.png"
	elif kind == "dummy":
		path = "res://art_dummy.png"
	spr.texture = load(path)
	if kind == "dummy":
		sc = 2.0
		spr.position = Vector2(0, body_size.y / 2.0 - 24.0 * sc)
	else:
		sc = 3.0 if kind == "boss" else 2.0
		spr.region_enabled = true
		spr.region_rect = Rect2(0, 0, 48, 36)
		spr.position = Vector2(0, body_size.y / 2.0 - 18.0 * sc)
	spr.scale = Vector2(sc, sc)
	spr.show_behind_parent = true
	add_child(spr)

func hit_rect() -> Rect2:
	return Rect2(global_position - body_size / 2.0, body_size)

func _physics_process(delta: float) -> void:
	if dead:
		return
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	flash = maxf(0.0, flash - delta)
	velocity.y = minf(velocity.y + GRAVITY * delta, 1200.0)
	var dx := 0.0
	var dist := 99999.0
	if player:
		dx = player.global_position.x - global_position.x
		if absf(player.global_position.y - global_position.y) < 220.0:
			dist = absf(dx)
	match state:
		S.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, 1500.0 * delta)
			if kind != "dummy" and dist < 520.0:
				state = S.CHASE
		S.CHASE:
			_chase(delta, dx, dist)
		S.WINDUP:
			_windup(delta)
		S.ATTACK:
			_attack(delta)
		S.RECOVER:
			timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 1500.0 * delta)
			if timer <= 0.0:
				state = S.CHASE
		S.STUN:
			stun_t -= delta
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if stun_t <= 0.0:
				state = S.IDLE if kind == "dummy" else S.CHASE
	move_and_slide()
	if slammed and is_on_floor():
		_slam_land()
	_update_anim(delta)
	queue_redraw()

func _update_anim(delta: float) -> void:
	var tint := Color.WHITE
	if flash > 0.0:
		tint = Color(1.0, 0.45, 0.45)
	elif state == S.WINDUP:
		tint = Color(1.0, 0.92, 0.5)
	spr.modulate = tint
	spr.scale = Vector2(sc * facing, sc)
	if kind == "dummy":
		return
	var row := 0
	var n := 4
	var fps := 5.0
	var frame_override := -1
	match state:
		S.CHASE:
			if absf(velocity.x) > 10.0 and kind != "shooter":
				row = 1
				n = 6
				fps = 10.0
		S.WINDUP:
			row = 2
			n = 2
			fps = 0.0
			frame_override = 0 if timer > 0.18 else 1
		S.ATTACK:
			row = 3
			n = 3
			fps = 0.0
			var dur := 0.3 if ((kind == "boss" or kind == "extreme") and pattern == 1) else 0.14
			frame_override = 1 if timer > dur * 0.5 else 2
		S.STUN:
			row = 4
			n = 1
			fps = 0.0
	anim_t += delta
	var frame := frame_override
	if frame < 0:
		frame = 0
		if fps > 0.0:
			frame = int(anim_t * fps) % n
	spr.region_rect = Rect2(frame * 48, row * 36, 48, 36)

func _chase(delta: float, dx: float, dist: float) -> void:
	if dist > 800.0:
		state = S.IDLE
		return
	facing = 1 if dx > 0.0 else -1
	if kind == "shooter":
		shot_cd -= delta
		velocity.x = move_toward(velocity.x, 0.0, 1500.0 * delta)
		if shot_cd <= 0.0 and dist < 600.0:
			_begin_windup(0.6)
		return
	if dist > attack_range:
		velocity.x = facing * speed
	else:
		velocity.x = 0.0
		_begin_windup(windup_time)

func _begin_windup(t: float) -> void:
	state = S.WINDUP
	timer = t
	velocity.x = 0.0
	hit_done = false
	if kind == "boss":
		pattern = (pattern + 1) % 3
		timer = [0.4, 0.65, 0.75][pattern]
	elif kind == "extreme":
		pattern = (pattern + 1) % 2
		if pattern == 1:
			timer = 0.45

func _windup(delta: float) -> void:
	timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, 1500.0 * delta)
	if timer > 0.0:
		return
	if kind == "shooter":
		_shoot()
		state = S.RECOVER
		timer = 1.2
		return
	state = S.ATTACK
	timer = 0.3 if ((kind == "boss" or kind == "extreme") and pattern == 1) else 0.14
	hit_done = false

func _attack(delta: float) -> void:
	timer -= delta
	if (kind == "boss" or kind == "extreme") and pattern == 1:
		velocity.x = facing * 560.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, 3000.0 * delta)
	if not hit_done and player:
		var r := _attack_rect()
		if r.intersects(player.hit_rect()):
			var res: int = player.receive_attack(_damage(), self)
			if res != R_MISS:
				hit_done = true
			if res == R_PARRY:
				_stagger(0.45, 160.0)
			elif res == R_PERFECT:
				_stagger(1.4, 260.0)
	if timer <= 0.0 and state == S.ATTACK:
		state = S.RECOVER
		timer = recover_time

func _stagger(t: float, push: float) -> void:
	state = S.STUN
	stun_t = t * stun_resist
	velocity.x = -facing * push

func _damage() -> int:
	if kind == "boss":
		return [25, 30, 40][pattern]
	if kind == "extreme":
		return [20, 26][pattern]
	return attack_damage

func _attack_rect() -> Rect2:
	var p := global_position
	var reach := attack_range + 20.0
	var h := 70.0
	if kind == "boss" and pattern == 2:
		reach = 150.0
		h = 120.0
	var x := p.x if facing > 0 else p.x - reach
	return Rect2(x, p.y - h / 2.0, reach, h)

func _shoot() -> void:
	if player == null:
		return
	var pr := preload("res://projectile.gd").new()
	pr.position = position + Vector2(facing * 20.0, -6.0)
	var aim: Vector2 = (player.global_position - global_position).normalized()
	pr.vel = aim * 380.0
	get_parent().add_child(pr)
	shot_cd = 2.0

func take_damage(dmg: int, dir: int, knock: float, stun: float, slam: bool = false) -> void:
	if dead:
		return
	hp -= dmg
	flash = 0.12
	facing = -dir
	velocity.x = dir * knock * (0.4 if kind == "boss" else 1.0)
	if hp <= 0:
		_die()
		return
	if state == S.IDLE and kind != "dummy":
		state = S.CHASE
	if stun > 0.0 and kind != "dummy" and not (kind == "boss" and stun < 0.3):
		state = S.STUN
		stun_t = stun * stun_resist
	if slam:
		slammed = true
		velocity.y = 900.0

func launch(vy: float, stun: float) -> void:
	if dead or kind == "dummy":
		return
	state = S.STUN
	stun_t = stun * stun_resist
	velocity.y = vy * (0.4 if kind == "boss" else 1.0)

func _slam_land() -> void:
	slammed = false
	var pos := global_position
	var fx := preload("res://fx.gd").new()
	fx.position = Vector2(pos.x, pos.y + body_size.y / 2.0)
	fx.max_radius = 130.0
	fx.color = Color(1.0, 0.7, 0.3)
	get_parent().add_child(fx)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e != self and not e.dead and e.global_position.distance_to(pos) < 130.0:
			e.take_damage(12, 1 if e.global_position.x > pos.x else -1, 150.0, 0.3)

func _die() -> void:
	dead = true
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	var gems: int = get_tree().root.get_meta("gems", 0)
	var reward := 1
	if kind == "boss":
		reward = 10
	elif kind == "heavy":
		reward = 2
	elif kind == "extreme":
		reward = 3
	get_tree().root.set_meta("gems", gems + reward)
	if kind == "boss":
		get_tree().root.set_meta("boss_dead", true)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(queue_free)

func _draw() -> void:
	var half := body_size / 2.0
	var tier := 0
	if kind == "fighter" or kind == "shooter":
		tier = 1
	elif kind == "heavy":
		tier = 2
	elif kind == "extreme":
		tier = 3
	var tier_cols := [Color(1.0, 0.65, 0.85), Color(1.0, 0.5, 0.3), Color(1.0, 0.15, 0.2)]
	for i in tier:
		draw_rect(Rect2(-half.x + float(i) * 9.0, -half.y - 24.0, 7.0, 7.0), tier_cols[tier - 1])
	if state == S.WINDUP:
		draw_string(ThemeDB.fallback_font, Vector2(-6.0, -half.y - 22.0), "!", HORIZONTAL_ALIGNMENT_CENTER, -1, 30, Color(1.0, 0.9, 0.2))
	if state == S.ATTACK and kind != "shooter" and kind != "dummy":
		var r := _attack_rect()
		draw_rect(Rect2(r.position - global_position, r.size), Color(1.0, 0.2, 0.2, 0.3))
	if hp < max_hp and kind != "boss":
		var w := body_size.x + 14.0
		draw_rect(Rect2(-w / 2.0, -half.y - 12.0, w, 5.0), Color(0.0, 0.0, 0.0, 0.6))
		draw_rect(Rect2(-w / 2.0, -half.y - 12.0, w * float(maxi(hp, 0)) / float(max_hp), 5.0), Color(0.9, 0.2, 0.2))
