extends CharacterBody3D

const SPEED = 3;
const ACCELERATION = 5;
const MAX_HEALTH = 4;
const PROJECTILE_SPEED = 50;
const PROJECTILE_DAMAGE = 5;

var see : bool = false
var previouslySeen : bool = false;
var timeSinceShot : float = 0;
var targetPos : Vector3;
var health : int = MAX_HEALTH;

signal createProjectile;

var tempIterator : int = 0;

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	await get_tree().physics_frame;

func takeDamage(amount : int) -> void:
	health -= amount;
	if (health <= 0):
		queue_free();

func _physics_process(delta : float) -> void:
	 # go ahead and reset all momentum
	velocity = Vector3.ZERO;
	
	 # gavity calculation
	velocity.y -= gravity * 1.0 * delta;
	
	if (see):
		previouslySeen = true;
		 # set the cone to look at the player
		$Sight.look_at(targetPos, Vector3(1,0,1));
		
		 # give the navigation agent the player's position...
		$NavigationAgent3D.set_target_position(targetPos);
		
		 # ...so it can tell us where to move
		var finalPos : Vector3 = $NavigationAgent3D.get_final_position();
		var nextPos : Vector3 = $NavigationAgent3D.get_next_path_position();
		
		 # if the player is a far enough distance away, we move to it
		if (global_position.distance_to(finalPos) > 2):
			velocity = global_position.direction_to(nextPos) * SPEED;
		
		 # slowly move the enemy to look at the character
		transform = transform.interpolate_with(transform.looking_at(nextPos), 0.2);
		rotation *= Vector3(0, 1, 0);
	elif (previouslySeen):
		 # if we don't see the player, reset the vision cone rotation
		previouslySeen = false;
		$Sight.global_rotation = global_rotation;
	
	move_and_slide()

func _process(delta : float) -> void:
	 # by default we assume nothing has been seen
	see = false;
	
	 # then we check everything in the sight
	var overlap : Array[Node3D] = $Sight.get_overlapping_bodies();
	for entity in overlap:
		 # if we see the 'player', then we need to check for any obstacles
		if (entity.is_in_group("Player")):
			 # make raycast point to player
			$Sight/VisionRayCast.force_raycast_update();
			$Sight/VisionRayCast.look_at(entity.global_position);
			
			 # if first thing is collides with it the player...
			if ($Sight/VisionRayCast.is_colliding()):
				var collider : Node3D = $Sight/VisionRayCast.get_collider();
				if (collider.is_in_group("Player")):
					 # ...then we save the player's position and mark we see it
					targetPos = overlap[0].global_position;
					see = true;
					if (see && timeSinceShot >= 1):
						# signal
						print("signal sent");
						print("position x [" + str(global_position.x) + "], y: [" + str(global_position.y) + "], z: [" + str(global_position.z) + "]");
						#var projectileVelocity : Vector3 = $Sight/VisionRayCast.global_rotation.normalized() * PROJECTILE_SPEED;
						var projectileVelocity : Vector3 = $Sight.global_position.direction_to(targetPos) * PROJECTILE_SPEED;
						var projectileRotation : Vector3 = $Sight/VisionRayCast.global_rotation;
						createProjectile.emit($Sight.global_position, projectileVelocity, projectileRotation, PROJECTILE_DAMAGE);
						timeSinceShot = 0;
						#projectile.setVelocity($Sight/VisionRayCast.global_rotation.normalized() * 5);
						#projectile.setRotation($Sight/VisionRayCast.global_rotation);
						pass
					elif (see):
						timeSinceShot += delta;
	

#signal
func _on_sight_body_entered(body : Node3D) -> void:
	"""
	player = body;
	see = true;
	print("entered");
	"""
	pass # Replace with function body.


func _on_sight_body_exited(body : Node3D) -> void:
	"""
	see = false;
	print("exited");
	"""
	pass # Replace with function body.


func _on_hurt_box_area_entered(area: Area3D) -> void:
	if (area.is_in_group("PlayerHitbox")):
		takeDamage(area.getDamage());
	
