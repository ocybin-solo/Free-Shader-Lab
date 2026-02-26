extends Control

# --- Node Paths ---
@onready var camera = $MarginContainer/HBoxContainer/MidPanel/MarginContainer/VBoxContainer/SubViewportContainer/SubViewport/Camera2D
@onready var viewport_container = $MarginContainer/HBoxContainer/MidPanel/MarginContainer/VBoxContainer/SubViewportContainer
@onready var sub_viewport = $MarginContainer/HBoxContainer/MidPanel/MarginContainer/VBoxContainer/SubViewportContainer/SubViewport
@onready var file_dialog = $MarginContainer/HBoxContainer/LeftPanel/MarginContainer/VBoxContainer/OpenFile
@onready var display_sprite = $MarginContainer/HBoxContainer/MidPanel/MarginContainer/VBoxContainer/SubViewportContainer/SubViewport/Sprite2D
@onready var color_picker = $MarginContainer/HBoxContainer/LeftPanel/MarginContainer/VBoxContainer/ColorPickerButton
@onready var controls_container = $MarginContainer/HBoxContainer/RightPanel/MarginContainer/ScrollContainer/RightVBox
@onready var anim_toggle = $MarginContainer/HBoxContainer/LeftPanel/MarginContainer/VBoxContainer/AnimToggle
@onready var progress_bar = $MarginContainer/HBoxContainer/MidPanel/MarginContainer/VBoxContainer/ExportProgress
@onready var GifPreview = $"../../CanvasLayer2/GifPreview"
@onready var stop_button = $"../../CanvasLayer2/VBoxContainer/StopPreviewButton"
@onready var preview_speed_slider = $"../../CanvasLayer2/VBoxContainer/PreviewSpeedSlider"
@onready var warning_label = $MarginContainer/HBoxContainer/MidPanel/MarginContainer/VBoxContainer/WarningLabel
# Inputs
@onready var rows_input = $MarginContainer/HBoxContainer/LeftPanel/MarginContainer/VBoxContainer/RowsInput
@onready var frame_count_input = $MarginContainer/HBoxContainer/LeftPanel/MarginContainer/VBoxContainer/FrameCountSpinbox
@onready var speed_slider = $MarginContainer/HBoxContainer/LeftPanel/MarginContainer/VBoxContainer/HSlider
@onready var fps_label = $"../../CanvasLayer2/VBoxContainer/FPSLabel"
# -- Animation preview stuff 
var preview_frame_index : int = 0
var preview_timer : float = 0.0
var is_playing_gif : bool = false
var captured_frames: Array = [] # This holds the actual Image objects

# How fast the GIF plays (e.g., 0.1s per frame = 10 FPS)
@export var frame_delay : float = 0.1 



# --- Script Variables ---
var slider_scene = preload("res://ShaderControl.tscn")
var zoom_speed = 0.1
var min_zoom = 0.1
var max_zoom = 5.0
var is_panning = false
var is_exporting = false
var preview_elapsed_time: float = 0.0


func _ready():
	create_dynamic_controls()
	var tween = create_tween()
	tween.tween_property(warning_label, "modulate:a", 0.0, 10.0)
	tween.tween_callback(warning_label.hide)
	
func _process(delta: float) -> void:
	if is_playing_gif and captured_frames.size() > 0:
		GifPreview.visible = true
		viewport_container.visible = false
		stop_button.visible = true # SHOW the button during preview
		preview_speed_slider.visible = true # Show the slider!
		fps_label.visible = true 
		
		frame_delay = preview_speed_slider.value
				# --- UPDATE FPS LABEL ---
		# --- THE FIX: FPS-BASED CONTROL ---
		# Get the target FPS directly from the slider (e.g., 24)
		var target_fps = preview_speed_slider.value 
		
		# Calculate the delay needed to hit that FPS
		frame_delay = 1.0 / target_fps
		var gif_delay = int(round(100.0 / target_fps))
		# Update the label with the exact slider value
		fps_label.text = "FPS: %d  |  GIF Delay: %d" % [target_fps, gif_delay]
		
		# 1. SNAP POSITION: Put the sprite center in the middle of the container
		# This ensures the "GIF" shows up exactly where the live view was.
		GifPreview.global_position = viewport_container.global_position + (viewport_container.size / 2.0)
		
		# 2. MATCH SCALE: If your viewport is 593x533, make sure the sprite matches
		var sprite_size = GifPreview.texture.get_size() if GifPreview.texture else Vector2(1,1)
		GifPreview.scale = viewport_container.size / sprite_size

		preview_timer += delta
		if preview_timer >= frame_delay:
			preview_timer = 0.0
			preview_frame_index = (preview_frame_index + 1) % captured_frames.size()
			
			# 3. UPDATE TEXTURE
			GifPreview.texture = ImageTexture.create_from_image(captured_frames[preview_frame_index])

			
	# --- 2. LIVE SHADER MODE ---
	else:
		# Toggle visibility: Show live view, hide preview
		GifPreview.visible = false
		viewport_container.visible = true
		stop_button.visible = false
		preview_speed_slider.visible = false # Hide the slider!
		fps_label.visible = false # Hide label when not in preview
		
		if not is_exporting:
			var mat = display_sprite.material as ShaderMaterial
			if mat:
				# Use a fixed 1.0 speed for the live preview so it's easy to see
				preview_elapsed_time += delta
				mat.set_shader_parameter("manual_time", fmod(preview_elapsed_time, 1.0))
			
