extends Node

var mapData

func load_map(data):
	self.mapData = data
	get_tree().change_scene_to_file("res://gameplay/gameplay.tscn")

func back_to_main_menu():
	get_tree().change_scene_to_file("res://main_menu/main_menu.tscn")
