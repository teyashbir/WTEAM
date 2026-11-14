extends Area2D

@export var speed: float = 950.0
@export var knockback_force: float = 680.0

var direction: Vector2 = Vector2.RIGHT
var is_enemy_bullet: bool = false
var start_x: float = 0.0

func _ready() -> void:
	start_x = global_position.x
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()
	if is_enemy_bullet:
		$Core.color = Color(1.0, 0.25, 0.3)
		$Glow.color = Color(1.0, 0.15, 0.2, 0.4)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	if absf(global_position.x - start_x) > 1500.0 or absf(global_position.y) > 2000.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_knockback"):
		if is_enemy_bullet and body.is_in_group("bots"):
			return
		if not is_enemy_bullet and body.is_in_group("player"):
			return
		body.take_knockback(direction, knockback_force)
		queue_free()
	elif body is StaticBody2D:
		queue_free()