func _on_quit_button_pressed():
	get_tree().quit()

# --- EXPORT PRESET LOGIC --- THIS SECTION WRITES TO THE CLIPBOARD

func _on_export_logic_button_pressed():
	var mat = display_sprite.material as ShaderMaterial
	if not mat or not mat.shader: return

	var output = "# --- SHADER PRESET LOGIC ---\n"
	output += "var mat = $Sprite2D.material as ShaderMaterial\n"
	
	var active_params = []
	var params = RenderingServer.get_shader_parameter_list(mat.shader.get_rid())
	
	for p in params:
		if p.name.begins_with("shader_parameter/") or p.name == "manual_time":
			continue
		
		var val = mat.get_shader_parameter(p.name)
		if val == null: continue
		
		var is_default = false
		if p.name in ["contrast", "saturation"]:
			if abs(val - 1.0) < 0.01: is_default = true
		elif p.type == TYPE_FLOAT:
			if abs(val - 0.0) < 0.001: is_default = true
		elif p.type == TYPE_COLOR:
			if val.is_equal_approx(Color.WHITE): is_default = true
		
				# --- ADD THIS: 4D Default Check ---
		elif p.type == TYPE_QUATERNION or p.type == TYPE_VECTOR4:
			if val is Quaternion and val.is_equal_approx(Quaternion(0, 0, 0, 1)):
				is_default = true
		
		if not is_default:
			active_params.append(p.name)
			if p.type == TYPE_FLOAT:
				output += "mat.set_shader_parameter('%s', %.3f)\n" % [p.name, val]
			elif p.type == TYPE_COLOR:
				output += "mat.set_shader_parameter('%s', Color(%.2f, %.2f, %.2f))\n" % [p.name, val.r, val.g, val.b]
						# --- ADD THIS: 4D Writer ---
			elif p.type == TYPE_QUATERNION or p.type == TYPE_VECTOR4:
				output += "mat.set_shader_parameter('%s', Quaternion(%.3f, %.3f, %.3f, %.3f))\n" % [p.name, val.x, val.y, val.z, val.w]
			
			
			
	var shader_code = FileAccess.get_file_as_string(mat.shader.resource_path)
	var lines = shader_code.split("\n")

	output += "\n# --- SHADER UNIFORM DECLARATIONS ---\n"
	for line in lines:
		var trimmed = line.strip_edges()
		if trimmed.begins_with("uniform"):
			for p_name in active_params:
				if " " + p_name in trimmed or ":" + p_name in trimmed:
					output += trimmed + "\n"

	output += "\n# --- GENERATED FRAGMENT SHADER SNIPPET ---\n"
	output += "void fragment() {\n\tvec2 uv = UV;\n\tvec4 tex = texture(TEXTURE, uv);\n\n"
	
	for p_name in active_params:
		var capturing = false
		for line in lines:
			if "if (" + p_name in line or p_name + " >" in line:
				capturing = true
			if capturing:
				output += "\t" + line.strip_edges() + "\n"
				if "}" in line:
					capturing = false
					output += "\n"
					break

	output += "\tCOLOR = tex;\n}"
	DisplayServer.clipboard_set(output)

# --- DYNAMIC UI GENERATION ---

