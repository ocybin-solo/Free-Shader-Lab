# ShaderControl.gd (Using Tabs)
extends VBoxContainer

# Signal to tell the Main script: "A knob moved, update the GPU!"
signal value_changed(param_name, value)

var parameter_name = ""
var true_default = 0.0 # The "Euclidean 0" home base from the .gdshader file

@onready var slider = %ParamSlider
@onready var val_label = %ValueLabel

# --- STAGE 1: THE CONFIGURATION ---
# This is called by the Main script right after the slider is "born"
func set_range(min_v, max_v, step_v):
	# This ensures the slider matches the math limits in your shader code
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step_v

# --- STAGE 2: THE INITIALIZATION ---
# This is called after set_range to fill in the starting values and descriptions
func setup(p_name, start_value, tooltip_msg, original_default):
	parameter_name = p_name
	true_default = original_default # We "hard-code" the home base here
	
	%ParamLabel.text = p_name.capitalize()
	slider.value = start_value
	tooltip_text = tooltip_msg
	_update_label(start_value)

# --- STAGE 3: THE TELEPORT (Reset) ---
# This is called when you hit the "Reset All" button in the UI
func reset_to_default():
	# We snap back to the 'true_default' we saved in Stage 2
	slider.value = true_default
	_update_label(true_default)
	# IMPORTANT: We tell the Main script to update the shader immediately
	value_changed.emit(parameter_name, true_default)

# --- STAGE 4: THE USER INTERACTION ---
# This is connected to the HSlider node's own 'value_changed' signal
func _on_param_slider_value_changed(value):
	_update_label(value)
	# This is the "Phone Call" that eventually changes the image on screen
	value_changed.emit(parameter_name, value)

# --- HELPERS ---
func _update_label(value):
	if val_label:
		# "%.2f" means show 2 decimal places (e.g., 1.23)
		val_label.text = "%.2f" % value

func get_param_name():
	return parameter_name
