extends Node2D
class_name PendulumWave

## Amount of Pendulums. If using sounds, this should ideally be a multiple of the amount of sounds. This will also be the max BPM used, assuming a bpm_multiplier of 1.
@export var pendulum_count : int = 15
## Multiplies the BPM of each pendulum. With large Pendulum counts, this should be ideally below 1 and get smaller the more Pendulums added.
@export var bpm_multiplier : float = 1
## Modifies the amount subtracted from the max BPM of each pendulum, depending on the pendulum number
@export_range(0.001, 1)
var bpm_ratio : float = 1
## Minimum Pendulum length.
@export var min_length : float = 10
## Maximum Pendulum length.
@export var max_length : float = 1000
## Adjusts the size of the Pendulum Sprite
@export var pendulum_scale : float = 1
## Angle of arc that Pendulums swing through.
@export_range(0, 360)
var swing_angle : float = 90
## Angle that Pendulum will be at bottom dead center. Can cause unexpected issues if not 90 and using curved paths.
@export_range(0, 360)
var gravity_angle : float = 90
## Start position of RightLimitLine. This line will end at Max Length at an angle of 0.5 -Swing Angle + Gravity Angle from the start position.
@export var right_origin : Vector2 = Vector2(0,0)
## Start position of LeftLimitLine. This line will end at Max Length at an angle of 0.5 Swing Angle + Gravity Angle from the start position.
@export var left_origin : Vector2 = Vector2(0,0)
## If true, Pendulums will follow a circular arc. If false, they will follow a straight line.
@export var curved_path : bool = true
## Ease type to use for Pendulum Tweens
@export var ease_type : Tween.EaseType = Tween.EASE_IN_OUT
## Transition type to use for Pendulum Tweens. Linear will create a hard direction change, while Sine will create a more natural pendulum swing.
@export var transition_type : Tween.TransitionType
## Optionally draw lines between Pendulums using PendulumLine node.
@export var draw_lines_between_pendulums : bool = true
## Add an offset to LimitLines to account for line thickness and Pendulum sprite size. Needs further refinement.
@export var use_limit_offset : bool = true
## Optionally include audio
@export var use_audio : bool = true
## Path to folder containing audio wavs. Make sure the files contained in this folder are in the order you wish to use them, as it will be looped through linlearly.
@export var audio_path : String

# Get PendulumLine node
@onready var pendulum_line : Line2D = %PendulumLine
# Get LeftLimitLine node
@onready var left_line : Line2D = %LeftLimitLine
# Get RightLimitLine node
@onready var right_line : Line2D = %RightLimitLine
# Optimal distance for bezier curve control points to create a circle, based on 4 points
@onready var optimal_control_point_distance = 0.552284749831
# modification of optimal_control_point_distance to account for fractional circular arc. This will be equal to optimal_control_point_distance when swing_angle is 360.
@onready var curve_factor = optimal_control_point_distance * (swing_angle / 360)

# Get Pendulum scene as a prefab
var pendulum = preload("res://Scenes/Pendulum.tscn")
# Used to store all Pendulums in an Array
var pendulums = []
# Used to store all audio streams in an Array
var audio_streams = []
# Offset calculated for LimitLines
var limit_line_offset : float
# Center position between both LimitLines
var center_origin : Vector2

# Returns a Vector2 point when given an origin point, a distance, and an angle from the origin.
func calculate_point(dist : float, angle : float, origin : Vector2):
	var x = dist * cos(deg_to_rad(angle))
	var y = dist * sin(deg_to_rad(angle))
	return origin + Vector2(x,y)

# Loops through wav files found in audio_path and loads them into audio_streams
func prepare_audio(path):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
			elif file_name.ends_with(".wav"):
				print("Found file: " + file_name)
				audio_streams.push_back(load(path + file_name))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

# Set up LimitLines
func _set_limit_lines():
	var offset_check = 0
	if use_limit_offset:
		offset_check = 1
	limit_line_offset = (16 * pendulum_scale) + (left_line.width * 0.5) * offset_check
	var left_line_end = calculate_point(max_length, gravity_angle + (swing_angle * 0.5), left_origin)
	var right_line_end = calculate_point(max_length, gravity_angle + (-swing_angle * 0.5), right_origin)
	left_line.add_point(Vector2(left_origin.x, left_origin.y - limit_line_offset))
	left_line.add_point(Vector2(left_line_end.x, left_line_end.y - limit_line_offset))
	right_line.add_point(Vector2(right_origin.x, right_origin.y - limit_line_offset))
	right_line.add_point(Vector2(right_line_end.x, right_line_end.y - limit_line_offset))
	var center_origin_base = right_origin.lerp(left_origin, 0.5)
	center_origin = Vector2(center_origin_base.x, center_origin_base.y - limit_line_offset)

