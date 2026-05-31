extends Node

# All global variables
var projectileScene : PackedScene = preload("res://enemy_projectile.tscn");

func _on_basic_enemy_create_projectile(extra_arg_0: Vector3, extra_arg_1: Vector3, extra_arg_2: Vector3, extra_arg_3: int) -> void:
	createProjectile(extra_arg_0, extra_arg_1, extra_arg_2, extra_arg_3);
	pass # Replace with function body.

func createProjectile(position : Vector3, velocity : Vector3, rotation : Vector3, damage : int) -> void:
	print("signal received: attempting to make projectile");
	var scene : Area3D = projectileScene.instantiate();
	print("position x [" + str(position.x) + "], y: [" + str(position.y) + "], z: [" + str(position.z) + "]");
	scene.setStartingPosition(position);
	scene.setVelocity(velocity);
	scene.setRotation(rotation);
	scene.setDamage(damage);
	add_child(scene);

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float) -> void:
	pass
