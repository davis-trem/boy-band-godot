extends Sprite


export(bool) var is_player = false

onready var ani_player = $AnimationPlayer
onready var animation_tree = $AnimationTree
onready var animation_state_mode: AnimationNodeStateMachinePlayback = (
	animation_tree.get("parameters/playback")
)

var chargine_attack = false


# Called when the node enters the scene tree for the first time.
func _ready():
#	for animation in ani_player.get_animation_list():
#			if animation == "RESET":
#				continue
#			print("rr {0}" % [animation])
	pass # Replace with function body.


func _unhandled_key_input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.scancode == KEY_A:
				print('play aniiii2')
				print(ani_player.get_animation("attack").length)
				animation_state_mode.travel("attack")
			if event.scancode == KEY_S:
				print('play preeep')
				print(ani_player.get_animation("attack_prep").length)
				animation_state_mode.travel("attack_prep")
			if event.scancode == KEY_0:
				print('000')
				animation_tree.set(
					"parameters/attack/TimeScale/scale",
					1
				)
			if event.scancode == KEY_1:
				print('111')
				animation_tree.set(
					"parameters/attack/TimeScale/scale",
					1 / ani_player.get_animation("attack").length
				)
			if event.scancode == KEY_2:
				print('222')
				animation_tree.set(
					"parameters/attack/TimeScale/scale",
					2 / ani_player.get_animation("attack").length
				)
			if event.scancode == KEY_3:
				print('333')
				animation_tree.set(
					"parameters/attack2/TimeScale/scale",
					3 / ani_player.get_animation("attack").length
				)


func _set_length_of_animation(animation: String, animation_length: float):
	animation_tree.set(
		"parameters/" + animation + "/TimeScale/scale",
		animation_length / ani_player.get_animation(animation).length
	)


func _on_eigth_beat_event(beat):
	if beat.measure == 1 and beat.beat == 1 and beat.eighth == 1:
		var beat_in_sec = float(60 / beat.tempo)
		for animation in ani_player.get_animation_list():
			if animation == "RESET":
				continue
			_set_length_of_animation(animation, beat_in_sec)

		_set_length_of_animation("idle", beat_in_sec * 4)
		animation_state_mode.start("idle")
	
	# Do nothing for first 2 measures
	if beat.measure == 1 or beat.measure == 2:
		return
	
	if is_player:
		if !chargine_attack and beat.measure % 2 == 1 and beat.beat == 1:
			animation_state_mode.travel("attack_prep_fail")
		
		# If player waits too long to commit attack 
		if chargine_attack and beat.beat == 3:
			chargine_attack = false
			animation_state_mode.travel("attack_fail")
	else:
		# handle ai attacking
		pass
	
	


func _on_character_button_pressed():
	if is_player:
		chargine_attack = true
		animation_state_mode.travel("attack_prep")
	else:
		# handle ai being attacked
		pass
