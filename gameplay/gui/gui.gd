extends Control

const NO_COLOR:Color = Color(0, 0, 0, 0)
const ERROR_LINE_COLOR:Color = Color(1,0,0,0.4)
@export var opcode_color:Color = Color(0.98, 0.431, 0.51)
@export var reg_colors:Array[Color] = [
	Color(0.596, 0.839, 0.859), # byte_low
	Color(0.596, 0.839, 0.859), # byte_high
	Color(0.506, 0.816, 0.784), # word
	Color(0.392, 0.796, 0.71),  # dword
	Color(0.216, 0.745, 0.584), # qword
]

var keyword_colors:Array[Dictionary] = [{},{}]

var is_executing:bool = false:
	set(value):
		is_executing = value
		_update_run_state()
	get:
		return is_executing

var selected_parser:int = 0:
	set(value):
		if value == selected_parser:
			return
		selected_parser = value
		$Program.syntax_highlighter.keyword_colors = keyword_colors[selected_parser]
		#request_full_check.emit($Program.text)
	get:
		return selected_parser

var program_text:String:
	get:
		return $Program/Program.text+"\n"

var available_reg_sizes = []

var reg_displays:Array[RegisterDisplay] = []
var assembler:Assembler = Assembler.new()
@onready var robot:RobotBase = $"../Robot"

#var _tracked_error_displays:Dictionary = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	_prepare_keyword_highlights()
	$Program/Program.syntax_highlighter.keyword_colors = keyword_colors[selected_parser]
	self.assembler.error_found.connect(self.show_error_at_line)
	
	# Prepare the register displays
	for i in range(self.robot.processor.registers.size()):
		var reg_disp:RegisterDisplay = RegisterDisplay.new(ParserData.BASE_VALID_REGISTERS[i][4])
		$RegisterShow/RegisterContainer.add_child(reg_disp)
		self.reg_displays.append(reg_disp)
		var reg_btn:CheckButton = CheckButton.new()
		reg_btn.text = ParserData.BASE_VALID_REGISTERS[i][4]
		reg_btn.toggled.connect(reg_disp.set_visible)
		reg_btn.button_pressed = true
		$RegisterMenu/VBox.add_child(reg_btn)
		$RegisterMenu/VBox.add_spacer(false)
		
	#$ParserSelect.item_selected.connect(Callable(self, "@selected_parser_setter"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


# adds the missing errors to tracked_error_displays, updates preexisting errors
#func merge_tracked_errors(errors:Dictionary):
	#while not $ErrorContainer/Timer.is_stopped():
		#await $ErrorContainer/Timer.timeout
	#$ErrorContainer/Timer.start()
	#for line in errors:
		#if _tracked_error_displays.has(line):
			#if _tracked_error_displays[line].text == errors[line].error_text:
				#continue
			#_tracked_error_displays[line].disappear()
		#_tracked_error_displays[line] = show_error_text(errors[line].error_text)
		#$Program.set_line_background_color(line, Color(1,0,0,0.4))
		#await $ErrorContainer/Timer.timeout
	#$ErrorContainer/Timer.stop()
 
func show_error_at_line(text:String, line:int) -> void:
	$ErrorContainer.add_child(ErrorDisplay.new(text, line))
	#_tracked_error_displays[line] = NewErrRect
	($Program/Program as CodeEdit).set_line_background_color(line, ERROR_LINE_COLOR)

func show_error_text(text:String, timeout:float = -1) -> void:
	$ErrorContainer.add_child(ErrorDisplay.new(text, -1, timeout))

func disappear_all_errors() -> void:
	for err_node:PanelContainer in $ErrorContainer.get_children():
		($Program/Program as CodeEdit).set_line_background_color(err_node.line, NO_COLOR)
		err_node.disappear()

# disappears and stops tracking an error
#func disappear_parse_error(line:int):
	#if not _tracked_error_displays.has(line):
		#return
	#_tracked_error_displays[line].disappear()
	#_tracked_error_displays.erase(line)
	#$Program.set_line_background_color(line, Color(0,0,0,0))

