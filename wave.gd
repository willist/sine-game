extends Node2D

@onready var line = $Line2D

# Wave parameters
var amplitude: float = 100.0
var wavelength: float = 200.0
var wave_speed: float = 200.0
var wave_offset: float = 0.0

# Wave vertical position
var wave_y_position: float = 400.0

# Control parameters
var amplitude_change_speed: float = 100.0
var wavelength_change_speed: float = 50.0
var wave_y_speed: float = 200.0

# Constraints
const MIN_AMPLITUDE = 75.0
const MAX_AMPLITUDE = 400.0
const MIN_WAVELENGTH = 150.0
const MAX_WAVELENGTH = 300.0

# Screen dimensions
var screen_width: float = 1280.0
var screen_height: float = 720.0

# Surfer position for anchoring wavelength changes
const SURFER_X: float = 300.0

func _ready():
	screen_width = get_viewport_rect().size.x
	screen_height = get_viewport_rect().size.y
	generate_wave()

func _process(delta):
	# Handle input
	handle_input(delta)

	# Update wave offset for animation
	wave_offset += wave_speed * delta

	# Generate wave points
	generate_wave()

func handle_input(delta):
	var shift_pressed = Input.is_key_pressed(KEY_SHIFT)

	# Amplitude control (W/S or Up/Down) - only when shift is not pressed
	if not shift_pressed:
		if Input.is_action_pressed("move_up"):
			amplitude = clamp(amplitude + amplitude_change_speed * delta, MIN_AMPLITUDE, MAX_AMPLITUDE)
		if Input.is_action_pressed("move_down"):
			amplitude = clamp(amplitude - amplitude_change_speed * delta, MIN_AMPLITUDE, MAX_AMPLITUDE)

	# Clamp wave_y_position to keep wave on screen after amplitude changes
	wave_y_position = clamp(wave_y_position, amplitude, screen_height - amplitude)

	# Shift + Up/Down: Translate wave vertically
	if Input.is_action_pressed("slide_wave_up"):
		wave_y_position -= wave_y_speed * delta
	if Input.is_action_pressed("slide_wave_down"):
		wave_y_position += wave_y_speed * delta

	# Clamp wave_y_position to keep wave on screen
	wave_y_position = clamp(wave_y_position, amplitude, screen_height - amplitude)

	# Shift + Left/Right: Translate wave horizontally
	if Input.is_action_pressed("slide_wave_left"):
		wave_offset += wave_speed * delta
	if Input.is_action_pressed("slide_wave_right"):
		wave_offset -= wave_speed * delta

	# A/D or Left/Right: Wavelength control (anchored at surfer position) - only when shift is not pressed
	if not shift_pressed:
		var old_wavelength = wavelength

		if Input.is_action_pressed("decrease_wavelength"):
			wavelength = clamp(wavelength - wavelength_change_speed * delta, MIN_WAVELENGTH, MAX_WAVELENGTH)
		if Input.is_action_pressed("increase_wavelength"):
			wavelength = clamp(wavelength + wavelength_change_speed * delta, MIN_WAVELENGTH, MAX_WAVELENGTH)

		# Adjust wave_offset to keep surfer at same phase position
		if wavelength != old_wavelength:
			var phase_at_surfer = (SURFER_X / old_wavelength + wave_offset / old_wavelength)
			wave_offset = (phase_at_surfer - SURFER_X / wavelength) * wavelength

func generate_wave():
	var points = PackedVector2Array()
	var num_points = 200

	for i in range(num_points):
		var x = (float(i) / num_points) * screen_width
		var wave_value = sin((x / wavelength + wave_offset / wavelength) * TAU)
		var y = wave_y_position + wave_value * amplitude
		points.append(Vector2(x, y))

	line.points = points

# Function to get the y position of the wave at a given x coordinate
func get_wave_y_at_x(x: float) -> float:
	var wave_value = sin((x / wavelength + wave_offset / wavelength) * TAU)
	return wave_y_position + wave_value * amplitude

# Function to get the angle of the wave at a given x coordinate (for surfer rotation)
func get_wave_angle_at_x(x: float) -> float:
	var dx = 1.0
	var y1 = get_wave_y_at_x(x)
	var y2 = get_wave_y_at_x(x + dx)
	return atan2(y2 - y1, dx)
