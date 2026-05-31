extends Sprite3D

#SPEED is in degrees
const SPEED = 2;

var coins : int = 5;
var playerName : String = "robot";
var is_godot_awesome : bool = true;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float) -> void:
	if (Input.is_action_pressed("ui_left")):	
		rotate_y(deg_to_rad(-SPEED));
	elif (Input.is_action_pressed("ui_right")):
		rotate_y(deg_to_rad(SPEED));
