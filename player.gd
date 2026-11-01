extends CharacterBody2D
# Syzu - movement prototype (Milestone 2).
# Semua angka di bawah bisa di-tune. Visual masih placeholder (kotak).

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
const ENERGY_REGEN := 4.0   # 20 per 5 detik (usulan, belum final)

enum State { NORMAL, DASH, LEDGE }

var state := State.NORMAL
var energy := ENERGY_MAX
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
var wall_normal_x := 0.0
var wall_time := 0.0
var input_lock := 0.0
var ledge_cooldown := 0.0
var invulnerable := false
var climbing := false
var spawn_point := Vector2.ZERO

func _ready() -> void:
	add_to_group("player")
	spawn_point = position
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 56)
	shape.shape = rect
	add_child(shape)
	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	cam.limit_left = -200
	cam.limit_right = 4240
	cam.limit_bottom = 800
	add_child(cam)

func _physics_process(delta: float) -> void:
	energy = minf(ENERGY_MAX, energy + ENERGY_REGEN * delta)
	coyote = maxf(0.0, coyote - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	input_lock = maxf(0.0, input_lock - delta)
	ledge_cooldown = maxf(0.0, ledge_cooldown - delta)
	wall_time = maxf(0.0, wall_time - delta)
	if Input.is_action_just_pressed("jump"):
		jump_buffer = JUMP_BUFFER

	var dir := Input.get_axis("left", "right")
	if input_lock > 0.0:
		dir = 0.0
	elif dir != 0.0:
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
		_:
			_state_normal(delta, dir)

	if global_position.y > 1100.0:
		global_position = spawn_point
		velocity = Vector2.ZERO
		state = State.NORMAL
	queue_redraw()

func _state_normal(delta: float, dir: float) -> void:
	var on_floor := is_on_floor()
	if on_floor:
		coyote = COYOTE_TIME
		double_jump_used = false
		air_dash_used = false
	var on_wall := not on_floor and wall_time > 0.0 and wall_normal_x != 0.0

	# Dash
	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0 and energy >= DASH_COST:
		if on_floor or not air_dash_used:
			_start_dash(dir, on_floor, on_wall)
			return

	# Horizontal
	if input_lock <= 0.0:
		var target := dir * (RUN_SPEED if running else WALK_SPEED)
		var accel := ACCEL_GROUND if on_floor else ACCEL_AIR
		velocity.x = move_toward(velocity.x, target, accel * delta)

	# Gravity + wall slide
	var sliding := on_wall and velocity.y > 0.0 and dir == -wall_normal_x
	if sliding:
		velocity.y = minf(velocity.y + GRAVITY * delta, WALL_SLIDE_SPEED)
	else:
		velocity.y = minf(velocity.y + GRAVITY * delta, FALL_MAX)

	# Jump / wall jump / double jump
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

	# Ledge grab (harus menekan arah ke tepi sambil jatuh)
	if not on_floor and velocity.y >= 0.0 and ledge_cooldown <= 0.0 and dir == float(facing):
		if _ray_hits(Vector2(0, -18), 22.0) and not _ray_hits(Vector2(0, -36), 22.0):
			state = State.LEDGE
			velocity = Vector2.ZERO
			return

	move_and_slide()
	_update_wall()

func _start_dash(dir: float, on_floor: bool, on_wall: bool) -> void:
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
	running = false
	state = State.DASH

func _state_dash(delta: float) -> void:
	dash_timer += delta
	invulnerable = dash_timer >= IFRAME_FROM and dash_timer <= IFRAME_TO
	velocity = dash_dir * (DOWN_DASH_SPEED if down_dash else DASH_SPEED)
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
	q.exclude = [get_rid()]
	return not space.intersect_ray(q).is_empty()

func _draw() -> void:
	var a := 0.45 if invulnerable else 1.0
	var f := float(facing)
	draw_rect(Rect2(f * -22.0 - 6.0, 4, 12, 14), Color(0.97, 0.55, 0.15, a))      # ekor
	draw_rect(Rect2(-14, -28, 28, 56), Color(0.97, 0.55, 0.15, a))                # badan oranye
	draw_rect(Rect2(-14, -2, 28, 30), Color(0.96, 0.95, 0.92, a))                 # kimono putih
	draw_rect(Rect2(-14, 8, 28, 5), Color(0.8, 0.12, 0.12, a))                    # aksen merah
	draw_rect(Rect2(f * 4.0 - 4.0, -20, 14, 10), Color(0.12, 0.12, 0.18, a))      # masker
	draw_rect(Rect2(-8, -36, 6, 10), Color(0.97, 0.55, 0.15, a))                  # telinga
	draw_rect(Rect2(2, -36, 6, 10), Color(0.97, 0.55, 0.15, a))
	draw_rect(Rect2(f * -16.0 - 2.0, -4, 4, 22), Color(0.25, 0.25, 0.3, a))       # katana di punggung
