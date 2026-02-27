extends Node

# Signal to tell the main app when the music "Hits"
signal audio_pulse(bass: float, mids: float, highs: float)

var spectrum: AudioEffectInstance

func _ready():
	var bus_index = AudioServer.get_bus_index("VortexInput")
	spectrum = AudioServer.get_bus_effect_instance(bus_index, 0)

func _process(_delta):
	if not spectrum: return
	
	# Capture the bands (Guitar/Liszt/Mozart)
	var bass = spectrum.get_magnitude_for_frequency_range(20, 200).length()
	var mids = spectrum.get_magnitude_for_frequency_range(200, 2000).length()
	var highs = spectrum.get_magnitude_for_frequency_range(2000, 10000).length()
	
	# Emit the data so the Main Menu can 'hear' it
	audio_pulse.emit(bass, mids, highs)
