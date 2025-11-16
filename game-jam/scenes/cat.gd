class_name player
extends CharacterBody2D


var health :int = 100
var damage: int = 20
const SPEED = 250.0
const JUMP_VELOCITY = -350.0
var DASH_SPEED := 4
var is_dashing := false
var is_attacking := false
var is_looking_down := false
var can_control := true
var facing:= 0
@onready var healthbar := $Label/ProgressBar
@onready var attack_collision = $AttackArea/CollisionShape2D
@onready var animated_sprite = $AnimatedSprite2D
var last_collision_position: Vector2
var COLISSION_OFFSET := Vector2(29,0)
var jump_count := 0

func _ready() -> void:
	healthbar.value = health
	
func _physics_process(delta: float) -> void:
	velocity += get_gravity() * delta
	
	if not can_control: return
	if health == 0: handle_danger()
	if Input.is_action_just_pressed("jump") && jump_count < 1:
		$Sounds/JumpSound.play()
		velocity.y = JUMP_VELOCITY  
		jump_count +=1
	

		
		
	var direction := Input.get_axis("left", "right")
			
	if direction > 0: 
		animated_sprite.flip_h = true
		$AttackArea.scale.x = -1
		facing = direction
	elif direction < 0: 
		animated_sprite.flip_h = false
		$AttackArea.scale.x = 1
		facing = direction
	
	if Input.is_action_just_pressed("dash"):
		if not is_dashing and direction:
			$Sounds/DashSound.play()
			start_dash()
	
	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		attack_collision.disabled = false

		if is_looking_down:
			animated_sprite.play("attack_down")
		else:
			animated_sprite.play("attack")
		$Sounds/AttackSound.play()
	
	
	if Input.is_action_just_pressed("attack_down"):
		attack_collision.rotation_degrees = 90
		$AttackArea.position.y += 20
		is_looking_down = true
	if Input.is_action_just_released("attack_down"):
		attack_collision.rotation_degrees = 0
		$AttackArea.position.y -= 20
		is_looking_down = false
	
	handle_animations(direction)	
			
	if direction:	
		if is_dashing:
			velocity.x = direction * SPEED * DASH_SPEED
		else:	velocity.x = direction * SPEED
 
	else:	velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	

func handle_animations(dir: float)-> void:
	
	if is_attacking: return
	elif is_dashing: animated_sprite.play("dashing")
		
	else:
		if is_on_floor():	
			jump_count = 0
			if dir && not is_attacking:	animated_sprite.play("walking")
			elif !dir && not is_attacking :	animated_sprite.play("idle")
		else:
			if animated_sprite.animation != "jumping" and not is_attacking:
				animated_sprite.play("jumping")

func start_dash() -> void:
	is_dashing = true
	$DashTimer.connect("timeout",_stop_dash)
	$DashTimer.start()

func _stop_dash() -> void:
	is_dashing = false
	

func _on_animated_sprite_finished() -> void:
	if animated_sprite.animation == "attack" or animated_sprite.animation == "attack_down":
		attack_collision.disabled =true
		is_attacking = false

func set_health(new_health: int)-> void:
	health = new_health
	healthbar.value = health
	
func take_damage(amount: int, damage_dir: Vector2) -> void:
	set_health(max(health-amount,0))
	animated_sprite.play("hit")
	velocity += damage_dir.normalized() * 100
	
	
func handle_danger()->void:
	$Sounds/Fahh.play()
	can_control = false
	set_health(0)
	
	await get_tree().create_timer(1).timeout
	reset_player()
	
func reset_player()->void:
	global_position = Vector2(535.0,302.0)
	can_control = true
	set_health(100)


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body is boss:
		body.take_damage(damage)
