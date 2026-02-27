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
@onready var perf_label = $MarginContainer/HBoxContainer/LeftPanel/MarginContainer/VBoxContainer/PerfLabel

@onready var VortexEarNode = %VortexEar

# -- Animation preview stuff 
var preview_frame_index : int = 0
var preview_timer : float = 0.0
var is_playing_gif : bool = false
var captured_frames: Array = [] # This holds the actual Image objects

# How fast the GIF plays (e.g., 0.1s per frame = 10 FPS)
@export var frame_delay : float = 0.1 
var original_shader_defaults: Dictionary = {}



# --- Script Variables ---
var slider_scene = preload("res://ShaderControl.tscn")
var zoom_speed = 0.1
var min_zoom = 0.1
var max_zoom = 5.0
var is_panning = false
var is_exporting = false
var preview_elapsed_time: float = 0.0
var transition_time: float = 1.5 # for transition between presets

@onready var world_3d = $"../../Node3D" # Your new 3D scene
@onready var ui_overlay = $MarginContainer

func _ready():

	create_dynamic_controls()


	var tween = create_tween()
	tween.tween_property(warning_label, "modulate:a", 0.0, 5.0) # P-Sens Warning tween
	tween.tween_callback(warning_label.hide)
	
	refresh_preset_list()
		# 1. Setup Easing Dropdown
	var trans_btn = %TransitionTypeButton
	trans_btn.clear()
	trans_btn.add_item("Sine (Smooth)", 0)
	trans_btn.add_item("Expo (Surge)", 1)
	trans_btn.add_item("Elastic (Jelly)", 2)
	trans_btn.add_item("Back (Cinematic)", 3)
	trans_btn.add_item("Bounce (Impact)", 4)
	
	# 2. Setup Snap Timing Dropdown
	var snap_btn = %SnapTimingButton
	snap_btn.clear()
	snap_btn.add_item("Snap at Start", 0)
	snap_btn.add_item("Snap at Mid-Point", 1)
	snap_btn.add_item("Snap at End", 2)
	

	
	
func _process(delta: float) -> void:
		# Update the monitor every frame
	update_performance_monitor()
	_check_gpu_safety()
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
		GifPreview.visible = false
		viewport_container.visible = true
		stop_button.visible = false
		preview_speed_slider.visible = false 
		fps_label.visible = false 
		
		if not is_exporting:
			var mat = display_sprite.material as ShaderMaterial
			if mat:
				# 1. Increment our master clock
				preview_elapsed_time += delta
				
				# 2. Check the "Sync" toggle we added to the shader
				# We use 'get_shader_parameter' to see if the user wants strict loops
				var sync_mode = mat.get_shader_parameter("sync_to_loop")
				
				# 3. Apply the time logic
				if sync_mode > 0.5:
					# LOOP MODE: Snap back to 0.0 every second for export preview
					mat.set_shader_parameter("manual_time", fmod(preview_elapsed_time, 1.0))
				else:
					# ORGANIC MODE: Continuous climb for smooth slow-motion
					mat.set_shader_parameter("manual_time", preview_elapsed_time)
					
		if Input.is_action_just_pressed("3d_toggle"):
			ui_overlay.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # Should we check to see if we are in a menu or 3d world here?
			
			
func _on_quit_button_pressed():
	get_tree().quit()

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

