extends Interactable
class_name Stairs

@onready var label: Label3D = Label3D.new()

func _ready():
	add_child(label)
	label.position = Vector3(0, 1.0, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.text = "Descend to Level " + str(GameManager.current_depth + 1) + "\n[E]"

func interact(player: Node):
	print("Player interacts with Stairs. Going deeper...")
	GameManager.go_deeper(player)
