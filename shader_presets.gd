extends Resource
class_name ShaderPreset

# We use a Dictionary to store all your shader slider values
@export var parameters: Dictionary = {}

# This function lets us "pack" a value into the preset
func set_param(p_name: String, value: Variant):
	parameters[p_name] = value

# This function lets us "pull" a value out
func get_param(p_name: String, default: Variant = 0.0):
	return parameters.get(p_name, default)
