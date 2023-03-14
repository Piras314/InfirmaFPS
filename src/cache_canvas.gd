extends CanvasLayer

var num1 = preload("res://scn/ent/muzzle.material")

var materials = [
	num1,
]

# Called when the node enters the scene tree for the first time.
func _ready():
	for mat in materials:
		var inst = GPUParticles3D.new()
		
		inst.set_process_material(mat)
		inst.set_one_shot(true)
		inst.set_emitting(true)
		
		self.add_child(inst)