func create_dynamic_controls():
	var mat = display_sprite.material as ShaderMaterial
	if not mat or not mat.shader: return
	
	for child in controls_container.get_children():
		child.queue_free()

	var descriptions = parse_shader_descriptions(mat.shader.resource_path)
	var params = RenderingServer.get_shader_parameter_list(mat.shader.get_rid())
	
	for p in params:
		# 1. Skip internal or time parameters
		if p.name.begins_with("shader_parameter/") or p.name == "manual_time":
			continue
		
		# 2. Handle QUATERNIONS / VECTORS (The 4D Geek Stuff)
		if p.type == TYPE_QUATERNION or p.type == TYPE_VECTOR4:
			var component_names = ["x", "y", "z", "w"]
			var current_val = mat.get_shader_parameter(p.name)
			# Ensure we have a valid starting point
			if current_val == null: current_val = Quaternion(0, 0, 0, 1)
			
			for i in range(4):
				var quat_ctrl = slider_scene.instantiate()
				controls_container.add_child(quat_ctrl)
				
				# We name it "q_rot.x", "q_rot.y", etc.
				var sub_name = p.name + "." + component_names[i]
				quat_ctrl.set_range(-1.0, 1.0, 0.01)
				quat_ctrl.setup(sub_name, current_val[i], "Adjust " + sub_name)
				quat_ctrl.value_changed.connect(_on_dynamic_value_changed)
			
			continue # Move to the next parameter since we handled this one

		# 3. Handle FLOATS (Your existing logic)
		if p.type == TYPE_FLOAT:
			var float_ctrl = slider_scene.instantiate()
			controls_container.add_child(float_ctrl)
			
			# Setup range hints
			if p.hint == PROPERTY_HINT_RANGE and not p.hint_string.is_empty():
				var parts = p.hint_string.split(",")
				var min_v = float(parts[0])
				var max_v = float(parts[1])
				var step_v = float(parts[2]) if parts.size() > 2 else 0.01
				float_ctrl.set_range(min_v, max_v, step_v)
			
			var initial_value = mat.get_shader_parameter(p.name)
			
			# Handle your specific defaults
			if initial_value == null: initial_value = 0.0
			if p.name == "fold_number" or p.name == "hex_scale" or p.name == "swirl_speed":
				initial_value = 0.0
				mat.set_shader_parameter(p.name, 0.0)
			elif p.name == "mask_radius":
				initial_value = 1.0
				mat.set_shader_parameter("mask_radius", 1.0)

			var desc = descriptions.get(p.name, "Adjust " + p.name)
			float_ctrl.setup(p.name, initial_value, desc)
			float_ctrl.value_changed.connect(_on_dynamic_value_changed)

func _on_dynamic_value_changed(p_name: String, value: float):
	var mat = display_sprite.material as ShaderMaterial
	if not mat: return
	
	# Check if the slider name has a dot (e.g., "q_rot.x")
	if "." in p_name:
		var parts = p_name.split(".")
		var target_uniform = parts[0]   # "q_rot"
		var component = parts[1]        # "x", "y", "z", or "w"
		
		# 1. Get the current Vector4/Quaternion from the shader
		var current_val = mat.get_shader_parameter(target_uniform)
		
		# 2. Safety check: if it's null, create a default
		if current_val == null: 
			current_val = Quaternion(0, 0, 0, 1)

		# 3. Update the specific piece that moved
		if component == "x": current_val.x = value
		elif component == "y": current_val.y = value
		elif component == "z": current_val.z = value
		elif component == "w": current_val.w = value
		
		# 4. Push the whole 4D package back to the shader
		mat.set_shader_parameter(target_uniform, current_val)
	else:
		# It's a standard single slider (like 'max_steps' or 'ray_angle')
		mat.set_shader_parameter(p_name, value)

#  COPY TO CLIPBOARD FUNCTION
func parse_shader_descriptions(path):
	var dict = {}
	if not FileAccess.file_exists(path): return dict
	var file = FileAccess.open(path, FileAccess.READ)
	var last_desc = ""
	
	while !file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.begins_with("// DESC:"):
			last_desc = line.replace("// DESC:", "").strip_edges()
		elif line.contains("uniform") and last_desc != "":
			# Improved Name Extraction:
			# 1. Remove 'uniform' keyword
			var content = line.replace("uniform", "").strip_edges()
			# 2. Split by ':' or '=' or ';' to isolate the name
			var u_name = content.split(":")[0].split("=")[0].split(";")[0].strip_edges()
			# 3. Clean up any remaining type names (like 'float') if they weren't split
			var parts = u_name.split(" ")
			u_name = parts[parts.size() - 1] # The last word before the ':' is the name
			
			dict[u_name] = last_desc
			last_desc = ""
	return dict

# --- VIEWPORT & FILE DIALOG ---

func _input(event):
	if not viewport_container.get_global_rect().has_point(get_global_mouse_position()):
		return
	if event.is_action_pressed("zoom_in"): zoom_camera(zoom_speed)
	elif event.is_action_pressed("zoom_out"): zoom_camera(-zoom_speed)
	if event.is_action("pan"): is_panning = event.pressed
	if event is InputEventMouseMotion and is_panning:
		camera.position -= event.relative / camera.zoom.x
	if event.is_action_pressed("ui_cancel"): # Usually the 'Escape' key
		stop_preview()

