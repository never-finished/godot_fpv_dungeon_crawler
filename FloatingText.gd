extends Label3D

var float_speed: float = 2.0
var lifetime: float = 1.0
var timer: float = 0.0

func _ready():
	# Make it always face the camera
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	# Ensure it renders over most things
	no_depth_test = true
	pixel_size = 0.01

func initialize(text_val: String, color: Color = Color.WHITE):
	text = text_val
	modulate = color
	
	# Small random offset so multiple numbers don't perfectly overlap
	position += Vector3(randf_range(-0.5, 0.5), randf_range(0.5, 1.5), randf_range(-0.5, 0.5))

func _process(delta):
	timer += delta
	# Float upwards
	position.y += float_speed * delta
	
	# Fade out over time
	var alpha = 1.0 - (timer / lifetime)
	modulate.a = alpha
	
	if timer >= lifetime:
		queue_free()
