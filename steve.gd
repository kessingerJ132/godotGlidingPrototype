extends CharacterBody3D

enum State {GROUNDED, GLIDING};

var characterState : State = State.GROUNDED;
const SPEED = 6.0
const JUMP_VELOCITY = 7;
const LOOKAROUND_SPEED = .002;
const RADIUS = 70;

var MAX_THRUST_SPEED : int = 0;
var MIN_THRUST_SPEED : int = 0;

const MAX_HEALTH : int = 10;
const NORMAL_ATTACK_DAMAGE : int = 2;

var currentThrust : int = 0;

const SKILL_BUTTON = "skill_use";

# this value is at what speed the character will turn at the same rate as the camera
# any slower and the turn rate is proportional to this value
# example: a speed of 5 means the character turns at 50% the speed
const GLIDE_LIFT_SPEED : int = 20;
const GLIDE_TURN_RATE : int = 8;
const GLIDE_MIN_SPEED : int = 2;
const GLIDE_MAX_SPEED : int = 25;
const GLIDE_DIVE_ACCEL : int = 4;
const GLIDE_DRAG : float = 0.3;
const GLIDE_CONTROL_MAX_DEGREES = 30;
const GLIDE_CONTROL_MAX =  deg_to_rad(GLIDE_CONTROL_MAX_DEGREES);

var rotX : float = 0.0;
var rotY : float = 0.0;
var cameraRotX : float = 0.0;
var cameraRotY : float = 0.0;
var cameraRotStrengthX : float = 1.0;
var cameraRotStrengthY : float = 1.0;

var setWeight : bool = false;
var lastRotY : float = 0

var charVelocity : Vector3  = Vector3();
var glideLookChange : float = 0.025;
var glideLookChange_angle : float = 0.5;
var restrictCamMovement : float  = 1.0;
var jumpTimer : float = 0;

var health: int = MAX_HEALTH;
var hitBoxActiveTimer : float = 0;

var meshInstance : MeshInstance3D;
var originalColor : Color;
var invertedColor : Color;
var colorInverted : bool = false;

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity");

func _enter_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;
	$MeleeHitBox.normalAttackDamage = NORMAL_ATTACK_DAMAGE;
	meshInstance = $MeshInstance3D;
	originalColor = $MeshInstance3D.mesh.surface_get_material(0).albedo_color;
	invertedColor = originalColor.inverted();

func takeDamage(amount : int) -> void:
	health -= amount;
	if (health <= 0):
		#TODO death screen
		pass
	
