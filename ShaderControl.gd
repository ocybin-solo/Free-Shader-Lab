# ShaderControl.gd (Using Tabs)
extends VBoxContainer

signal value_changed(param_name, value)
var parameter_name = ""
var default_value = 0.0 # Store the initial value

@onready var slider = %ParamSlider
@onready var val_label = %ValueLabel

func setup(p_name, start_value, tooltip_msg):
	parameter_name = p_name
	default_value = start_value # Save for resetting later
	%ParamLabel.text = p_name.capitalize()
	slider.value = start_value
	tooltip_text = tooltip_msg
	_update_label(start_value)

func reset_to_default():
	# Update the slider; the signal will handle the shader update automatically
	slider.value = default_value
	_update_label(default_value)
	
func set_range(min_v, max_v, step_v):
	# Using 'slider' instead of '%' here to ensure we use the cached variable
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step_v

func _on_param_slider_value_changed(value):
	_update_label(value)
	value_changed.emit(parameter_name, value)

func _update_label(value):
	# Safety check: Ensure the label exists and 'value' is cast to a float
	if val_label:
		val_label.text = "%.2f" % float(value)
