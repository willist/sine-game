extends Node2D

@onready var wave = $Wave
@onready var surfer = $Surfer
@onready var obstacle_timer = $ObstacleTimer
@onready var score_label = $UI/ScoreLabel
@onready var high_score_label = $UI/HighScoreLabel
@onready var pause_overlay = $UI/PauseOverlay
@onready var game_over_overlay = $UI/GameOverOverlay
@onready var final_score_label = $UI/GameOverOverlay/FinalScoreLabel
@onready var final_best_label = $UI/GameOverOverlay/FinalBestLabel

var obstacle_scene = preload("res://obstacle.tscn")
var score: int = 0
var high_score: int = 0
var game_time: float = 0.0

const SAVE_PATH = "user://high_score.save"

func _ready():
	surfer.set_wave(wave)
	surfer.game_over.connect(_on_game_over)
	pause_overlay.hide()
	game_over_overlay.hide()
	load_high_score()
	high_score_label.text = "Best: " + str(high_score)

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

func load_high_score():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		high_score = file.get_32()
		file.close()
	else:
		high_score = 0

func save_high_score():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_32(high_score)
	file.close()

func _on_game_over():
	if score > high_score:
		high_score = score
		high_score_label.text = "Best: " + str(high_score)
		save_high_score()

	# Update game over overlay
	final_score_label.text = "Score: " + str(score)
	final_best_label.text = "Best: " + str(high_score)

	# Pause the game and show game over screen
	get_tree().paused = true
	game_over_overlay.show()

func _on_play_again_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()
