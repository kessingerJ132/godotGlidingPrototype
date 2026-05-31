extends CharacterBody3D


const SPEED = 2
const ACCELERATION = 10

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var nav: NavigationAgent3D = $NavigationAgent3D;

func _physics_process(delta: float) -> void:
	var direction : Vector3 = Vector3();
	
	nav.target_position = Global.targetPosition;
	
	direction = nav.get_next_path_position() - global_position;
	
	if (direction.length() > 0.5):
		direction = direction.normalized();
		
		velocity = velocity.lerp(direction * SPEED, ACCELERATION * delta);
	else:
		velocity = Vector3();

	move_and_slide()
