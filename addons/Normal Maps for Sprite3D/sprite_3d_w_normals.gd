@tool
class_name Sprite3DwNormals extends Sprite3D

## Sprite3D whith Animations and Normal Maps.
## Expecially made for PixelArt  

@export var normal: Texture2D: ## Texture3D object to draw as a Normal Map
	set(value):
		normal = value
		if normal != null:
			material_override.normal_texture = load(normal.resource_path)
		else:
			material_override.normal_texture = null

@export_category("Create Frame Animation")

@export var animation_player : AnimationPlayer ## Animation Player where the animation is created
@export var delete_existed_animation_before_creating : bool = false ## Set True if you want to delete the already existed animation with the same name before creating


@export_category("Create One Frame Animation")
@export var animation_name : String = "default" ## Name of the new animation
@export var animation_col : int = 1 ## The column on which the frame of an animation are located (start from 1)
@export var animation_row : int = 1 ## The row on which the frame of an animation are located (start from 1)
@export var frame_number : int = 0 ## The number of frames of the animation
@export var frame_duration : int = 120 ## Duration of each frame in milliseconds (ms)
@export var loop_mode : Animation.LoopMode = Animation.LoopMode.LOOP_NONE
@export var create_animation : bool = false: ## Press this only when everything above is set. I know that this is a checkbox and not a button ;)
	set(value):
		if value == true:
			_update_animation_track_path()
			_create_frame_animation(animation_name, loop_mode, animation_col, animation_row, frame_number, frame_duration)

@export_category("Create Frame Animation From Json")
@export_file("*.json") var json_path: String
@export var create_animation_from_json : bool = false: ## Press this only when json is set. I know that this is a checkbox and not a button ;)
	set(value):
		if value == true :
			_update_animation_track_path()
			_create_frame_animation_from_json(json_path)

@onready var animation_track_path : String = "Sprite3DwNormals" ## Name of the new animation track path

func _create_frame_animation_from_json(json_path: String):
	if json_path == "":
		printerr("The JSON file path is not set correctly")
		return

	# Load and parse JSON file
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		printerr("Failed to open JSON file")
		return

	var json_content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_content)
	if parse_result != OK:
		printerr("Failed to parse JSON file: " + json.get_error_message())
		return

	var animations = json.data
	if not animations is Array:
		printerr("JSON data is not an array")
		return

	# Process each animation in the JSON array
	for anim_config in animations:
		if not anim_config is Dictionary:
			printerr("Animation config is not a dictionary")
			continue

		# Extract animation properties from config
		var anim_name = anim_config.get("animation_name", "default")
		var anim_col = anim_config.get("animation_col", 1)
		var anim_row = anim_config.get("animation_row", 1)
		var anim_frames = anim_config.get("frame_number", 0)
		var anim_duration = anim_config.get("frame_duration", 120)

		# Handle loop_mode conversion
		var loop_mode_str = anim_config.get("loop_mode", "LOOP_NONE").to_upper()
		var loop_mode = Animation.LoopMode.LOOP_NONE
		if loop_mode_str == "LOOP_NONE" or loop_mode_str == "NONE":
			loop_mode = Animation.LoopMode.LOOP_NONE
		elif loop_mode_str == "LOOP_LINEAR" or loop_mode_str == "LINEAR":
			loop_mode = Animation.LoopMode.LOOP_LINEAR
		elif loop_mode_str == "LOOP_PINGPONG" or loop_mode_str == "PINGPONG":
			loop_mode = Animation.LoopMode.LOOP_PINGPONG

		# Create the animation
		_create_frame_animation(anim_name, loop_mode, anim_col, anim_row, anim_frames, anim_duration)

func _update_animation_track_path() -> void:
	var animation_player_s_root_node_path = String(get_node(animation_player.root_node).get_path())
	var this_full_path = String(self.get_path())

	# Calculate relative path from animation player's root node to this node
	var relative_path = cal_relative_path(animation_player_s_root_node_path, this_full_path)
	animation_track_path = relative_path

func _ready() -> void:

	if get_material_override() == null:
		var spriteMaterial = StandardMaterial3D.new()
		set_material_override(spriteMaterial)
		material_override.normal_enabled = true
		material_override.set_transparency(1)
		material_override.set_cull_mode(2)
		material_override.set_texture_filter(0) #Set to Nearest for Pixel Art


func _set(property, value):
	if property == "texture":
		if value != null:
			material_override.albedo_texture = load(value.resource_path)
		else:
			material_override.albedo_texture = null

func cal_relative_path(from_path: String, to_path: String) -> String:

	var from_parts = from_path.split("/")
	var to_parts = to_path.split("/")

	# Remove empty strings from splits
	var filtered_from = []
	for part in from_parts:
		if part != "":
			filtered_from.append(part)
	var filtered_to = []
	for part in to_parts:
		if part != "":
			filtered_to.append(part)

	# Find common ancestor
	var common_index = 0
	while common_index < filtered_from.size() and common_index < filtered_to.size() and filtered_from[common_index] == filtered_to[common_index]:
		common_index += 1

	# Build relative path manually
	var relative_path = ""

	# Add up steps
	for i in range(filtered_from.size() - common_index):
		relative_path += "../"

	# Add down steps
	for i in range(common_index, filtered_to.size()):
		relative_path += filtered_to[i]
		if i < filtered_to.size() - 1:
			relative_path += "/"

	# Remove trailing slash if present
	if relative_path.ends_with("/"):
		relative_path = relative_path.left(relative_path.length() - 1)

	return relative_path

func _create_frame_animation(_animation_name: String, _loop_mode: Animation.LoopMode, _animation_col: int, _animation_row: int, _frame_number: int, _frame_duration: int):
	if animation_player == null:
		printerr("The Animation Player Node in not set correctly")
		return

	var animation_list = animation_player.get_animation_list()

	if animation_list.has(_animation_name):
		if not delete_existed_animation_before_creating:
			printerr("There is already an animation with this name")
			return

		for animation_lab_name in animation_player.get_animation_library_list():
			var animation_lab = animation_player.get_animation_library(animation_lab_name)
			if animation_lab.has_animation(_animation_name):
				animation_lab.remove_animation(_animation_name)

	var animation = Animation.new()
	var track_index = animation.add_track(Animation.TYPE_VALUE)

	var time : float = 0
	var coords : Vector2i = Vector2i(_animation_col - 1, _animation_row - 1)

	animation.loop_mode = _loop_mode
	animation.track_set_path(track_index, animation_track_path + ":frame_coords")
	animation.track_set_interpolation_type(track_index, 0) # Set the interpolation type to nearest for pixel art

	for n in range(_frame_number):
		animation.track_insert_key(track_index, time, coords)
		#animation.track_insert_key(track_index, time, value)
		time += float(_frame_duration)/1000
		coords.x += 1

	animation.set_length(time)
	animation_player.get_animation_library("").add_animation(_animation_name, animation)

