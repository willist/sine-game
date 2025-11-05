extends Node2D

@onready var wave = $Wave
@onready var surfer = $Surfer
@onready var obstacle_timer = $ObstacleTimer
@onready var score_label = $UI/ScoreLabel
@onready var pause_overlay = $UI/PauseOverlay

var obstacle_scene = preload("res://obstacle.tscn")
var score: int = 0
var game_time: float = 0.0

func _ready():
	surfer.set_wave(wave)
	pause_overlay.hide()

func _unhandled_input(event):
	if event.is_action_pressed("toggle_pause"):
		toggle_pause()

func _process(delta):
	if not get_tree().paused:
		game_time += delta
		score = int(game_time * 10)
		score_label.text = "Score: " + str(score)

		# Increase difficulty over time
		var difficulty = 1.0 + (game_time / 30.0)
		obstacle_timer.wait_time = max(1.0, 2.0 / difficulty)

func toggle_pause():
	get_tree().paused = !get_tree().paused
	if get_tree().paused:
		pause_overlay.show()
	else:
		pause_overlay.hide()

func _on_obstacle_timer_timeout():
	spawn_obstacle()

func spawn_obstacle():
	var obstacle = obstacle_scene.instantiate()
	obstacle.process_mode = Node.PROCESS_MODE_PAUSABLE

	# Random Y position
	var random_y = randf_range(150, 570)

	# Spawn off the right side of the screen
	obstacle.position = Vector2(1380, random_y)

	# Match wave speed
	obstacle.set_speed(wave.wave_speed)

	add_child(obstacle)
