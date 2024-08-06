class_name Assembler_A

signal error_found(message:String, line:int)

var parser:Parser
var instructions:Dictionary = {}

var execute_ready:bool = false

func _init(program_text:String):
	self.parser = Parser.new()
	self.parser.error_found.connect(self.relay_parser_error)
	self.parser.parse([])

func assemble():
	self.execute_ready = true
	for inst in parser.instructions:
		if not inst.instruction.to_upper() in ASMInstructions.AMD.keys():
			error_found.emit("%s is not a valid instruction" % inst.instruction, inst.line)
			self.execute_ready = false
			continue
		for arg_list in ASMInstructions.AMD[inst.instruction.to_upper()]:
			if arg_list.size() == inst.arguments.size():
				var matching = true
				for iarg in range(len(arg_list)):
					if arg_list[iarg] & inst.arguments[iarg] != inst.arguments[iarg]:
						matching = false
				if matching:
					pass

func relay_parser_error(message:String, line:int):
	error_found.emit(message, line)


class Instruction:

	# an inner class representing an argument
	class Argument:
		# a flag corresponding to ASMInstructions consts
		var flags:int
		# the actual value of the argument
		var value:int
		
		# a simple initializer
		func _init(flags:int, value:int):
			self.flags = flags
			self.value = value
