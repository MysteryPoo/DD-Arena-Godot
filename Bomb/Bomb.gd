extends RigidBody2D


export (int) var _fuse = 3
export (int) var _damage = 1

var _isOnGround = false

onready var sprite = get_node("Sprite")
onready var animation = get_node("AnimationPlayer")
onready var warning = get_node("WarningZone/WarningIndicator")
onready var collider = get_node("CollisionShape2D")

signal explode

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_fuse -= delta
	if animation.current_animation != "Explode" && _fuse < 1:
		animation.play("Explode")
	if _fuse <= 0:
		emit_signal("explode", _damage)
		queue_free()
		
func _physics_process(delta):
	if _isOnGround:
		if linear_velocity.x > 0.1:
			sprite.rotate(2*PI * delta)
		elif linear_velocity.x < -0.1:
			sprite.rotate(-2*PI * delta)
		
func Release(force: Vector2):
	self.apply_impulse(Vector2.ZERO, force)
	animation.play("Land")


func _on_WarningZone_body_entered(body: Node2D):
	var error = OK
	if body.has_method("_on_damage"):
		error = connect("explode", body, "_on_damage")
	print(error)

func _on_WarningZone_body_exited(body: Node2D):
	if body.has_method("_on_damage"):
		disconnect("explode", body, "_on_damage")

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Land":
		collider.disabled = false
		_isOnGround = true


func _on_AnimationPlayer_animation_started(anim_name):
	if anim_name == "Explode":
		warning.visible = true
