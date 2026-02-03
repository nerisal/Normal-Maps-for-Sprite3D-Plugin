@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("Sprite3DwNormals", "Sprite3D", preload("sprite_3d_w_normals.gd"), preload("sprite_wnm_icon.svg"))
	#add_custom_type("AnimatedSprite3DwNormals", "AnimatedSprite3D", preload("animated_sprite_3d_w_normals.gd"), preload("animated_sprite_wnm_icon.svg"))
	
func _exit_tree():
	remove_custom_type("Sprite3DwNormals")
