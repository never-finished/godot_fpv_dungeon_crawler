extends Interactable
class_name GroundItem

var item_data: ItemData

@onready var label: Label3D = Label3D.new()

func _ready():
	add_child(label)
	label.position = Vector3(0, 0.5, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 48
	# We'll set the text and color when initialize is called

func initialize(data: ItemData):
	item_data = data
	
	if item_data.visual_mesh:
		var mi = MeshInstance3D.new()
		mi.mesh = item_data.visual_mesh
		add_child(mi)
		
	label.text = item_data.get_full_name()
	
	match item_data.rarity:
		ItemData.Rarity.COMMON:
			label.modulate = Color(1.0, 1.0, 1.0) # White
		ItemData.Rarity.MAGIC:
			label.modulate = Color(0.2, 0.5, 1.0) # Blue
		ItemData.Rarity.RARE:
			label.modulate = Color(1.0, 1.0, 0.2) # Yellow
		ItemData.Rarity.LEGENDARY:
			label.modulate = Color(1.0, 0.5, 0.0) # Orange

func interact(interactor: Node):
	if interactor.has_method("_pickup_item"):
		interactor._pickup_item(item_data)
		queue_free()
	else:
		print("Picked up: " + item_data.get_full_name())
		queue_free()
