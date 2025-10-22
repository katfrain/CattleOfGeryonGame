extends Node2D

enum spawner_type_enum {
	COW,
	GADFLY,
	HEALTH
}

@export var spawner_type: spawner_type_enum
@export var max_instances_in_scene: int
@export var timer_interval: float
@export var wave_size: int = 1
@export var level_text: RichTextLabel
@export var spawned_text: RichTextLabel

@onready var spawn_timer: Timer = $Timer

# GENERAL VARIABLES
var spawn_scene: PackedScene
var world_bounds: TextureRect
var current_in_scene: int
var screen_area: Area2D
var screen_rect: Rect2
var tilemap: TileMapLayer
var player_level = 1
var next_level_needed = 2
var level_interval = 2
var base_wave_size

# SCENES
var cow_scene: PackedScene = preload("res://Scenes/cow.tscn")
var fly_scene: PackedScene = preload("res://Scenes/gadfly.tscn")
var health_scene: PackedScene = preload("res://Scenes/health_drop.tscn")


func _ready() -> void:
	world_bounds = get_parent().get_node("World Bounds") as TextureRect
	var player = get_parent().get_node("Player")
	screen_area = player.get_node("Viewport Bounds") as Area2D
	base_wave_size = wave_size
	
	match spawner_type:
		spawner_type_enum.COW:
			spawn_scene = cow_scene
			updated_spawned_text()
			wave_size = 1
			current_in_scene = 2
		spawner_type_enum.GADFLY:
			spawn_scene = fly_scene
		spawner_type_enum.HEALTH:
			spawn_scene = health_scene
	
	screen_rect = get_area_rect(screen_area)
	spawn_timer.wait_time = timer_interval
	spawn_timer.timeout.connect(on_spawn_timer_timeout)
	spawn_timer.start()
	
	tilemap = get_parent().get_node("TileMap") as TileMapLayer
	level_text.visible = false

	
func on_spawn_timer_timeout():
	if current_in_scene >= max_instances_in_scene:
		return
	
	#print("Attempting to spawn ", name)
	var pos = get_spawn_position()
	
	match spawner_type:
		spawner_type_enum.COW:
			if wave_size <= 0: return
			if current_in_scene >= max_instances_in_scene: return
			var instance = spawn_scene.instantiate()
			instance.global_position = pos + Vector2(randf_range(3,20), randf_range(3,20))
			instance.z_index = 1
			add_child(instance)
			current_in_scene += 1
			wave_size -= 1
			if wave_size <= 0:
				update_level_text()
				level_text.visible = true
			updated_spawned_text()
			if current_in_scene == max_instances_in_scene:
				level_text.visible = false
			print(current_in_scene, " ", name, "(s) spawned")
		spawner_type_enum.GADFLY:
			for i in range(wave_size):
				if current_in_scene >= max_instances_in_scene: return
				var instance = spawn_scene.instantiate()
				instance.global_position = pos + Vector2(randf_range(3,20), randf_range(3,20))
				instance.z_index = 1
				add_child(instance)
				current_in_scene += 1
		spawner_type_enum.HEALTH:
			if current_in_scene >= max_instances_in_scene: return
			var instance = spawn_scene.instantiate()
			instance.global_position = pos + Vector2(randf_range(3,20), randf_range(3,20))
			instance.z_index = 1
			add_child(instance)
			current_in_scene += 1
			print("Health drop spawned")

func get_spawn_position() -> Vector2:
	if not tilemap:
		push_warning("Spawner has no TileMap reference — using fallback random spawn.")
		return Vector2(0, 0)
	
	for i in range(200): # safety cap
		screen_rect = get_area_rect(screen_area)
		var pos = Vector2(
			randf_range(world_bounds.position.x, world_bounds.position.x + world_bounds.size.x),
			randf_range(world_bounds.position.y, world_bounds.position.y + world_bounds.size.y)
		)

		if screen_rect.has_point(pos):
			continue # don't spawn on screen
		
		# Convert world position to tile coordinates
		var cell = tilemap.local_to_map(tilemap.to_local(pos))
		var tile_data = tilemap.get_cell_tile_data(cell)
		
		if tile_data and tile_data.get_custom_data("Spawnable"):
			return pos
	
	push_warning("No valid spawn position found after 200 attempts.")
	return Vector2.ZERO

	
func remove_from_scene() -> void:
	current_in_scene = max(current_in_scene - 1, 0)
	if spawner_type == spawner_type_enum.COW:
		updated_spawned_text()
		wave_size += 1
			
func get_area_rect(area: Area2D) -> Rect2:
	var col = area.get_node("CollisionShape2D") as CollisionShape2D
	if col and col.shape is RectangleShape2D:
		var rect_shape = col.shape as RectangleShape2D
		var extents = rect_shape.extents * col.global_scale  # account for scale
		var top_left = col.global_position - extents
		var size = extents * 2
		return Rect2(top_left, size)
	return Rect2()
	
func level_up() -> void:
	player_level += 1
	if player_level >= next_level_needed:
		wave_size += base_wave_size
		next_level_needed += level_interval
		level_text.visible = false
		
func update_level_text() -> void:
	level_text.text = str("Next Cows Spawn at: Level ", next_level_needed)
	
func updated_spawned_text() -> void:
	spawned_text.text = str(current_in_scene, " Spawned")
	
