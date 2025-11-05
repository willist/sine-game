extends Area2D

signal game_over

var wave: Node2D = null
var surfer_x: float = 300.0

func _ready():
	# Add collision shape
	var shape = CircleShape2D.new()
	shape.radius = 15.0
	$CollisionShape2D.shape = shape

func _process(_delta):
	if wave:
		# Get the y position from the wave at the surfer's x position
		var wave_y = wave.get_wave_y_at_x(surfer_x)
		position = Vector2(surfer_x, wave_y)

func set_wave(w: Node2D):
	wave = w

func _on_area_entered(area):
	if area.is_in_group("obstacles"):
		handle_game_over()

func handle_game_over():
	print("Game Over! Hit an obstacle!")
	game_over.emit()
	await get_tree().create_timer(0.1).timeout
	get_tree().reload_current_scene()