func create_dynamic_controls():
	var mat = display_sprite.material as ShaderMaterial
	if not mat or not mat.shader: return
	
	# --- STAGE 1: CLEANUP ---
	for child in controls_container.get_children():
		child.queue_free()

	# --- STAGE 2: PREPARATION ---
	var descriptions = parse_shader_descriptions(mat.shader.resource_path)
	# Use the Shader's own uniform list for UI generation
	var params = mat.shader.get_shader_uniform_list()
	
	for p in params:
		# Skip internal Godot parameters and the manual timer
		if p.name.begins_with("shader_parameter/") or p.name == "manual_time":
			continue
		
		# --- STAGE 3: CAPTURE VALUES ---
		# Since you cleaned the .tscn, this will now correctly return 
		# the defaults from your .gdshader file.
		var current_val = mat.get_shader_parameter(p.name)

		# Safety fallback: if Godot returns Nil, we provide a basic starting point
		if current_val == null:
			match p.type:
				TYPE_QUATERNION, TYPE_VECTOR4: current_val = Quaternion(0, 0, 0, 1)
				TYPE_COLOR: current_val = Color.WHITE
				_: current_val = 0.0

		# Save the very first values we see as the "True Home" for the Reset button
		if not original_shader_defaults.has(p.name):
			original_shader_defaults[p.name] = current_val

		var true_default = original_shader_defaults[p.name]


		# --- STAGE 4: QUATERNION/VEC4 SLIDERS ---
		if p.type == TYPE_QUATERNION or p.type == TYPE_VECTOR4:
			var component_names = ["x", "y", "z", "w"]
			for i in range(4):
				var q_ctrl = slider_scene.instantiate()
				controls_container.add_child(q_ctrl)
				var sub_name = p.name + "." + component_names[i]
				
				# Pass the component value and its true default
				q_ctrl.setup(sub_name, current_val[i], "4D Axis: " + sub_name, true_default[i])
				q_ctrl.value_changed.connect(_on_dynamic_value_changed)
			continue

		# --- STAGE 5: FLOAT SLIDERS ---
		if p.type == TYPE_FLOAT:
			var f_ctrl = slider_scene.instantiate()
			controls_container.add_child(f_ctrl)
			
			# Parse the hint_range(min, max, step) from the shader
			if p.hint == PROPERTY_HINT_RANGE and not p.hint_string.is_empty():
				var parts = p.hint_string.split(",")
				var min_v = float(parts[0])
				var max_v = float(parts[1])
				var step_v = float(parts[2]) if parts.size() > 2 else 0.01
				f_ctrl.set_range(min_v, max_v, step_v)
			
			var desc = descriptions.get(p.name, "Adjust " + p.name)
			# Initialize the slider with the shader's default value
			f_ctrl.setup(p.name, current_val, desc, true_default)
			f_ctrl.value_changed.connect(_on_dynamic_value_changed)
			
	# --- STAGE 6: INITIAL SYNC ---
# Force the material to actually use the values we just put into the UI
	for p_name in original_shader_defaults:
		mat.set_shader_parameter(p_name, original_shader_defaults[p_name])

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
		# Press ESC to jump back to the Menu
		


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
	# --- NEW: AUTO-SYNC FOR EXPORT ---
	# We force the shader into "Loop Mode" regardless of the UI slider
	var user_sync_setting = mat.get_shader_parameter("sync_to_loop")
	mat.set_shader_parameter("sync_to_loop", 1.0)
	
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
		# Use int() or the floor division style to tell Godot: 
		# "I know what I'm doing with these integers!"
		@warning_ignore("integer_division")
		var r: int = i / cols 
		var c: int = i % cols
		var dest_point = Vector2i(c * w, r * h)
		sheet.blit_rect(frames[i], Rect2i(0, 0, w, h), dest_point)
	
	sheet.save_png(path)
	
	
	
	# --- 2. TRANSITION TO PREVIEW ---
	mat.set_shader_parameter("sync_to_loop", user_sync_setting)
	is_exporting = false
	progress_bar.visible = false
	
	# Position the Sprite2D in the CanvasLayer to match the UI
	# CanvasLayer doesn't move with the UI, so we snap the sprite to the container's screen position
	GifPreview.global_position = viewport_container.global_position + (viewport_container.size / 2.0)
	
	# Start the loop! (This triggers the visibility swap in _process)
	is_playing_gif = true 
	print("Export complete. Previewing %d frames." % captured_frames.size())

func _on_reset_button_pressed(): #RESET THE IMAGE POSITION
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
	if not mat: return
	
	# Force the GPU values back to 'True' defaults immediately
	for p_name in original_shader_defaults.keys():
		mat.set_shader_parameter(p_name, original_shader_defaults[p_name])
	
	# Then tell the sliders to move home
	for child in controls_container.get_children():
		if child.has_method("reset_to_default"):
			child.reset_to_default()

func _on_color_picker_button_color_changed(color: Color):
	# Directly updates the 'mod_color' uniform in the shader
	var mat = display_sprite.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("mod_color", color)

func _on_filter_selected(index: int):
	# index 0: Inherited, 1: Nearest (Pixel Art), 2: Linear (Smooth)
	# This matches the 'Texture Filter' settings in the Godot Inspector
	display_sprite.texture_filter = index as CanvasItem.TextureFilter

