extends Node3D
class_name Interactable

signal interacted(player: Node)

@export var prompt_message: String = "Interact"

func interact(player: Node):
	print("Interacted with " + self.name)
	interacted.emit(player)
