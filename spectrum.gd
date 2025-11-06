extends ColorRect

const VU_COUNT:int = 32
const FREQ_MAX:float = 3000.0
const MIN_DB:float = 80.0
@export var SILENCE_THRESHOLD:float = 0.02 

var spectrum_shader:ShaderMaterial
var analyzer:AudioEffectSpectrumAnalyzerInstance
var smooth_values: Array = []
@onready var player: AudioStreamPlayer = $"../Reproductor"


func _ready():
	analyzer = AudioServer.get_bus_effect_instance(0, 0)
	spectrum_shader = material
	smooth_values.resize(VU_COUNT)
	for i in range(VU_COUNT):
		smooth_values[i] = 0.0


func _process(delta: float):
	if !analyzer or !spectrum_shader:
		return

	if player and not player.playing:
		for i in range(VU_COUNT):
			smooth_values[i] = lerp(smooth_values[i], 0.0, delta * 2.0)
			spectrum_shader.set_shader_parameter("hz%d" % i, smooth_values[i])
		return

	var prev_hz: float = 0.0

	for i in range(VU_COUNT):
		var hz: float = (i + 1) * FREQ_MAX / VU_COUNT
		var mag: float = analyzer.get_magnitude_for_frequency_range(prev_hz, hz).length()

		if mag < SILENCE_THRESHOLD:
			mag = 0.0

		var db_value = linear_to_db(mag)
		if db_value < -60.0:
			db_value = -80.0

		var value: float = clamp((db_value + MIN_DB) / MIN_DB, 0.0, 1.0)

		# suavizado con inercia
		if value > smooth_values[i]:
			smooth_values[i] = lerp(smooth_values[i], value, delta * 10.0)
		else:
			smooth_values[i] = lerp(smooth_values[i], value, delta * 1.5)

		spectrum_shader.set_shader_parameter("hz%d" % i, smooth_values[i])
		prev_hz = hz