func zoom_camera(delta):
	var new_zoom = clamp(camera.zoom.x + delta, min_zoom, max_zoom)
	camera.zoom = Vector2(new_zoom, new_zoom)

func _on_open_button_pressed():
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.clear_filters()
	file_dialog.add_filter("*.png, *.jpg, *.jpeg ; Supported Images")
	file_dialog.popup_centered()

func _on_file_dialog_file_selected(path: String):
	if file_dialog.file_mode == FileDialog.FILE_MODE_OPEN_FILE:
		var img = Image.load_from_file(path)
		if img:
			display_sprite.texture = ImageTexture.create_from_image(img)
	else:
		if anim_toggle.button_pressed:
			export_animated_strip(path, int(frame_count_input.value))
		else:
			save_single_frame(path)

# --- EXPORT LOGIC ---

func save_single_frame(path):
	await RenderingServer.frame_post_draw
	var img = sub_viewport.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	img.save_png(path)

func export_animated_strip(path: String, frame_count: int):
	is_exporting = true
	progress_bar.visible = true
	progress_bar.max_value = frame_count
	
	# 1. PREPARE NODES: Ensure live view is ON so we can capture it
	# And ensure the preview sprite is HIDDEN during the process
	viewport_container.visible = true
	GifPreview.visible = false
	captured_frames.clear() 
	
	var frames = []
	var w = sub_viewport.size.x
	var h = sub_viewport.size.y
	var mat = display_sprite.material as ShaderMaterial
	
	var rows = int(rows_input.value)
	var cols = int(ceil(float(frame_count) / float(rows)))
	var total_loops = speed_slider.value
	
	for i in range(frame_count):
		var progress = float(i) / float(frame_count)
		mat.set_shader_parameter("manual_time", progress * total_loops)
		
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		
		var frame_img = sub_viewport.get_texture().get_image()
		frame_img.convert(Image.FORMAT_RGBA8)
		
		frames.append(frame_img)
		captured_frames.append(frame_img.duplicate())
		
		progress_bar.value = i + 1

	# --- STITCHING ---
	var sheet = Image.create(w * cols, h * rows, false, Image.FORMAT_RGBA8)
	for i in range(frames.size()):
		var r = i / cols
		var c = i % cols
		var dest_point = Vector2i(c * w, r * h)
		sheet.blit_rect(frames[i], Rect2i(0, 0, w, h), dest_point)
	
	sheet.save_png(path)
	
	# --- 2. TRANSITION TO PREVIEW ---
	mat.set_shader_parameter("manual_time", 0.0)
	is_exporting = false
	progress_bar.visible = false
	
	# Position the Sprite2D in the CanvasLayer to match the UI
	# CanvasLayer doesn't move with the UI, so we snap the sprite to the container's screen position
	GifPreview.global_position = viewport_container.global_position + (viewport_container.size / 2.0)
	
	# Start the loop! (This triggers the visibility swap in _process)
	is_playing_gif = true 
	print("Export complete. Previewing %d frames." % captured_frames.size())

func _on_reset_button_pressed():
	var tween = create_tween().set_parallel(true)
	tween.tween_property(camera, "position", Vector2.ZERO, 0.3)
	tween.tween_property(camera, "zoom", Vector2.ONE, 0.3)

func _on_save_button_pressed():
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.clear_filters()
	file_dialog.add_filter("*.png", "PNG Image")
	file_dialog.current_file = "sprite_export.png"
	file_dialog.popup_centered()

func _on_reset_all_button_pressed():
	var mat = display_sprite.material as ShaderMaterial
	if mat:
		# Manual reset of parameters
		mat.set_shader_parameter("manual_time", 0.0)
		# ... other param resets ...
	speed_slider.value = 1.0
	for child in controls_container.get_children():
		if child.has_method("reset_to_default"): child.reset_to_default()

func _on_color_picker_button_color_changed(color: Color):
	# Directly updates the 'mod_color' uniform in the shader
	var mat = display_sprite.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("mod_color", color)

func _on_filter_selected(index: int):
	# index 0: Inherited, 1: Nearest (Pixel Art), 2: Linear (Smooth)
	# This matches the 'Texture Filter' settings in the Godot Inspector
	display_sprite.texture_filter = index as CanvasItem.TextureFilter

func stop_preview():
	is_playing_gif = false
	# The _process function will now automatically show the live view again
	viewport_container.visible = true
	GifPreview.visible = false

func _on_stop_button_pressed():
	is_playing_gif = false
	# The _process function will handle the rest!
