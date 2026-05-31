extends Area3D

const DEFAULT_ROTATION = Vector3(deg_to_rad(-90), 0, 0);

var startingPosition : Vector3;
var startingRotation : Vector3;
var velocity : Vector3;
var attackDamage : int;

var timeAlive : float = 0;

func setStartingPosition(inputPosition : Vector3) -> void:
	startingPosition = inputPosition;

func setVelocity(inputVelocity : Vector3) -> void:
	velocity = inputVelocity;
	
func setRotation(inputRotation : Vector3) -> void:
	startingRotation = inputRotation;

func setDamage(inputDamage : int) -> void:
	attackDamage = inputDamage;

func getDamage() -> int:
	return attackDamage;

func _ready() -> void:
	global_position = startingPosition;
	global_rotation = startingRotation;

func _physics_process(delta : float) -> void:
	timeAlive += delta;
	if (timeAlive > 30):
		queue_free();
	global_position += velocity * delta;
