class_name Processor

signal system_interrupt

var CALLABLES:Dictionary
var registers:Array[int]

var program_memory:Array[Parser.ParsedStatement]

var auto_loop:bool

func _init():
	program_memory = []
	auto_loop = false
	self.reset()

func load_program(program:Array[Parser.ParsedStatement]) -> void:
	self.program_memory = program
	self.reset()

func reset() -> void:
	registers = [
		0, 0, 0, 0, 
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0,
		0, 0, 0, 0
	]

func execute() -> bool:
	if not self.registers[17] < program_memory.size():
		return false
	CALLABLES[program_memory[registers[17]].instruction].call(self, program_memory[registers[17]].arguments)
	self.registers[17] += 1
	if auto_loop and self.registers[17] >= program_memory.size():
		self.registers[17] = 0
	return true

func get_instruction_line() -> int:
	if program_memory.size() > 0 and registers[17] < program_memory.size():
		return program_memory[registers[17]].line
	return -1
