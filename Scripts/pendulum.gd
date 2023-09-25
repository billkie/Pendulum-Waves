extends Node2D
class_name Pendulum

## Amount of times the pendulum completes half a cycle in one minute. This is set by PendulumWave.
@export var pendulum_bpm = 60
## Ease Type of Pendulum Tween. This is set by PendulumWave
@export var ease_type : Tween.EaseType
## Transition Type of Pendulum Tween. This is set by PendulumWave
@export var transition_type : Tween.TransitionType
# Get PathFollow2D parent to use for Tween
@onready var path_follow_2d = %PathFollow2D
# Get SoundQueue node for playing sounds in change_direction method
@onready var collision_sound = %SoundQueue

# Tween for moving Pendulum
var tween : Tween
# Time used to complete Tween step
var tween_time : float

func _ready():
	# Calculating Tween time based on current Pendulum BPM
	tween_time = 1.0 / (pendulum_bpm / 60.0)
	# Creating Tween and setting trans type and ease type. Setting to loop infinitely and setting process mode to use physics process
	tween = get_tree().create_tween().set_loops().set_trans(transition_type).set_ease(ease_type).set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	# Connecting Tween signal "step_finished" to the change_direction method. This will allow change_direction to be called each time the Tween completes a step i.e. half a cycle.
	tween.connect("step_finished", change_direction)
	# Tween step to move along progress_ratio of PathFollow2D from 0 to 1 in tween_time seconds
	tween.tween_property(path_follow_2d, 'progress_ratio', 1, tween_time)
	# Tween step to move along progress_ratio of PathFollow2D from 1 to 0 in tween_time seconds
	tween.tween_property(path_follow_2d, 'progress_ratio', 0, tween_time)

# function called when Pendulum changes direction
func change_direction(_obj):
	# Play sound from SoundQueue
	collision_sound.play_sound()
	# Other things can be added here, like animating the Pendulum Sprite to change size or color etc
