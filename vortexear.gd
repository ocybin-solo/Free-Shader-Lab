extends Node

# Signal sends (Guitar_Energy, Music_Energy)
signal dual_pulse(guitar: float, music: float)

var spectrum_guitar: AudioEffectInstance
var spectrum_music: AudioEffectInstance

func _ready():
	# 1. Hook up the Guitar Ear
	var g_idx = AudioServer.get_bus_index("GuitarInput")
	spectrum_guitar = AudioServer.get_bus_effect_instance(g_idx, 0)
	
	# 2. Hook up the Music Ear
	var m_idx = AudioServer.get_bus_index("MusicInput")
	spectrum_music = AudioServer.get_bus_effect_instance(m_idx, 0)

func _process(_delta):
	if not spectrum_guitar or not spectrum_music: return
	
	# Sample the "Mids" for the Guitar (where the strings sing)
	var g_val = spectrum_guitar.get_magnitude_for_frequency_range(200, 2000).length()
	
	# Sample the "Bass" for the Music (the heartbeat of the track)
	var m_val = spectrum_music.get_magnitude_for_frequency_range(20, 200).length()
	
	# Send both to the Brain
	dual_pulse.emit(g_val, m_val)