# Set up Pendulums
func _create_pendulums():
	# max bpm = number of Pendulums, and will decrease with each new pendulum created
	var current_bpm = pendulum_count * bpm_multiplier
	# Loop for each Pendulum to create
	for n in pendulum_count:
		# Create Pendulum node
		var pendulum_node : Pendulum = pendulum.instantiate()
		# Calculate Pendulum length based on Pendulum number and min / max lengths
		var pendulum_length = lerp(min_length, max_length, (float)(n+1) / pendulum_count)
		# Calculate Pendulum BPM based on Pendulum number and bpm_multiplier
		#var pendulum_bpm : float = (pendulum_count - (n * bpm_ratio)) * bpm_multiplier
		# Create Curve2D for Pendulum Path
		var curve = Curve2D.new()
		# Calculate bezier control point distance for this specific Pendulum path
		var control_distance = curve_factor * pendulum_length
		# Create 'out' control point for start point on curve, only added if using a curved path
		var start_point_out = Vector2()
		if curved_path:
			start_point_out = calculate_point(control_distance, gravity_angle + (-swing_angle * 0.5) + 90, Vector2())
		# Add start point to curve with control point. Start point is along the RightLimitLine at the pendulum length
		curve.add_point(calculate_point(pendulum_length, gravity_angle + (-swing_angle * 0.5), right_origin), Vector2(), start_point_out)
		
		# If using a curved path, add 3 additional points at equal lengths between start point and end point, and calculate 'in' and 'out' control points
		if curved_path:
			# right - center
			var right_center_pos = calculate_point(pendulum_length, gravity_angle + (-swing_angle * 0.25), right_origin.lerp(center_origin, 0.5))
			var right_center_pos_in = calculate_point(control_distance, gravity_angle + (-swing_angle * 0.25) - 90, Vector2())
			var right_center_pos_out = calculate_point(control_distance, gravity_angle + (-swing_angle * 0.25) + 90, Vector2())
			curve.add_point(right_center_pos, right_center_pos_in, right_center_pos_out)
			
			# center
			var center_pos = calculate_point(pendulum_length, gravity_angle, center_origin)
			var center_pos_in = calculate_point(control_distance, gravity_angle - 90, Vector2())
			var center_pos_out = calculate_point(control_distance, gravity_angle + 90, Vector2())
			curve.add_point(center_pos, center_pos_in, center_pos_out)
			
			# center - left
			var center_left_pos = calculate_point(pendulum_length, gravity_angle + (swing_angle * 0.25), left_origin.lerp(center_origin, 0.5))
			var center_left_pos_in = calculate_point(control_distance, gravity_angle + (swing_angle * 0.25) - 90, Vector2())
			var center_left_pos_out = calculate_point(control_distance, gravity_angle + (swing_angle * 0.25) + 90, Vector2())
			curve.add_point(center_left_pos, center_left_pos_in, center_left_pos_out)
		
		# Create 'in' control point for end point on curve, only added if using a curved path
		var end_point_in = Vector2()
		if curved_path:
			end_point_in = calculate_point(control_distance, gravity_angle + (swing_angle * 0.5) - 90, Vector2())
		# Add end point to curve with control point. End point is along the LeftLimitLine at the pendulum length
		curve.add_point(calculate_point(pendulum_length, gravity_angle + (swing_angle * 0.5), left_origin), end_point_in, Vector2())
		
		# Add Curve2D to PathFollow2D
		pendulum_node.set_curve(curve)
		# Set BPM of Pendulum
		pendulum_node.pendulum_bpm = current_bpm
		# Set Ease Type of Pendulum
		pendulum_node.ease_type = ease_type
		# Set Transition type of Pendulum
		pendulum_node.transition_type = transition_type
		# Set size of Pendulum
		pendulum_node.get_child(0).get_child(0).scale = Vector2(pendulum_scale, pendulum_scale)
		# If using audio, add the corresponding audio file from audio_streams to the Pendulum SoundQueue. Using modulus to loop through audio_streams when it gets to the end.
		if use_audio:
			pendulum_node.get_child(0).get_node("SoundQueue").get_child(0).stream = audio_streams[n % audio_streams.size()]
		# Add Pendulum node to scene
		add_child(pendulum_node)
		# Add pendulum to Pendulums Array
		pendulums.push_back(pendulum_node)
		# decrement current BPM
		current_bpm -= (bpm_multiplier * bpm_ratio)
	
	# If drawing lines between Pendulums, add points to the line at center_origin and all Pendulum positions
	if draw_lines_between_pendulums:
		pendulum_line.add_point(center_origin, 0)
		for p in pendulums:
			pendulum_line.add_point(p.get_child(0).position, p.get_index() + 1)

# Called when scene is loaded
func _ready():
	# Prepare audio files is using audio
	if use_audio:
		prepare_audio(audio_path)
	# Set up LimitLines
	_set_limit_lines()
	# Create Pendulums
	_create_pendulums()
	# calculate Pendulum Wave period (time is takes to complete a full cycle) and print to log
	var period_seconds : float = ((bpm_multiplier * 2) / bpm_ratio) * 60
	var period_minutes = floor((bpm_multiplier * 2) / bpm_ratio)
	var period_seconds_remainder = snapped(fmod(period_seconds, 60.0), 0.001)
	print("Period: ", period_minutes, " minutes ", period_seconds_remainder, " seconds")

# Called once every frame
func _process(_delta):
	# If drawing lines between Pendulums, update line points based on current Pendulum positions
	if draw_lines_between_pendulums:
		for n in pendulum_line.get_points().size():
			if n != pendulum_count:
				pendulum_line.set_point_position(n + 1, pendulums[n].get_child(0).position)