func stop_preview(): #ESCAPES THE ANIMATED STRIP SAVE PREVIEW
	is_playing_gif = false
	# The _process function will now automatically show the live view again
	viewport_container.visible = true
	GifPreview.visible = false

func _on_stop_button_pressed():
	is_playing_gif = false
	# The _process function will handle the rest!
	
func create_preset_from_current_settings() -> ShaderPreset:
	var mat = display_sprite.material as ShaderMaterial
	if not mat: return null
	
	var new_preset = ShaderPreset.new()
	var params = RenderingServer.get_shader_parameter_list(mat.shader.get_rid())
	
	for p in params:
		# --- STAGE 1: THE ORIGINAL FILTERS ---
		# Skip internal Godot stuff and the manual timer
		if p.name.begins_with("shader_parameter/") or p.name == "manual_time":
			continue
			
		var current_val = mat.get_shader_parameter(p.name)
		
		# --- STAGE 2: THE PURITY FILTER ---
		if current_val != null:
			# Fix the "Quaternion Explosion" (Normalization)
			if current_val is Quaternion:
				# .normalized() ensures the 4D rotation is a "unit" (length of 1.0)
				# This prevents the transition jitter and the "90, 25, 28" errors.
				current_val = current_val.normalized()
			
			# Safety check for Floats to prevent "NaN" (Not a Number) or "Inf" (Infinity)
			elif current_val is float:
				if is_nan(current_val) or is_inf(current_val):
					current_val = 0.0
			
			# --- STAGE 3: SAVE TO PRESET ---
			new_preset.set_param(p.name, current_val)
			
	return new_preset

func save_preset_to_disk(preset_name: String):
	var preset = create_preset_from_current_settings()
	if preset:
		var directory = "user://presets/"
		if not DirAccess.dir_exists_absolute(directory):
			DirAccess.make_dir_recursive_absolute(directory)
			
		var path = directory + preset_name + ".tres"
		var error = ResourceSaver.save(preset, path)
		
		if error == OK:
			print("Successfully saved 4D Preset: ", path)
		else:
			print("Error saving preset: ", error)

func _on_save_preset_button_pressed():
	# 1. Get the text from our new LineEdit node
	var raw_name = $MarginContainer/HBoxContainer/LeftPanel/MarginContainer/VBoxContainer/PresetContainer/MarginContainer/VBoxContainer/PresetNameEdit.text.strip_edges()
	
	# 2. Safety check: Don't save if the name is empty
	if raw_name == "":
		print("4D Error: Please enter a name for your preset!")
		return
		
	# 3. Clean the name (remove spaces or weird characters for the file system)
	var clean_name = raw_name.validate_filename()
	
	# 4. Call our save function with the typed name
	save_preset_to_disk(clean_name)
	
	# 5. Optional: Clear the text box after saving
		# 5. Clear the actual typed text
	var input_node = $MarginContainer/HBoxContainer/LeftPanel/MarginContainer/VBoxContainer/PresetContainer/MarginContainer/VBoxContainer/PresetNameEdit
	input_node.text = "" # This clears the box
	input_node.placeholder_text = "Enter New Name" # This shows the hint again
	print("Preset ", clean_name, "' has been archived.")
	refresh_preset_list() 
	
func refresh_preset_list():
	var container = %PresetListContainer
	
	# 1. Clear existing buttons
	for child in container.get_children():
		child.queue_free()
		
	# 2. Open the directory
	var path = "user://presets/"
	if not DirAccess.dir_exists_absolute(path):
		return
		
	var dir = DirAccess.open(path)
	dir.list_dir_begin()
	
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var btn = Button.new()
			var trip_name = file_name.replace(".tres", "")
			btn.text = trip_name
			btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
			
			# --- ADD THE TOOLTIP HERE ---
			btn.tooltip_text = "Left-Click: Transition to '" + trip_name + "'\nRight-Click: Delete preset"
			
			# Connect the input for left/right click detection
			btn.gui_input.connect(_on_preset_gui_input.bind(file_name))
			
			container.add_child(btn)
			
		file_name = dir.get_next()
		
