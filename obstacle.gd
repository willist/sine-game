extends Area2D

var speed: float = 150.0

func _ready():
	# Add collision shape
	var shape = RectangleShape2D.new()
	shape.size = Vector2(50, 50)
	$CollisionShape2D.shape = shape

func _process(delta):
	# Move obstacle to the left
	position.x -= speed * delta

	# Remove obstacle when it goes off screen
	if position.x < -100:
		queue_free()

func set_speed(s: float):
	speed = s
