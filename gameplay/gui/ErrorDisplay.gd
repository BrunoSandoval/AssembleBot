@icon("res://gameplay/gui/Style/ErrorIcon.svg")
class_name ErrorDisplay extends PanelContainer

const STYLE:StyleBoxFlat = preload("res://gameplay/gui/Style/error_display_style.tres")

@export var text:String
@export var line:int
var fadeout_timer:float

var label:Label = Label.new()

func _init(error_text:String, error_line:int = -1, fadeout_time:float = -1):
	self.text = error_text
	self.line = error_line
	self.fadeout_timer = fadeout_time
	
	self.add_theme_stylebox_override("panel", STYLE)
	self.anchor_left = 0.13
	self.anchor_top = 0.09
	self.anchor_right = 0.59
	self.anchor_bottom = 0.14
	
	label.text = self.text \
			if self.line < 0 else \
			tr("ERROR_DISPLAY_STRING").format({"text":self.text, "line":self.line+1})
	self.add_child(label)

func _ready():
	if fadeout_timer > 0:
		get_tree().create_timer(fadeout_timer).timeout.connect(disappear)

func disappear():
	var fade_tween = self.create_tween()
	fade_tween.finished.connect(queue_free)
	fade_tween.tween_property(self, "modulate", Color.TRANSPARENT, 1)

