extends CharacterBody2D

@export var speed = 300
@export var cattle_needed = 15

@onready var feet_area: CollisionShape2D = $Feet

var amt_of_cattle = 0
var head_collision

signal got_cow
signal lost_cow

# COW SWARM VARIABLES
var base_radius = 50        # distance of first circle from player
var radius_step = 30        # how much each additional circle grows
var slots_per_circle = 8    # base number of slots in first circle
var cow_slots: Array[CowSlot] = []
var assigned_slots: Array[bool]
var rings: int

func _ready() -> void:
	amt_of_cattle = 0
	add_to_group("player")
	
	cow_slots = get_slots_for_cows(cattle_needed)
	assigned_slots = create_cow_slot_assigned_arr(cow_slots)
	rings = get_num_of_rings(slots_per_circle, cattle_needed)
	
	# DEBUG
	queue_redraw()

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	if head_collision and input_direction.y < 0:
		input_direction.y = 0
	
	velocity = input_direction * speed

func _physics_process(delta):
	get_input()
	move_and_slide()
	
func _add_cattle(cattle_pos: Vector2) -> CowSlot:
	amt_of_cattle += 1
	got_cow.emit()
	print("Amount of cattle: ", amt_of_cattle)
	var cow_target = assign_slot(cattle_pos, slots_per_circle, rings)
	if amt_of_cattle >= cattle_needed:
		_cattle_amt_reached()
	return cow_target
		
func lose_cattle() -> void:
	amt_of_cattle -= 1
	lost_cow.emit()
	recompute_assignments()
	print("Amount of cattle: ", amt_of_cattle)
		
func _cattle_amt_reached() -> void:
	pass


func _on_head_area_body_entered(body: Node2D) -> void:
	head_collision = true


func _on_head_area_body_exited(body: Node2D) -> void:
	head_collision = false

# COW SWARM LOGIC
func get_slots_for_cows(num_cows: int) -> Array[CowSlot]:
	var slots: Array[CowSlot] = []
	var cows_remaining = num_cows
	var circle_index = 0
	
	while cows_remaining > 0:
		var radius = base_radius + circle_index * radius_step
		var slots_in_this_circle = slots_per_circle + circle_index * 2
		
		for i in range(min(cows_remaining, slots_in_this_circle)):
			var angle = (float(i) / float(slots_in_this_circle)) * TAU
			slots.append(CowSlot.new(angle, radius, self))
		
		cows_remaining -= slots_in_this_circle
		circle_index += 1
	
	return slots
	
func create_cow_slot_assigned_arr(slots: Array[CowSlot]) -> Array[bool]:
	var bool_arr: Array[bool] = []
	for i in range(slots.size()):
		bool_arr.append(false)
	return bool_arr
		
	
func assign_slot(cow_pos: Vector2, slots_per_circle: int, rings: int) -> CowSlot:
	var slot_index := 0
	
	for circle_index in range(rings):
		var slots_in_circle = slots_per_circle + circle_index * 2
		var best_slot: int = -1
		var shortest_distance: float = INF
		
		for i in range(slots_in_circle):
			if slot_index >= cow_slots.size():
				break
			var slot = cow_slots[slot_index]
			
			if not slot.assigned:
				var dist = get_slot_global_position(slot).distance_to(cow_pos)
				if dist < shortest_distance:
					shortest_distance = dist
					best_slot = slot_index
			slot_index += 1
		
		if best_slot != -1:
			cow_slots[best_slot].assigned = true
			return cow_slots[best_slot]
	
	push_error("No available cow slots!")
	return null

func get_num_of_rings(slots_per_circle: int, cattle: int) -> int:
	var rings: int = 0
	var remaining: int = cattle
	
	while remaining > 0:
		var slots_in_this_circle = slots_per_circle + rings * 2
		remaining -= slots_in_this_circle
		rings += 1
	
	return rings
	
func get_slot_global_position(slot: CowSlot) -> Vector2:
	return feet_area.global_position + Vector2(cos(slot.angle), sin(slot.angle)) * slot.radius
	
func recompute_assignments() -> void:
	# reset all slots
	for i in range(assigned_slots.size()):
		assigned_slots[i] = false

	# get all cows
	var cows = get_tree().get_nodes_in_group("cows")

	# reassign each cow
	for cow in cows:
		if cow.state == cow.States.FOLLOWING:
			var new_slot = assign_slot(cow.global_position, slots_per_circle, rings)
			cow.target = new_slot
		
# DEBUG
func _draw() -> void:
	for slot in cow_slots:
		draw_circle(to_local(get_slot_global_position(slot)), 5, Color.RED)
