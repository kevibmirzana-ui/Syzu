extends CharacterBody2D
# Syzu - Movement (M2) + Combat (M3). Semua angka bisa di-tune. Visual masih placeholder.

const WALK_SPEED := 260.0
const RUN_SPEED := 420.0
const ACCEL_GROUND := 2600.0
const ACCEL_AIR := 1500.0
const GRAVITY := 2300.0
const FALL_MAX := 1100.0
const JUMP_VELOCITY := -780.0
const COYOTE_TIME := 0.10
const JUMP_BUFFER := 0.12
const DASH_SPEED := 900.0
const DASH_TIME := 0.18
const DASH_COOLDOWN := 0.12
const IFRAME_FROM := 0.03
const IFRAME_TO := 0.12
const DOWN_DASH_SPEED := 1100.0
const WALL_SLIDE_SPEED := 110.0
const WALL_JUMP := Vector2(400.0, -720.0)
const WALL_JUMP_LOCK := 0.14
const WALL_GRACE := 0.12
const ENERGY_MAX := 100.0
const DASH_COST := 15.0
const DOUBLE_JUMP_COST := 12.0
const ENERGY_REGEN := 4.0
const MAX_HP := 100
const ATTACK_DAMAGE := 10
const COMBO_WINDOW := 0.55
const PARRY_TIME := 0.40
const PARRY_ACTIVE := 0.26
const PERFECT_WINDOW := 0.10
const COUNTER_WINDOW := 0.70
const SLAM_SPEED := 1200.0
const SLAM_FALL_SPEED := 450.0
const R_HIT := 0
const R_PARRY := 1
const R_PERFECT := 2
const R_MISS := 3
const MAX_MANA := 100.0
const MANA_REGEN := 2.667   # 20 per 7,5 detik (usulan)
const COST_NEEDLES := 10.0
const COST_TIDE := 20.0
const COST_RAIN := 20.0
const COST_GEYSER := 25.0
const COST_MIRROR := 20.0
const ULT_MANA := 67.0      # 2/3 Mana
const ULT_ENERGY := 33.0    # 1/3 Energy

enum State { NORMAL, DASH, LEDGE, ATTACK, PARRY, SLAM, CAST, ULT }

var state := State.NORMAL
var energy := ENERGY_MAX
var hp := MAX_HP
var mana := MAX_MANA
var cast_t := 0.0
var ult_t := 0.0
var ult_phase := 0
var ult_start := Vector2.ZERO
var ult_air := Vector2.ZERO
var ult_land := Vector2.ZERO
var ult_targets: Array = []
var max_hp := MAX_HP
var facing := 1
var running := false
var double_jump_used := false
var air_dash_used := false
var coyote := 0.0
var jump_buffer := 0.0
var dash_timer := 0.0
var dash_cooldown := 0.0
var dash_dir := Vector2.RIGHT
var down_dash := false
var dash_attacked := false
var dash_hit_landed := false
var dash_step := 0
var wall_normal_x := 0.0
var wall_time := 0.0
var input_lock := 0.0
var ledge_cooldown := 0.0
var invulnerable := false
var climbing := false
var spawn_point := Vector2.ZERO
var combo_step := 0
var combo_timer := 0.0
var attack_t := 0.0
var attack_kind := 0
var attack_wide := false
var attack_hit_done := false
var attack_buffer := 0.0
var counter_timer := 0.0
var parry_t := 0.0
var parry_cd := 0.0
var hurt_timer := 0.0
var shake_t := 0.0
var hitstop_id := 0
var slash_t := 99.0
var slash_arc := Vector2.ZERO
var slash_face := 1
var slash_wide := false
var slash_finisher := false
var cam: Camera2D
var spr: Sprite2D
var anim := "idle"
var anim_t := 0.0

