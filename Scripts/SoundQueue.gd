# This tool allows a queue of the same sound to be set up, so each time the sound is requested to be played, it plays the next sound in the queue.
# This allows multiple copies of the same sound to be played overlapping.
@tool
extends Node2D
class_name SoundQueue

var _next : int = 0
var _audio_stream_players = []

## Amount of copies of the sound to create. Adjust this if you notices some sounds aren't being played at the right time.
@export var count : int = 1

func _ready():
	
	if get_child_count() == 0:
		print("No AudioStreamPlayer2D child found.")
		return
		
	var child = get_child(0)
	
	if child is AudioStreamPlayer2D:
		_audio_stream_players.push_back(child)
		
		for n in count:
			var d : AudioStreamPlayer2D = child.duplicate()
			add_child(d)
			_audio_stream_players.push_back(d)
			
	play_sound()

func _get_configuration_warnings():
	if get_child_count() == 0:
		return ["No children found. Expected one AudioStreamPlayer2D child."]
		
	if not(get_child(0) is AudioStreamPlayer2D):
		return ["Expected first child to be an AudioStreamPlayer2D"]

func play_sound():
	if not(_audio_stream_players[_next].playing):
		_audio_stream_players[_next].play()
		_next += 1
		_next %= _audio_stream_players.size()
		

