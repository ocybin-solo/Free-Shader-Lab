extends Camera3D


var boombox_scene = preload("res://QuantumBoomBox.tscn")

@export var move_speed := 20.0
@export var rotation_speed := 1.5

func _process(delta):
	# 1. TRANSLATION (Forward/Back, Left/Right, Up/Down)
	var input_dir = Vector3.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_down", "move_up")
	input_dir.z = Input.get_axis("move_forward", "move_back")
	
	# Move relative to where the camera is currently looking
	# This is the 'hyperspace' feel—there is no fixed floor
	var move_vec = (quaternion * input_dir).normalized()
	position += move_vec * move_speed * delta

	# 2. ROTATION (Roll)
	if Input.is_action_pressed("roll_left"):
		quaternion *= Quaternion(Vector3.FORWARD, rotation_speed * delta)
	if Input.is_action_pressed("roll_right"):
		quaternion *= Quaternion(Vector3.FORWARD, -rotation_speed * delta)

func _unhandled_input(event):
	# 3. LOOK (Mouse Pitch and Yaw)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var yaw = Quaternion(Vector3.UP, -event.relative.x * 0.002)
		var pitch = Quaternion(Vector3.RIGHT, -event.relative.y * 0.002)
		# Combine rotations using Quaternions to avoid Gimbal Lock
		quaternion = (quaternion * yaw * pitch).normalized()
		
func _input(event):
	if event.is_action_pressed("place_boombox"):
		var box = boombox_scene.instantiate()
		get_parent().add_child(box)
		box.global_position = global_position + (quaternion * Vector3(0,0,-5))