const ANIMS := {
	"idle": [0, 4, 5.0], "run": [1, 6, 12.0], "jump": [2, 1, 1.0], "fall": [3, 1, 1.0],
	"dash": [4, 1, 1.0], "wall": [5, 1, 1.0], "ledge": [6, 1, 1.0],
	"atk_h": [7, 3, 0.0], "atk_diag": [8, 3, 0.0], "atk_over": [9, 3, 0.0], "atk_up": [10, 3, 0.0],
	"parry": [11, 2, 0.0], "hurt": [12, 1, 1.0], "slam": [13, 1, 1.0],
}

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	spawn_point = position
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 56)
	shape.shape = rect
	add_child(shape)
	spr = Sprite2D.new()
	spr.texture = load("res://art_fox.png")
	spr.region_enabled = true
	spr.region_rect = Rect2(0, 0, 48, 40)
	spr.scale = Vector2(2, 2)
	spr.position = Vector2(0, -12)
	spr.show_behind_parent = true
	add_child(spr)
	cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	cam.limit_left = -200
	cam.limit_right = 4240
	cam.limit_bottom = 800
	add_child(cam)

func hit_rect() -> Rect2:
	return Rect2(global_position - Vector2(14, 28), Vector2(28, 56))

func _physics_process(delta: float) -> void:
	energy = minf(ENERGY_MAX, energy + ENERGY_REGEN * delta)
	mana = minf(MAX_MANA, mana + MANA_REGEN * delta)
	coyote = maxf(0.0, coyote - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	attack_buffer = maxf(0.0, attack_buffer - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	input_lock = maxf(0.0, input_lock - delta)
	ledge_cooldown = maxf(0.0, ledge_cooldown - delta)
	wall_time = maxf(0.0, wall_time - delta)
	counter_timer = maxf(0.0, counter_timer - delta)
	parry_cd = maxf(0.0, parry_cd - delta)
	hurt_timer = maxf(0.0, hurt_timer - delta)
	shake_t = maxf(0.0, shake_t - delta)
	slash_t += delta
	if state != State.ATTACK:
		combo_timer = maxf(0.0, combo_timer - delta)
	if Input.is_action_just_pressed("jump"):
		jump_buffer = JUMP_BUFFER
	if Input.is_action_just_pressed("attack"):
		attack_buffer = 0.3

	var dir := Input.get_axis("left", "right")
	if input_lock > 0.0:
		dir = 0.0
	elif dir != 0.0 and state == State.NORMAL:
		facing = 1 if dir > 0.0 else -1
	if dir == 0.0:
		if input_lock <= 0.0:
			running = false
	elif Input.is_action_just_pressed("run"):
		running = true

	match state:
		State.DASH:
			_state_dash(delta)
		State.LEDGE:
			_state_ledge()
		State.ATTACK:
			_state_attack(delta, dir)
		State.PARRY:
			_state_parry(delta)
		State.SLAM:
			_state_slam()
		State.CAST:
			_state_cast(delta)
		State.ULT:
			_state_ult(delta)
		_:
			_state_normal(delta, dir)

	_check_checkpoints()
	if global_position.y > 1100.0:
		_respawn(false)
	if shake_t > 0.0:
		cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 8.0
	else:
		cam.offset = Vector2.ZERO
	_update_anim(delta)
	queue_redraw()

func _update_anim(delta: float) -> void:
	var anim_name := "idle"
	var frame_override := -1
	match state:
		State.DASH:
			anim_name = "dash"
		State.LEDGE:
			anim_name = "ledge"
		State.ATTACK:
			anim_name = ["atk_h", "atk_h", "atk_diag", "atk_over", "atk_up"][attack_kind]
			frame_override = 0 if attack_t < 0.07 else (1 if attack_t < 0.2 else 2)
		State.PARRY:
			anim_name = "parry"
			frame_override = 0 if parry_t <= PARRY_ACTIVE else 1
		State.SLAM:
			anim_name = "slam"
		State.CAST:
			anim_name = "atk_h"
			frame_override = 1
		State.ULT:
			if ult_t < 0.4:
				anim_name = "atk_over"
				frame_override = 0
			elif ult_t < 0.9:
				anim_name = "jump"
			elif ult_t < 1.12:
				anim_name = "slam"
			else:
				anim_name = "atk_over"
				frame_override = 1
		_:
			if hurt_timer > 0.85:
				anim_name = "hurt"
			elif not is_on_floor():
				if wall_time > 0.0 and wall_normal_x != 0.0 and velocity.y > 0.0:
					anim_name = "wall"
				elif velocity.y < 0.0:
					anim_name = "jump"
				else:
					anim_name = "fall"
			elif absf(velocity.x) > 20.0:
				anim_name = "run"
	if anim_name != anim:
		anim = anim_name
		anim_t = 0.0
	anim_t += delta
	var info: Array = ANIMS[anim]
	var frame := frame_override
	if frame < 0:
		frame = 0
		if float(info[2]) > 0.0:
			frame = int(anim_t * float(info[2])) % int(info[1])
	spr.region_rect = Rect2(frame * 48, int(info[0]) * 40, 48, 40)
	spr.scale = Vector2(2.0 * facing, 2.0)
	var blink := invulnerable or hurt_timer > 0.0
	spr.modulate = Color(1, 1, 1, 0.5 if blink else 1.0)

# ---------- NORMAL ----------

func _state_normal(delta: float, dir: float) -> void:
	var on_floor := is_on_floor()
	if on_floor:
		coyote = COYOTE_TIME
		double_jump_used = false
		air_dash_used = false
	var on_wall := not on_floor and wall_time > 0.0 and wall_normal_x != 0.0
	var sliding := on_wall and velocity.y > 0.0 and dir == -wall_normal_x

	if Input.is_action_just_pressed("dash") and _try_dash(dir):
		return
	if Input.is_action_just_pressed("parry") and not running and not sliding and parry_cd <= 0.0:
		_start_parry()
		return
	if Input.is_action_just_pressed("ult") and mana >= ULT_MANA and energy >= ULT_ENERGY and not sliding:
		_start_ult()
		return
	if Input.is_action_just_pressed("skill") and not sliding and _try_skill():
		return
	if attack_buffer > 0.0 and not sliding:
		if not on_floor and (velocity.y > SLAM_FALL_SPEED or Input.is_action_pressed("down")):
			_start_slam()
		elif counter_timer > 0.0:
			_start_attack(0, true)
		else:
			var step := 0
			if combo_timer > 0.0:
				step = (combo_step + 1) % 4
			_start_attack(step, false)
		return

	if input_lock <= 0.0:
		var target := dir * (RUN_SPEED if running else WALK_SPEED)
		var accel := ACCEL_GROUND if on_floor else ACCEL_AIR
		velocity.x = move_toward(velocity.x, target, accel * delta)

	if sliding:
		velocity.y = minf(velocity.y + GRAVITY * delta, WALL_SLIDE_SPEED)
	else:
		velocity.y = minf(velocity.y + GRAVITY * delta, FALL_MAX)

	if jump_buffer > 0.0:
		if on_floor or coyote > 0.0:
			velocity.y = JUMP_VELOCITY
			jump_buffer = 0.0
			coyote = 0.0
		elif on_wall:
			velocity = Vector2(wall_normal_x * WALL_JUMP.x, WALL_JUMP.y)
			facing = 1 if wall_normal_x > 0.0 else -1
			input_lock = WALL_JUMP_LOCK
			jump_buffer = 0.0
			wall_normal_x = 0.0
			wall_time = 0.0
		elif not double_jump_used and energy >= DOUBLE_JUMP_COST:
			velocity.y = JUMP_VELOCITY * 0.92
			energy -= DOUBLE_JUMP_COST
			double_jump_used = true
			jump_buffer = 0.0
	if Input.is_action_just_released("jump") and velocity.y < -200.0:
		velocity.y *= 0.5

	if not on_floor and velocity.y >= 0.0 and ledge_cooldown <= 0.0 and dir == float(facing):
		if _ray_hits(Vector2(0, -18), 22.0) and not _ray_hits(Vector2(0, -36), 22.0):
			state = State.LEDGE
			velocity = Vector2.ZERO
			return

	move_and_slide()
	_update_wall()

# ---------- DASH ----------

func _try_dash(dir: float) -> bool:
	if dash_cooldown > 0.0 or energy < DASH_COST:
		return false
	var on_floor := is_on_floor()
	if not on_floor and air_dash_used:
		return false
	var on_wall := not on_floor and wall_time > 0.0 and wall_normal_x != 0.0
	_start_dash(dir, on_floor, on_wall)
	return true

func _start_dash(dir: float, on_floor: bool, on_wall: bool) -> void:
	if state == State.ATTACK:
		combo_timer = 0.0 if combo_step == 3 else COMBO_WINDOW
	energy -= DASH_COST
	if not on_floor:
		air_dash_used = true
	down_dash = Input.is_action_pressed("down") and not on_floor
	if down_dash:
		dash_dir = Vector2.DOWN
	else:
		var dx := dir if dir != 0.0 else float(facing)
		if on_wall:
			dx = wall_normal_x
		facing = 1 if dx > 0.0 else -1
		dash_dir = Vector2(float(facing), 0.0)
	dash_timer = 0.0
	dash_attacked = false
	dash_hit_landed = false
	attack_buffer = 0.0
	running = false
	state = State.DASH

func _state_dash(delta: float) -> void:
	dash_timer += delta
	invulnerable = dash_timer >= IFRAME_FROM and dash_timer <= IFRAME_TO
	velocity = dash_dir * (DOWN_DASH_SPEED if down_dash else DASH_SPEED)
	if Input.is_action_just_pressed("attack") and not dash_attacked and not down_dash:
		dash_attacked = true
		dash_step = (combo_step + 1) % 4 if combo_timer > 0.0 else 0
		combo_step = dash_step
		combo_timer = COMBO_WINDOW
		_set_slash(0, true)
	if dash_attacked and not dash_hit_landed:
		dash_hit_landed = _do_hit(0, dash_step, true)
		if dash_hit_landed and dash_step == 3:
			combo_timer = 0.0
	if down_dash and not dash_hit_landed:
		dash_hit_landed = _do_hit(5, 0, false)
	move_and_slide()
	if down_dash:
		for i in get_slide_collision_count():
			var c := get_slide_collision(i).get_collider()
			if c is Node and (c as Node).is_in_group("fragile"):
				(c as Node).queue_free()
	_update_wall()
	if dash_timer >= DASH_TIME or is_on_wall() or (down_dash and is_on_floor()):
		invulnerable = false
		dash_cooldown = DASH_COOLDOWN
		state = State.NORMAL
		if down_dash:
			velocity = Vector2(0.0, 200.0)
		else:
			velocity = Vector2(dash_dir.x * WALK_SPEED, 0.0)

# ---------- LEDGE ----------

func _state_ledge() -> void:
	velocity = Vector2.ZERO
	if climbing:
		return
	if Input.is_action_just_pressed("down"):
		state = State.NORMAL
		ledge_cooldown = 0.3
		return
	if jump_buffer > 0.0:
		jump_buffer = 0.0
		climbing = true
		var tw := create_tween()
		tw.tween_property(self, "global_position", global_position + Vector2(facing * 24.0, -66.0), 0.18)
		await tw.finished
		climbing = false
		state = State.NORMAL
		ledge_cooldown = 0.3

# ---------- ATTACK ----------

func _start_attack(step: int, counter: bool) -> void:
	state = State.ATTACK
	combo_step = step
	attack_t = 0.0
	attack_hit_done = false
	attack_buffer = 0.0
	counter_timer = 0.0
	attack_wide = counter
	running = false
	attack_kind = 4 if Input.is_action_pressed("up") else step
	var d := Input.get_axis("left", "right")
	if d != 0.0:
		facing = 1 if d > 0.0 else -1
	_set_slash(attack_kind, counter)

func _state_attack(delta: float, dir: float) -> void:
	if Input.is_action_just_pressed("dash") and _try_dash(dir):
		return
	if Input.is_action_just_pressed("skill") and _try_skill():
		return
	attack_t += delta
	var finisher := combo_step == 3
	var total := 0.42 if finisher else 0.28
	var chain_time := total - 0.12
	if not attack_hit_done and attack_t >= 0.07:
		attack_hit_done = true
		_do_hit(attack_kind, combo_step, attack_wide)
	var on_floor := is_on_floor()
	if on_floor and attack_t < 0.1:
		velocity.x = facing * 140.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
	velocity.y = minf(velocity.y + GRAVITY * 0.5 * delta, FALL_MAX)
	move_and_slide()
	_update_wall()
	if attack_buffer > 0.0 and attack_t >= chain_time:
		_start_attack((combo_step + 1) % 4, false)
		return
	if attack_t >= total:
		state = State.NORMAL
		combo_timer = 0.0 if finisher else COMBO_WINDOW

func _attack_rect(kind: int, wide: bool) -> Rect2:
	var p := global_position
	var w := 130.0 if wide else 90.0
	var x := p.x if facing > 0 else p.x - w
	match kind:
		5:
			return Rect2(p.x - 40.0, p.y - 10.0, 80.0, 110.0)
		4:
			return Rect2(p.x - 45.0, p.y - 120.0, 90.0, 100.0)
		3:
			return Rect2(x, p.y - 60.0, w, 130.0)
	return Rect2(x, p.y - 40.0, w, 80.0)

func _do_hit(kind: int, step: int, wide: bool) -> bool:
	var rect := _attack_rect(kind, wide)
	var finisher := step == 3
	var hit_any := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead:
			continue
		if rect.intersects(e.hit_rect()):
			var dir := 1 if e.global_position.x > global_position.x else -1
			var dmg := ATTACK_DAMAGE * (2 if finisher else 1)
			var knock := 420.0 if finisher else 90.0
			var stun := 0.5 if finisher else 0.1
			e.take_damage(dmg, dir, knock, stun, finisher and not is_on_floor())
			hit_any = true
	if hit_any:
		_hitstop(0.09 if finisher else 0.045)
		shake_t = 0.14 if finisher else 0.06
	return hit_any

func _set_slash(kind: int, wide: bool) -> void:
	slash_t = 0.0
	slash_face = facing
	slash_wide = wide
	slash_finisher = kind == 3
	match kind:
		0:
			slash_arc = Vector2(-1.1, 0.9)
		1:
			slash_arc = Vector2(-0.9, 1.1)
		2:
			slash_arc = Vector2(-1.6, 0.2)
		3:
			slash_arc = Vector2(-0.2, 1.9)
		_:
			slash_arc = Vector2(-2.3, -0.8)

# ---------- PARRY ----------

func _start_parry() -> void:
	state = State.PARRY
	parry_t = 0.0
	velocity.x = 0.0
	attack_buffer = 0.0

func _state_parry(delta: float) -> void:
	parry_t += delta
	velocity.x = move_toward(velocity.x, 0.0, 2400.0 * delta)
	velocity.y = minf(velocity.y + GRAVITY * delta, FALL_MAX)
	if parry_t > PARRY_ACTIVE and Input.is_action_just_pressed("dash") and _try_dash(Input.get_axis("left", "right")):
		parry_cd = 0.2
		return
	move_and_slide()
	_update_wall()
	if parry_t >= PARRY_TIME:
		state = State.NORMAL
		parry_cd = 0.3

# Dipanggil musuh/peluru. Hasil: 0 kena, 1 parry, 2 perfect parry, 3 dihindari.
func receive_attack(dmg: int, src: Node2D) -> int:
	if invulnerable or hurt_timer > 0.0:
		return R_MISS
	if state == State.PARRY and parry_t <= PARRY_ACTIVE:
		var perfect := parry_t <= PERFECT_WINDOW
		energy = minf(ENERGY_MAX, energy + (20.0 if perfect else 10.0))
		counter_timer = COUNTER_WINDOW
		hurt_timer = 0.3
		state = State.NORMAL
		velocity.x = 0.0
		_spawn_ring(global_position + Vector2(facing * 24.0, -4.0), 70.0 if perfect else 45.0, Color(0.5, 1.0, 1.0) if perfect else Color(1.0, 0.9, 0.4))
		_hitstop(0.1 if perfect else 0.06)
		shake_t = 0.12
		return R_PERFECT if perfect else R_PARRY
	hp -= dmg
	hurt_timer = 1.0
	var kdir := -1 if src.global_position.x > global_position.x else 1
	velocity = Vector2(kdir * 340.0, -280.0)
	input_lock = 0.18
	state = State.NORMAL
	attack_buffer = 0.0
	invulnerable = false
	_hitstop(0.05)
	shake_t = 0.2
	if hp <= 0:
		_respawn(true)
	return R_HIT

# ---------- SLAM ----------

func _start_slam() -> void:
	state = State.SLAM
	velocity = Vector2(0.0, SLAM_SPEED)
	running = false
	attack_buffer = 0.0

func _state_slam() -> void:
	if Input.is_action_just_pressed("dash") and _try_dash(0.0):
		return
	velocity = Vector2(0.0, SLAM_SPEED)
	move_and_slide()
	if is_on_floor():
		_slam_land()
		state = State.NORMAL
		velocity = Vector2.ZERO

func _slam_land() -> void:
	var hit := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead:
			continue
		var d: Vector2 = e.global_position - global_position
		if absf(d.x) < 130.0 and absf(d.y) < 90.0:
			e.take_damage(15, 1 if d.x > 0.0 else -1, 220.0, 0.4)
			hit = true
	_spawn_ring(global_position + Vector2(0.0, 26.0), 130.0, Color(1.0, 0.7, 0.3))
	shake_t = 0.2
	if hit:
		_hitstop(0.06)

# ---------- ELEMEN AIR ----------

func _spawn_water(mode: String, pos: Vector2, vel: Vector2, dmg: int, life: float, size: Vector2) -> void:
	var w := preload("res://water.gd").new()
	w.mode = mode
	w.position = pos
	w.vel = vel
	w.damage = dmg
	w.life = life
	w.size = size
	get_parent().add_child(w)

func _begin_cast(t: float) -> void:
	state = State.CAST
	cast_t = t
	running = false
	attack_buffer = 0.0

func _state_cast(delta: float) -> void:
	if Input.is_action_just_pressed("dash") and _try_dash(Input.get_axis("left", "right")):
		return
	cast_t -= delta
	velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
	velocity.y = minf(velocity.y + GRAVITY * 0.6 * delta, FALL_MAX)
	move_and_slide()
	_update_wall()
	if cast_t <= 0.0:
		state = State.NORMAL

# Attack 2 dan combo Air. Urutan prioritas: counter, tahan bawah, di udara, setelah serangan, biasa.
func _try_skill() -> bool:
	var on_floor := is_on_floor()
	var d := Input.get_axis("left", "right")
	if d != 0.0 and state == State.NORMAL:
		facing = 1 if d > 0.0 else -1
	if counter_timer > 0.0:
		if mana < COST_MIRROR:
			return false
		mana -= COST_MIRROR
		_mirror_tide()
		_begin_cast(0.3)
		return true
	if on_floor and Input.is_action_pressed("down"):
		if mana < COST_GEYSER:
			return false
		mana -= COST_GEYSER
		_spawn_water("geyser", global_position + Vector2(facing * 120.0, 28.0), Vector2.ZERO, 18, 0.7, Vector2(64, 220))
		_begin_cast(0.35)
		return true
	if not on_floor:
		if mana < COST_RAIN:
			return false
		mana -= COST_RAIN
		for i in 5:
			var ang := 1.5708 + (float(i) - 2.0) * 0.28
			_spawn_water("needle", global_position + Vector2(0.0, 14.0), Vector2(cos(ang), sin(ang)) * 700.0, 9, 0.9, Vector2(22, 6))
		_begin_cast(0.25)
		return true
	if state == State.ATTACK or combo_timer > 0.1:
		if mana < COST_TIDE:
			return false
		mana -= COST_TIDE
		_spawn_water("wave", global_position + Vector2(facing * 36.0, 8.0), Vector2(facing * 520.0, 0.0), 22, 0.7, Vector2(70, 70))
		_begin_cast(0.3)
		return true
	if mana < COST_NEEDLES:
		return false
	mana -= COST_NEEDLES
	for j in 3:
		var off := (float(j) - 1.0) * 0.14
		var ang2 := off if facing > 0 else PI - off
		_spawn_water("needle", global_position + Vector2(facing * 24.0, -6.0), Vector2(cos(ang2), sin(ang2)) * 760.0, 9, 0.9, Vector2(22, 6))
	_begin_cast(0.22)
	return true

func _mirror_tide() -> void:
	_spawn_water("burst", global_position, Vector2.ZERO, 14, 0.35, Vector2(260, 260))
	for pr in get_tree().get_nodes_in_group("projectiles"):
		if pr.global_position.distance_to(global_position) < 170.0 and pr.hostile:
			pr.vel = -pr.vel * 1.4
			pr.hostile = false
	hurt_timer = maxf(hurt_timer, 0.4)
	_hitstop(0.05)

# Ultimate Air: Abyss - Heavenfall (versi sederhana, tanpa sinematik)
func _start_ult() -> void:
	mana -= ULT_MANA
	energy -= ULT_ENERGY
	state = State.ULT
	ult_t = 0.0
	ult_phase = 0
	ult_start = global_position
	velocity = Vector2.ZERO
	invulnerable = true
	running = false
	attack_buffer = 0.0
	ult_targets = []
	var sx := 0.0
	var n := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.dead and e.global_position.distance_to(global_position) < 450.0:
			ult_targets.append(e)
			sx += e.global_position.x
			n += 1
	var dx := 140.0 * facing
	if n > 0:
		dx = clampf(sx / float(n) - global_position.x, -220.0, 220.0)
	var q := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(dx, 0.0), 1)
	var r := get_world_2d().direct_space_state.intersect_ray(q)
	if not r.is_empty():
		var hx: float = r["position"].x
		dx = (hx - global_position.x) - signf(dx) * 26.0
	ult_air = ult_start + Vector2(dx, -210.0)
	ult_land = ult_start + Vector2(dx, 0.0)
	if dx != 0.0:
		facing = 1 if dx > 0.0 else -1

func _state_ult(delta: float) -> void:
	ult_t += delta
	velocity = Vector2.ZERO
	invulnerable = true
	if ult_t < 0.4:
		if ult_phase == 0:
			ult_phase = 1
			for e in ult_targets:
				if is_instance_valid(e) and not e.dead:
					_spawn_water("geyser", Vector2(e.global_position.x, e.global_position.y + e.body_size.y / 2.0), Vector2.ZERO, 14, 0.8, Vector2(70, 260))
					e.launch(-1000.0, 1.4)
		shake_t = 0.1
	elif ult_t < 0.9:
		var k := (ult_t - 0.4) / 0.5
		global_position = ult_start.lerp(ult_air, 1.0 - pow(1.0 - k, 3.0))
	elif ult_t < 1.12:
		var k2 := (ult_t - 0.9) / 0.22
		global_position = ult_air.lerp(ult_land, k2 * k2)
	else:
		_ult_explode()
		state = State.NORMAL
		invulnerable = false
		hurt_timer = 0.8
		velocity = Vector2.ZERO

func _ult_explode() -> void:
	global_position = ult_land
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead:
			continue
		var d: Vector2 = e.global_position - global_position
		if d.length() < 330.0:
			e.take_damage(55, 1 if d.x > 0.0 else -1, 420.0, 0.8, false)
	_spawn_ring(global_position + Vector2(0.0, 26.0), 330.0, Color(0.45, 0.8, 1.0))
	_spawn_ring(global_position + Vector2(0.0, 26.0), 220.0, Color(0.8, 0.95, 1.0))
	shake_t = 0.5
	_hitstop(0.14)

# ---------- UTIL ----------

func _update_wall() -> void:
	if is_on_floor():
		wall_normal_x = 0.0
		wall_time = 0.0
		return
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var n := col.get_normal()
		var obj := col.get_collider()
		if absf(n.x) > 0.9 and obj is Node and (obj as Node).is_in_group("wall"):
			wall_normal_x = n.x
			wall_time = WALL_GRACE
			return
	if wall_time <= 0.0:
		wall_normal_x = 0.0

func _ray_hits(from_off: Vector2, length: float) -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + from_off
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(facing * length, 0.0))
	q.collision_mask = 1
	q.exclude = [get_rid()]
	return not space.intersect_ray(q).is_empty()