func step_program() -> void:
	if self.robot.execute():
		self.update_registers()
	else:
		$Program/Run.disabled = true
		$Program/Step.disabled = true
		stop_running()
		
	self.highlight_line(self.robot.processor.get_instruction_line())

func start_running() -> void:
	$Program/Timer.start()
	$SpeedBox.editable = false
	$Program/Stop.visible = true
	$Program/Run.visible = false

func stop_running() -> void:
	$Program/Timer.stop()
	$SpeedBox.editable = true
	$Program/Stop.visible = false
	$Program/Run.visible = true

var prev_highlighted_line:int = 0
func highlight_line(line:int) -> void:
	if line < 0:
		return
	$Program/Program.set_line_as_executing(prev_highlighted_line, false)
	prev_highlighted_line = line
	$Program/Program.set_line_as_executing(line, true)


func _prepare_keyword_highlights():
	for w in ASMInstructions.AMD.keys():
		keyword_colors[0][w] = opcode_color
		keyword_colors[1][w] = opcode_color
	for w in ASMInstructions.RISC.keys():
		keyword_colors[0][w] = opcode_color
		keyword_colors[1][w] = opcode_color
	for reg:Array[String] in ParserData.BASE_VALID_REGISTERS:
		for i in range(reg.size()):
			keyword_colors[0][reg[i]] = reg_colors[i]
			keyword_colors[1][reg[i]] = reg_colors[i]


func _update_run_state():
	$SpeedBox.editable = true
	$Program/Compile.visible = not is_executing
	$Program/Run.visible = is_executing
	$Program/Run.disabled = false
	$Program/Stop.visible = false
	$Program/Step.disabled = not is_executing
	$Program/Reset.disabled = not is_executing
	$Program/Program.editable = not is_executing
	$Program/Program.modulate = Color(1,1,1,0.6) if is_executing else Color.WHITE
	$Program/Timer.stop()
	if is_executing:
		disappear_all_errors()
		self.update_registers()
		self.robot.load_program(assembler.assemble(self.program_text))
		$Program/Program.set_line_as_executing(0, true)
		prev_highlighted_line = 0
	else:
		self.robot.reset()
		$Program/Program.set_line_as_executing(prev_highlighted_line, false)

func update_registers():
	for i in range(self.robot.processor.registers.size()):
		self.reg_displays[i].update_value(self.robot.processor.registers[i])

func _on_compile_pressed() -> void:
	self.is_executing = true

func _on_step_pressed() -> void:
	if not $Program/Timer.is_stopped():
		self.stop_running()
	self.step_program()


func _on_reset_pressed() -> void:
	if not $Program/Timer.is_stopped():
		self.stop_running()
	self.is_executing = false


func _on_program_lines_edited_from(from_line, to_line):
	var lines:Array[String] = []
	for i in range(min(from_line, to_line), max(from_line, to_line)+1):
		lines.append($Program/Program.get_line(i))
	print(lines)
	#request_lines_check.emit(lines, min(from_line, to_line))



func _on_speed_box_value_changed(value) -> void:
	$Program/Timer.wait_time = 1/value


func _on_back_button_pressed():
	GameMaster.back_to_main_menu()


func _on_info_button_pressed():
	$InfoTabs.visible = not $InfoTabs.visible

func _on_info_tabs_tab_clicked(tab):
	if tab == 2:
		$InfoTabs.visible = false
		$InfoTabs.current_tab = 0

func _on_toggle_all_regs_pressed():
	for ch in $RegisterMenu/VBox.get_children():
		if ch is CheckButton:
			ch.button_pressed = not ch.button_pressed


func _on_docs_button_pressed():
	OS.shell_open("https://www.amd.com/content/dam/amd/en/documents/processor-tech-docs/programmer-references/40332.pdf")
