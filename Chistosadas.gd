extends HBoxContainer

@onready var btnPitchHigh: Button = $ButtonPitchHigh
@onready var btnPitchLow: Button = $ButtonPitchLow
@onready var btnFiesta: Button = $ButtonFiesta
@onready var btnWave: Button = $ButtonWave
@onready var btnRetro: Button = $ButtonRetro
@onready var color_rect: ColorRect = $"../../../ColorRect"
@onready var wave: AnimationPlayer = $"../../../../wave"
@onready var retro_screen: ColorRect = $"../../../../RetroScreen/RetroScreen"
@onready var rainbow: AnimationPlayer = $"../../../../rainbow"
@onready var animated_sprite_2d: AnimatedSprite2D = $"../../../AnimatedSprite2D"


var bus := "Master"
var fiesta_tween: Tween
var fiesta_active: bool = false

#indices de efectos en el bus
const INDEX_PITCH_HIGH := [1]
const INDEX_PITCH_LOW := [2]
const INDEX_FIESTA := [3]
const INDEX_WAVE := [4, 5]
const INDEX_RETRO := [7, 8, 9, 10, 11, 12, 13, 14]


const FIESTA_COLORS := [
	Color("#f5000034"),
	Color("#2fff0034"),
	Color("#00fff534"),
	Color("#ff00f534"),
	Color("#fff50034"),
	Color("#00f5ff34")
]

func _ready() -> void:
	btnPitchHigh.text = "        Effect1        "
	btnPitchLow.text = "        Effect2       "
	btnFiesta.text = "        Effect3        "
	btnWave.text = "        Effect4       "
	btnRetro.text = "        Effect5        "

	btnPitchHigh.pressed.connect(Callable(self, "_on_pitch_high_pressed"))
	btnPitchLow.pressed.connect(Callable(self, "_on_pitch_low_pressed"))
	btnFiesta.pressed.connect(Callable(self, "_on_fiesta_pressed"))
	btnWave.pressed.connect(Callable(self, "_on_wave_pressed"))
	btnRetro.pressed.connect(Callable(self, "_on_retro_pressed"))


func _on_pitch_high_pressed() -> void:
	_toggle_effects(INDEX_PITCH_HIGH, btnPitchHigh)
	var active := _is_any_effect_enabled(INDEX_PITCH_HIGH)
	if active:
		_disable_effects(INDEX_PITCH_LOW)
		_update_button_visual(btnPitchLow, false)
	_update_sprite_speed()


func _on_pitch_low_pressed() -> void:
	_toggle_effects(INDEX_PITCH_LOW, btnPitchLow)
	var active := _is_any_effect_enabled(INDEX_PITCH_LOW)
	if active:
		_disable_effects(INDEX_PITCH_HIGH)
		_update_button_visual(btnPitchHigh, false)
	_update_sprite_speed()

func _update_sprite_speed() -> void:
	if not is_instance_valid(animated_sprite_2d):
		return
	var high_active := _is_any_effect_enabled(INDEX_PITCH_HIGH)
	var low_active := _is_any_effect_enabled(INDEX_PITCH_LOW)
	if high_active:
		animated_sprite_2d.speed_scale = 12
	elif low_active:
		animated_sprite_2d.speed_scale = 5
	else:
		animated_sprite_2d.speed_scale = 8
		
func _on_fiesta_pressed() -> void:
	_toggle_effects(INDEX_FIESTA, btnFiesta)
	
	var active := _is_any_effect_enabled(INDEX_FIESTA)
	
	if active and not fiesta_active:
		_start_fiesta_colors()
	elif not active and fiesta_active:
		_stop_fiesta_colors()
		
	if is_instance_valid(rainbow):
		rainbow.stop()
		if active and rainbow.has_animation("fade_in"):
			rainbow.play("fade_in")
		elif not active and rainbow.has_animation("fade_out"):
			rainbow.play("fade_out")
			
func _on_wave_pressed() -> void:
	_toggle_effects(INDEX_WAVE, btnWave)
	
	var active := _is_any_effect_enabled(INDEX_WAVE)
	
	if is_instance_valid(wave):
		if active:
			if wave.has_animation("fade_in"):
				wave.play("fade_in")
		else:
			if wave.has_animation("fade_out"):
				wave.play("fade_out")
				
func _on_retro_pressed() -> void:
	_toggle_effects(INDEX_RETRO, btnRetro)
	
	var active := _is_any_effect_enabled(INDEX_RETRO)
	
	if is_instance_valid(retro_screen):
		retro_screen.visible = active
		
#control
func _toggle_effects(indices: Array, button: Button) -> void:
	var bus_idx := AudioServer.get_bus_index(bus)
	if bus_idx == -1:
		push_error("Bus no encontrado: %s" % bus)
		return
		
	var enabled := _is_any_effect_enabled(indices)
	for i in indices:
		if i < AudioServer.get_bus_effect_count(bus_idx):
			AudioServer.set_bus_effect_enabled(bus_idx, i, !enabled)
			
	_update_button_visual(button, !enabled)
	
func _is_any_effect_enabled(indices: Array) -> bool:
	var bus_idx := AudioServer.get_bus_index(bus)
	for i in indices:
		if i < AudioServer.get_bus_effect_count(bus_idx):
			if AudioServer.is_bus_effect_enabled(bus_idx, i):
				return true
	return false
	
func _disable_effects(indices: Array) -> void:
	var bus_idx := AudioServer.get_bus_index(bus)
	for i in indices:
		if i < AudioServer.get_bus_effect_count(bus_idx):
			AudioServer.set_bus_effect_enabled(bus_idx, i, false)
			
func _update_button_visual(button: Button, active: bool) -> void:
	button.modulate = Color("c58281ff") if active else Color(1, 1, 1)
	
func _start_fiesta_colors() -> void:
	fiesta_active = true
	if is_instance_valid(fiesta_tween):
		fiesta_tween.stop()
		fiesta_tween.kill()
	fiesta_tween = create_tween()
	fiesta_tween.set_loops() 
	_cycle_fiesta_color()

func _cycle_fiesta_color() -> void:
	if not fiesta_active or not is_instance_valid(color_rect):
		return
		
	if fiesta_tween == null or not fiesta_tween.is_valid():
		fiesta_tween = create_tween()
	else:
		fiesta_tween.stop()
		fiesta_tween.kill()
		fiesta_tween = create_tween()
		
	var next_color: Color = FIESTA_COLORS[randi() % FIESTA_COLORS.size()]
	fiesta_tween.tween_property(color_rect, "color", next_color, 0.8)
	fiesta_tween.tween_callback(Callable(self, "_cycle_fiesta_color"))
	
func _stop_fiesta_colors() -> void:
	fiesta_active = false
	if is_instance_valid(fiesta_tween):
		fiesta_tween.stop()
		fiesta_tween.kill()
		
	var tween := create_tween()
	tween.tween_property(color_rect, "color", Color("#f5000034"), 0.6)