func _respawn(heal: bool) -> void:
	global_position = spawn_point
	velocity = Vector2.ZERO
	state = State.NORMAL
	climbing = false
	if heal:
		hp = max_hp
		energy = ENERGY_MAX
		hurt_timer = 1.5

func _check_checkpoints() -> void:
	for c in get_tree().get_nodes_in_group("checkpoint"):
		var d: Vector2 = c.global_position - global_position
		if absf(d.x) < 70.0 and absf(d.y) < 100.0 and spawn_point != c.global_position:
			spawn_point = c.global_position
			hp = max_hp
			energy = ENERGY_MAX
			var vis := c.get_child(0)
			if vis is CanvasItem:
				(vis as CanvasItem).modulate = Color(1, 1, 1, 1)

func _spawn_ring(pos: Vector2, radius: float, color: Color) -> void:
	var fx := preload("res://fx.gd").new()
	fx.position = pos
	fx.max_radius = radius
	fx.color = color
	get_parent().add_child(fx)

func _hitstop(duration: float) -> void:
	hitstop_id += 1
	var my_id := hitstop_id
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	if my_id == hitstop_id:
		Engine.time_scale = 1.0

func _draw() -> void:
	if slash_t < 0.14:
		var k := 1.0 - slash_t / 0.14
		var a0 := slash_arc.x
		var a1 := slash_arc.y
		if slash_face < 0:
			var t0 := PI - a1
			a1 = PI - a0
			a0 = t0
		var sc := Color(1.0, 0.8, 0.3, k) if slash_finisher else Color(0.85, 0.95, 1.0, k)
		draw_arc(Vector2(slash_face * 8.0, -2.0), 90.0 if slash_wide else 66.0, a0, a1, 16, sc, 10.0)
	if state == State.PARRY:
		var perfect := parry_t <= PERFECT_WINDOW
		var pc := Color(0.5, 1.0, 1.0, 0.9) if perfect else Color(1.0, 0.9, 0.4, 0.7)
		if parry_t > PARRY_ACTIVE:
			pc.a = 0.25
		var base := 0.0 if facing > 0 else PI
		draw_arc(Vector2(facing * 6.0, -2.0), 42.0, base - 1.0, base + 1.0, 16, pc, 6.0)
