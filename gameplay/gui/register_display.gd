@icon("res://node_icons/register_display.svg")
class_name RegisterDisplay
extends VBoxContainer

var register_name:String

var label:Label
var value:LineEdit
var bin_value:LineEdit

func _init(display_name:String):
	self.register_name = display_name

func _ready():
	self.label = Label.new()
	self.label.text = self.register_name
	self.add_child(self.label)
	self.label.owner = self
	
	self.value = LineEdit.new()
	self.value.editable = false
	self.add_child(self.value)
	self.value.owner = self
	
	self.bin_value = LineEdit.new()
	self.bin_value.editable = false
	self.add_child(self.bin_value)
	self.bin_value.owner = self
	
	self.update_value(0)

func update_value(value:int):
	self.value.text = String.num_int64(value)
	self.bin_value.text = String.num_uint64(value, 2)
	if self.bin_value.text.length() > 32:
		self.bin_value.text = self.bin_value.text.pad_zeros(64)
	elif self.bin_value.text.length() > 16:
		self.bin_value.text = self.bin_value.text.pad_zeros(32)
	elif self.bin_value.text.length() > 8:
		self.bin_value.text = self.bin_value.text.pad_zeros(16)
	else:
		self.bin_value.text = self.bin_value.text.pad_zeros(8)
