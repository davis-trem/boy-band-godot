extends Sprite


onready var ani_player = $AnimationPlayer
onready var animation_tree = $AnimationTree


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _unhandled_key_input(event):
	var animation_state_mode: AnimationNodeStateMachinePlayback = (
		animation_tree.get("parameters/playback")
	)
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
