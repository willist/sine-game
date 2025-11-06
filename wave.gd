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

# Touch control tracking
var touch_points: Dictionary = {}
var last_single_touch_pos: Vector2 = Vector2.ZERO
var last_two_finger_distance: float = 0.0
var last_two_finger_angle: float = 0.0

func _ready():
	screen_width = get_viewport_rect().size.x
	screen_height = get_viewport_rect().size.y
	generate_wave()

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
		else:
			touch_points.erase(event.index)
			# Reset tracking when fingers lift
			if touch_points.size() == 0:
				last_two_finger_distance = 0.0
	elif event is InputEventScreenDrag:
		touch_points[event.index] = event.position

func _process(delta):
	# Handle input
	handle_input(delta)

	# Update wave offset for animation
	wave_offset += wave_speed * delta

	# Generate wave points
	generate_wave()

func handle_input(delta):
	# Handle touch controls
	handle_touch_input(delta)

	var shift_pressed = Input.is_key_pressed(KEY_SHIFT)

	# Shift + Up/Down: Amplitude control (stretch and squeeze)
	if Input.is_action_pressed("slide_wave_up"):
		amplitude = clamp(amplitude + amplitude_change_speed * delta, MIN_AMPLITUDE, MAX_AMPLITUDE)
	if Input.is_action_pressed("slide_wave_down"):
		amplitude = clamp(amplitude - amplitude_change_speed * delta, MIN_AMPLITUDE, MAX_AMPLITUDE)

	# Clamp wave_y_position to keep wave on screen after amplitude changes
	wave_y_position = clamp(wave_y_position, amplitude, screen_height - amplitude)

	# Up/Down: Translate wave vertically (move the wave)
	if not shift_pressed:
		if Input.is_action_pressed("move_up"):
			wave_y_position -= wave_y_speed * delta
		if Input.is_action_pressed("move_down"):
			wave_y_position += wave_y_speed * delta

	# Clamp wave_y_position to keep wave on screen
	wave_y_position = clamp(wave_y_position, amplitude, screen_height - amplitude)

	# Shift + Left/Right: Wavelength control (stretch and squeeze)
	var old_wavelength = wavelength

	if Input.is_action_pressed("slide_wave_left"):
		wavelength = clamp(wavelength - wavelength_change_speed * delta, MIN_WAVELENGTH, MAX_WAVELENGTH)
	if Input.is_action_pressed("slide_wave_right"):
		wavelength = clamp(wavelength + wavelength_change_speed * delta, MIN_WAVELENGTH, MAX_WAVELENGTH)

	# Adjust wave_offset to keep surfer at same phase position
	if wavelength != old_wavelength:
		var phase_at_surfer = (SURFER_X / old_wavelength + wave_offset / old_wavelength)
		wave_offset = (phase_at_surfer - SURFER_X / wavelength) * wavelength

	# Left/Right: Translate wave horizontally (move the wave)
	if not shift_pressed:
		if Input.is_action_pressed("decrease_wavelength"):
			# Left: normal speed
			wave_offset += wave_speed * delta
		if Input.is_action_pressed("increase_wavelength"):
			# Right: double speed
			wave_offset -= wave_speed * 2.0 * delta

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

func handle_touch_input(delta):
	var num_touches = touch_points.size()

	if num_touches == 1:
		# Single finger drag - move the wave
		var touch_pos = touch_points.values()[0]

		if last_single_touch_pos != Vector2.ZERO:
			var touch_delta = touch_pos - last_single_touch_pos

			# Vertical movement
			wave_y_position += touch_delta.y
			wave_y_position = clamp(wave_y_position, amplitude, screen_height - amplitude)

			# Horizontal movement (translate wave)
			wave_offset -= touch_delta.x * 0.5

		last_single_touch_pos = touch_pos

	elif num_touches == 2:
		# Two finger pinch/stretch - affect wavelength or amplitude
		var touches = touch_points.values()
		var touch1 = touches[0]
		var touch2 = touches[1]

		# Calculate distance and angle between touches
		var distance = touch1.distance_to(touch2)
		var delta_vec = touch2 - touch1
		var angle = abs(delta_vec.angle())

		# Initialize on first two-finger touch
		if last_two_finger_distance == 0.0:
			last_two_finger_distance = distance
			last_two_finger_angle = angle
		else:
			var distance_change = distance - last_two_finger_distance

			# Determine if gesture is more horizontal or vertical
			# angle near 0 or PI is horizontal, near PI/2 is vertical
			var angle_from_horizontal = abs(angle)
			if angle_from_horizontal > PI / 2:
				angle_from_horizontal = PI - angle_from_horizontal

			var is_horizontal = angle_from_horizontal < PI / 4

			if is_horizontal:
				# Affect wavelength
				var old_wavelength = wavelength
				wavelength += distance_change * 0.5
				wavelength = clamp(wavelength, MIN_WAVELENGTH, MAX_WAVELENGTH)

				# Adjust wave_offset to keep surfer at same phase position
				if wavelength != old_wavelength:
					var phase_at_surfer = (SURFER_X / old_wavelength + wave_offset / old_wavelength)
					wave_offset = (phase_at_surfer - SURFER_X / wavelength) * wavelength
			else:
				# Affect amplitude
				amplitude += distance_change * 0.5
				amplitude = clamp(amplitude, MIN_AMPLITUDE, MAX_AMPLITUDE)
				wave_y_position = clamp(wave_y_position, amplitude, screen_height - amplitude)

			last_two_finger_distance = distance
			last_two_finger_angle = angle
	else:
		# No touches or more than 2 - reset
		last_single_touch_pos = Vector2.ZERO
		last_two_finger_distance = 0.0
