extends Node3D
## Spawns a fixed debris field for F002 (no sector streaming yet).

const DEBRIS_SCENE := preload("res://scenes/harvestable_debris.tscn")

@export var spawn_specs: Array[Dictionary] = [
	{"pos": Vector3(120, 8, -60), "mass": 25.0},
	{"pos": Vector3(180, -12, 40), "mass": 30.0},
	{"pos": Vector3(240, 20, 120), "mass": 20.0},
	{"pos": Vector3(-90, 5, 150), "mass": 35.0},
	{"pos": Vector3(-200, -8, -80), "mass": 28.0},
	{"pos": Vector3(60, 15, -180), "mass": 22.0},
	{"pos": Vector3(310, 0, -40), "mass": 40.0},
	{"pos": Vector3(-150, 25, -120), "mass": 18.0},
	{"pos": Vector3(400, -15, 90), "mass": 32.0},
	{"pos": Vector3(-280, 10, 60), "mass": 26.0},
	{"pos": Vector3(150, -20, -250), "mass": 45.0},
	{"pos": Vector3(-60, 30, 280), "mass": 15.0},
]


func _ready() -> void:
	for spec in spawn_specs:
		var debris = DEBRIS_SCENE.instantiate()
		add_child(debris)
		debris.global_position = spec.get("pos", Vector3.ZERO)
		debris.mass = spec.get("mass", 25.0)
		if spec.has("material"):
			debris.material_id = spec.material