func handleWalkAndJump(delta : float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta;
		if (velocity.y < 0):
			velocity.y -= (gravity * .5) * delta;
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir : Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward");
	var direction : Vector3 = ($cameraController.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized();
	if direction:
		velocity.x = direction.x * SPEED;
		velocity.z = direction.z * SPEED;
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED);
		velocity.z = move_toward(velocity.z, 0, SPEED);
	
	# if jump is pressed, start the timer
	if Input.is_action_pressed("jump_button") and is_on_floor():
		# begin charging jump if crouch is pressed
		if Input.is_action_pressed("crouch"):
			jumpTimer += 1 * delta;
			velocity.x = 0;
			velocity.z = 0;
			# if held for long enough, we change the color to let the player know
			if jumpTimer >= 1 and !colorInverted:
				$MeshInstance3D.mesh.surface_get_material(0).albedo_color = invertedColor;
				colorInverted = true;
		else:
			#normal jump
			velocity.y = JUMP_VELOCITY;
	
	# once its release, do a big jump if it was held for long enough
	if Input.is_action_just_released("jump_button") and is_on_floor() and jumpTimer > 0:
		if jumpTimer >= 1:
			velocity.y = JUMP_VELOCITY * 3;
		else:
			velocity.y = JUMP_VELOCITY;
		# reset jumpTimer and color if needed
		jumpTimer = 0;
		if colorInverted:
			$MeshInstance3D.mesh.surface_get_material(0).albedo_color = originalColor;
			colorInverted = false;
	
	#skill use handler
	if Input.is_action_just_pressed("skill_use") and !is_on_floor():
		characterState = State.GLIDING;
		velocity = ($cameraController.basis * Vector3(0, 0, -1)).normalized() * 5;
	
	# Rotate character mesh so oriented towards movement
	# If an arrow key is pressed
	if input_dir != Vector2(0, 0):
		# make the character look at where it is going, but only horizontally
		look_at(global_position + (velocity * Vector3(1, 0 ,1)) );
	

func handleGliding(delta : float) -> void:
	# apply gravity
	velocity.y -= gravity * delta;
	
	# current direction
	var velocityDirection : Vector3 = velocity.normalized();
	# how much we're going down
	var diveStrength : float = -velocityDirection.y;
	# accelerate or deccelerate the player proportionally to how much the player is moving vertically
	# this makes accelerating and deccelerating from gravity faster
	velocity += velocityDirection * diveStrength * GLIDE_DIVE_ACCEL * delta;
	
	velocity = velocity * ( 1.0 - (GLIDE_DRAG * delta) );
	
	# have a speed limit
	if (velocity.length() > GLIDE_MAX_SPEED):
		velocity = velocity.normalized() * GLIDE_MAX_SPEED;
	
	# calculate the direction that the camera is telling the character to move to
	var cameraDirection : Vector3 = ( -$cameraController.global_transform.basis.z );
	
	var angle : float = velocity.angle_to(cameraDirection);
	var desiredDirection : Vector3;
	
	if (angle > GLIDE_CONTROL_MAX):
		desiredDirection = velocity.slerp(cameraDirection, GLIDE_CONTROL_MAX/angle);
	else:
		desiredDirection = cameraDirection;
	
	# multiply it by the velocity's magnitude to prevent changing the speed
	desiredDirection = desiredDirection.normalized() * velocity.length();
	# we don't want to set the direction, only influence it based on character's velocity
	var turnRate : float = clamp(velocity.length()/GLIDE_LIFT_SPEED, 0.0, 1.0);
	turnRate = turnRate * turnRate * GLIDE_TURN_RATE;
	
	# this slerp influences the character to the desiredDirection based upon the turnRate
	velocity = velocity.slerp(desiredDirection, delta * turnRate);
	
	# rotate the character to have it look at where it's going
	if (abs(velocity.normalized().y) != 1):
		look_at(global_position + velocity);
	
	# changing the state
	if (Input.is_action_just_pressed("skill_use") || is_on_floor()):
		characterState = State.GROUNDED;
		rotation_degrees.x = 0;
		rotation_degrees.z = 0;

func _physics_process(delta : float) -> void:
	# gravity is handled in each character's states seperately
	match(characterState):
		State.GROUNDED:
			handleWalkAndJump(delta);
		State.GLIDING:
			handleGliding(delta);
	
	# prevent y rotation from going upside down
	rotY = clamp(rotY, deg_to_rad(-90), deg_to_rad(70));
	
	# reset rotation
	$cameraController.transform.basis = Basis();
	# first rotate in Y
	$cameraController.rotate_object_local(Vector3(0, -1, 0), rotX);
	# then rotate in X
	$cameraController.rotate_object_local(Vector3(-1, 0, 0), rotY);
	
	move_and_slide();
	
	if (hitBoxActiveTimer > 0):
		hitBoxActiveTimer -= delta;
		if (hitBoxActiveTimer <= 0):
			hitBoxActiveTimer = 0;
			$MeleeHitBox/CollisionShape3D.disabled = true;
	
	elif (Input.is_action_just_pressed("normal_attack")):
		hitBoxActiveTimer += .5;
		$MeleeHitBox/CollisionShape3D.disabled = false;
	
	# Camera Controller follow character
	$cameraController.position = lerp($cameraController.position, position, 0.2);

func _input(event : InputEvent) -> void:
	# if the mouse is moved and we're in gameplay stage
	if (event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):
		rotX += event.relative.x * LOOKAROUND_SPEED;
		rotY += event.relative.y * LOOKAROUND_SPEED;
	
	# controls mouse
	if Input.is_action_just_pressed("mouse_mode_toggle"):
		if (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;

func _exit_tree() -> void:
	pass


func _on_hurt_box_area_entered(area: Area3D) -> void:
	if (area.is_in_group("EnemyHitbox")):
		takeDamage(area.getDamage());
		pass