func _on_preset_button_pressed(file_name: String):
	var path = "user://presets/" + file_name
	var preset = ResourceLoader.load(path) as ShaderPreset
	if not preset: return
	
	var mat = display_sprite.material as ShaderMaterial
	var start_states = {}
	var end_states = {}
	var snap_params = {} # Holds the "Integer/Structural" values

	# --- STAGE 1: SORT PARAMETERS ---
	for p_name in preset.parameters.keys():
		var end_val = preset.get_param(p_name)
		
		# Always normalize Quats on load for "Pure Math"
		if end_val is Quaternion: end_val = end_val.normalized()
		
		# Identify the "Snap" parameters
		if p_name in ["sync_to_loop", "kaleido_sides", "fold_number", "max_steps", "vortex_density"]:
			snap_params[p_name] = end_val
			continue
			
		if p_name == "manual_time": continue
		
		var s_val = mat.get_shader_parameter(p_name)
		if s_val != null:
			start_states[p_name] = s_val
			end_states[p_name] = end_val

	# --- STAGE 2: CALCULATE EASING & SNAP DELAY ---
	var trans_type = Tween.TRANS_SINE
	match %TransitionTypeButton.selected:
		1: trans_type = Tween.TRANS_EXPO
		2: trans_type = Tween.TRANS_ELASTIC
		3: trans_type = Tween.TRANS_BACK
		4: trans_type = Tween.TRANS_BOUNCE

	var snap_delay = 0.0 # Snap at Start
	match %SnapTimingButton.selected:
		1: snap_delay = transition_time / 2.0 # Mid-Point
		2: snap_delay = transition_time # At the End

	# --- STAGE 3: THE TWEEN ---
	var tween = create_tween().set_parallel(true).set_trans(trans_type).set_ease(Tween.EASE_IN_OUT)

	# The "Delayed Snap" Callback
	tween.tween_callback(func():
		for p in snap_params:
			mat.set_shader_parameter(p, snap_params[p])
			_sync_ui_to_param(p, snap_params[p])
	).set_delay(snap_delay)

	# The Master Morph
	tween.tween_method(
		func(weight): _update_transition_step(weight, start_states, end_states, mat),
		0.0, 1.0, transition_time
	)


	
# --- HELPER 1: THE STEPPER ---
func _update_transition_step(weight: float, starts: Dictionary, ends: Dictionary, mat: ShaderMaterial):
	for p_name in starts.keys():
		var start = starts[p_name]
		var end = ends[p_name]
		var current_val
		
		# 1. Interpolate
		if start is Quaternion:
			current_val = start.normalized().slerp(end.normalized(), weight)
		elif start is Color or start is Vector4:
			current_val = start.lerp(end, weight)
		else:
			current_val = lerp(start, end, weight)
		
# 2. THE STABILITY CLAMPS (Preventing the "Manic" visuals)
		if p_name == "step_length":
			current_val = clamp(current_val, 0.001, 0.05)
		elif p_name == "max_steps":
			current_val = clamp(current_val, 1.0, 150.0)
		elif p_name in ["mask_radius", "fold_zoom", "ray_intensity", "vortex_state"]:
			# Ensure these specific sliders never go below zero
			if current_val is float:
				current_val = max(0.0, current_val)
			# If it's a 4D type, we only want to ensure the 'w' (hole size) is positive
			if current_val is Quaternion or current_val is Vector4:
				current_val.w = max(0.0, current_val.w)
			
		mat.set_shader_parameter(p_name, current_val)
		_sync_ui_to_param(p_name, current_val)

# --- HELPER 2: THE UI SYNC ---
func _sync_ui_to_param(p_name: String, val):
	for ctrl in controls_container.get_children():
		if not ctrl.has_method("get_param_name"): continue
		var ctrl_name = ctrl.get_param_name()
		
		var slider = ctrl.slider
		var original_step = slider.step
		slider.step = 0 
		
		# --- THE CRASH FIX ---
		# Case A: Standard float sliders (e.g. 'swirl_strength')
		if ctrl_name == p_name and (val is float or val is int):
			if not is_equal_approx(slider.value, float(val)):
				slider.value = float(val)
		
		# Case B: 4D Axis sliders (e.g. 'q_rot.x' or 'vortex_state.w')
		elif ctrl_name.begins_with(p_name + "."):
			# Only proceed if we actually have 4D data to read from
			if val is Vector4 or val is Quaternion:
				var parts = ctrl_name.split(".")
				var axis = parts[1] # "x", "y", "z", or "w"
				
				# Direct property access is safer and faster than val[axis]
				match axis:
					"x": slider.value = val.x
					"y": slider.value = val.y
					"z": slider.value = val.z
					"w": slider.value = val.w
		
		# Case C: Color Pickers
		elif p_name == "mod_color" and ctrl_name == "mod_color" and val is Color:
			# If your 'ctrl' node has a 'color_picker' child, sync it here
			if ctrl.has_node("ColorPickerButton"):
				ctrl.get_node("ColorPickerButton").color = val

		slider.step = original_step

