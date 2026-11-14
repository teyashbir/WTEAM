extends Area2D

signal collected

var base_y: float = 0.0
var time: float = 0.0

func _ready() -> void:
	base_y = position.y
	time = randf() * 6.28
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	time += delta * 4.5
	position.y = base_y + sin(time) * 5.0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collected.emit()
		queue_free()
