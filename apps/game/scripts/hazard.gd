class_name Hazard
extends Area2D
## A hurtbox the engineer can be knocked down by. It sits on the hazard physics layer (which the
## engineer's body masks and WOLF's does not), scans the actor layer, and reports contact only
## for the engineer and only while [member armed], so a room arms it from real state (a blown
## vent, a live blast zone) and never from a timer of its own.

signal contact(hazard: Hazard)

## Physics layer 4; the engineer's collision_mask includes it, WOLF's does not.
const HAZARD_LAYER_BIT: int = 8
## Physics layer 1, where both actors' bodies live.
const ACTOR_LAYER_BIT: int = 1

## What the status line says after the knockdown: the cause and the fix.
@export var reason: String = ""
@export var armed: bool = false:
	set(value):
		armed = value
		if armed and not _inside.is_empty():
			contact.emit(self)

var _inside: Array[M0Actor] = []


func _init() -> void:
	collision_layer = HAZARD_LAYER_BIT
	collision_mask = ACTOR_LAYER_BIT
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## A rectangular hazard covering [param rect] in the parent's space.
static func make(hazard_name: String, rect: Rect2, cause: String) -> Hazard:
	var hazard: Hazard = Hazard.new()
	hazard.name = hazard_name
	hazard.reason = cause
	hazard.position = rect.get_center()
	var shape: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	hazard.add_child(shape)
	return hazard


func _on_body_entered(body: Node2D) -> void:
	if not (body is M0Actor) or (body as M0Actor).actor_id != &"human":
		return
	var actor: M0Actor = body as M0Actor
	if not _inside.has(actor):
		_inside.append(actor)
	if armed:
		contact.emit(self)


func _on_body_exited(body: Node2D) -> void:
	if body is M0Actor:
		_inside.erase(body as M0Actor)