func _on_transition_speed_changed(value):
	transition_time = value

func _on_preset_gui_input(event: InputEvent, file_name: String):
	if event is InputEventMouseButton and event.pressed:
		# LEFT CLICK: Transition to Preset
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_preset_button_pressed(file_name)
		
		# RIGHT CLICK: Delete Preset
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_delete_preset(file_name)

func _delete_preset(file_name: String):
	var path = "user://presets/" + file_name
	if FileAccess.file_exists(path):
		OS.move_to_trash(ProjectSettings.globalize_path(path))
		# Or use: DirAccess.remove_absolute(path) if you want it gone forever
		print("4D Archive: Deleted ", file_name)
		refresh_preset_list() # Re-scan the folder to update the UI

func _on_random_morph_button_pressed():
	var path = "user://presets/"
	var files = []
	var dir = DirAccess.open(path)
	if not dir: return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"): files.append(file_name)
		file_name = dir.get_next()
	
	if files.size() == 0: return

	# 1. Choose a random destination
	var random_preset = files[randi() % files.size()]
	
	# 2. Randomize the "Vibe"
	%TransitionTypeButton.selected = randi() % 5 # Sine, Expo, Elastic, etc.
	%SnapTimingButton.selected = randi() % 3    # Start, Mid, End
	
	# 3. Randomize the duration (Between 3s and 12s)
	# This ensures your 'transition_time' variable is updated before the morph starts
	transition_time = randf_range(10.0, 20.0)
	
	# 4. TRIGGER THE MAGIC
	_on_preset_button_pressed(random_preset)
	
func update_performance_monitor():
	var fps = Engine.get_frames_per_second()
	# VRAM usage is critical for your 1050 Ti
	var vram = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1024.0 / 1024.0
	# Draw calls tell you if the Ray Marching is choking the pipeline
	var draws = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	
	perf_label.text = "FPS: %d\nVRAM: %.1f MB\nDraws: %d" % [fps, vram, draws]
	
	# Color code the FPS so you know when to back off
	if fps > 55: perf_label.modulate = Color.GREEN
	elif fps > 30: perf_label.modulate = Color.YELLOW
	else: perf_label.modulate = Color.RED
	
# --- THE VRAM SAFETY VALVE ---
func _check_gpu_safety():
	# 1. Measure the current 'Pressure' on the 1050 Ti
	# We check total Video Memory used by textures and buffers
	var vram_used = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1024.0 / 1024.0
	
	# 2. Set your 'Trip Point'
	# Since you have 4GB (4096MB), let's get worried at 3.5GB
	var safety_limit = 3500.0 
	
	if vram_used > safety_limit:
		# TRIP THE BREAKER: Force-lower the heaviest parameters
		var mat = display_sprite.material as ShaderMaterial
		
		# Feedback and Ray Steps are the VRAM 'Gas Guzzlers'
		var current_feedback = mat.get_shader_parameter("feedback_amount")
		if current_feedback > 0.1:
			mat.set_shader_parameter("feedback_amount", 0.0)
			# Sync the UI so the user knows why it stopped!
			_sync_ui_to_param("feedback_amount", 0.0)
			print("VRAM Safety Tripped: Feedback disabled to prevent 1050 Ti crash.")
			
			
			## AUDIYODELOGIC
			
func _on_vortex_ear_dual_pulse(guitar_energy: float, music_energy: float):
	var mat = display_sprite.material as ShaderMaterial
	if not mat: return
	mat.set_shader_parameter("vortex_morph", guitar_energy * 100.0)
	mat.set_shader_parameter("ray_intensity", music_energy * 100.0)

	
func _on_enter_void_pressed():
	# 1. Hide the messy sliders
	ui_overlay.visible = false
	
	# 2. Enable the 6DoF Camera
	world_3d.get_node("Camera3D").set_process(true)
	
	# 3. Capture the mouse for that 'True Pilot' feel
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
