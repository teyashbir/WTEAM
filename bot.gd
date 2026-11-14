extends CharacterBody2D

signal defeated

@export var move_speed: float = 135.0
@export var bounce_force: float = -360.0
@export var bullet_scene: PackedScene

var gravity: float = 1200.0
var knockback: Vector2 = Vector2.ZERO
var knockback_multiplier: float = 1.0
var direction: float = -1.0
var shoot_timer: float = 1.4
var player: Node2D = null
var is_dead: bool = false
var visual_scale: Vector2 = Vector2.ONE
var hit_flash_timer: float = 0.0

@onready var visual_root: Node2D = $VisualRoot
@onready var body_rect: ColorRect = $VisualRoot/Body
@onready var gun_pivot: Node2D = $GunPivot
@onready var hit_sfx: AudioStreamPlayer = $HitSFX
@onready var shoot_sfx: AudioStreamPlayer = $ShootSFX

func _ready() -> void:
	add_to_group("bots")
	shoot_timer = randf_range(0.9, 1.8)
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0.0 and body_rect:
			body_rect.color = Color(0.88, 0.28, 0.22, 1.0)

	# Continuous bouncing when touching the floor!
	if is_on_floor():
		velocity.y = bounce_force + randf_range(-40.0, 20.0)
		visual_scale = Vector2(1.25, 0.78)
	else:
		velocity.y += gravity * delta

	var aim_dir: Vector2 = Vector2(direction, 0)
	if is_instance_valid(player):
		var dx: float = player.global_position.x - global_position.x
		var dy: float = player.global_position.y - global_position.y
		var dist: float = absf(dx)

		# Smart AI: face the player and pursue or keep optimal range
		if dist < 640.0:
			var desired_dir: float = signf(dx) if dx != 0.0 else -1.0
			aim_dir = Vector2(desired_dir, clampf(dy / 400.0, -0.35, 0.35)).normalized()

			# Smart spacing: move toward player if far, strafe/bounce if close
			if dist > 180.0:
				direction = desired_dir

			# Smart high-bounce when player aims at same height
			if is_on_floor() and absf(dy) < 60.0 and randf() < 0.35:
				velocity.y = bounce_force * 1.32

			shoot_timer -= delta
			if shoot_timer <= 0.0 and absf(dy) < 220.0:
				shoot(aim_dir)
				shoot_timer = randf_range(1.3, 2.2)

	# Smart Edge Detection: Don't walk off the platform unless knocked back!
	if knockback.length() < 45.0:
		var space_state := get_world_2d().direct_space_state
		var check_start := global_position + Vector2(direction * 26.0, 10.0)
		var check_end := check_start + Vector2(0, 75.0)
		var query := PhysicsRayQueryParameters2D.create(check_start, check_end)
		query.exclude = [get_rid()]
		var result := space_state.intersect_ray(query)
		if result.is_empty():
			direction *= -1.0

	gun_pivot.rotation = aim_dir.angle()

	velocity.x = (direction * move_speed) + knockback.x
	knockback = knockback.move_toward(Vector2.ZERO, 1250.0 * delta)
	move_and_slide()

	visual_scale = visual_scale.lerp(Vector2.ONE, 12.0 * delta)
	if visual_root:
		visual_root.scale = visual_scale

	if global_position.y > 820.0:
		is_dead = true
		defeated.emit()
		queue_free()

func shoot(aim_dir: Vector2) -> void:
	if bullet_scene == null:
		return
	if shoot_sfx:
		shoot_sfx.play()
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position + (aim_dir * 32.0)
	bullet.direction = aim_dir
	bullet.is_enemy_bullet = true
	bullet.speed = 560.0
	bullet.knockback_force = 480.0
	get_parent().add_child(bullet)
	knockback -= aim_dir * 110.0
	visual_scale = Vector2(1.2, 0.85)

func take_knockback(hit_dir: Vector2, force: float) -> void:
	if hit_sfx:
		hit_sfx.play()
	knockback = hit_dir * force * knockback_multiplier * 1.35
	velocity.y = -360.0
	knockback_multiplier += 0.45
	visual_scale = Vector2(0.72, 1.35)
	hit_flash_timer = 0.14
	if body_rect:
		body_rect.color = Color(1.0, 0.95, 0.85, 1.0)
