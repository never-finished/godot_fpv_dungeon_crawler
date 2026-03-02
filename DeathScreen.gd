extends Control

@onready var color_rect: ColorRect = $ColorRect
@onready var respawn_button: Button = $VBoxContainer/RespawnButton

var is_dead: bool = false
var fade_timer: float = 0.0
var fade_duration: float = 2.0

func _ready():
	hide()
	respawn_button.pressed.connect(_on_respawn_pressed)
	# Ensure background transparency starts at 0
	color_rect.color.a = 0.0

func trigger_death():
	is_dead = true
	fade_timer = 0.0
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta):
	if is_dead and fade_timer < fade_duration:
		fade_timer += delta
		# Linearly interpolate the alpha from 0 to 0.8 over the duration
		var alpha = min(fade_timer / fade_duration, 1.0) * 0.8
		color_rect.color = Color(0.3, 0.0, 0.0, alpha) # Dark Red

func _on_respawn_pressed():
	GameManager.reset_run()
	get_tree().reload_current_scene()
