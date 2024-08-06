class_name SemanticAnalizer

signal error_found(message:String, line:int)

var swap_operands:bool

func _init(atnt_syntax:bool = true):
	self.swap_operands = atnt_syntax

# some macros might be processed here
# for now, we just use it to check further
func analyze(program:Array[Parser.ParsedStatement]) -> void:
	for inst in program:
		if self.swap_operands and inst.arguments.size() > 1:
			var tmp:Parser.ParsedStatement.Argument = inst.arguments[0]
			inst.arguments[0] = inst.arguments[1]
			inst.arguments[1] = tmp
		if not inst.instruction.to_upper() in ASMInstructions.AMD.keys():
			error_found.emit("%s is not a valid instruction" % inst.instruction, inst.line)
			self.execute_ready = false
			continue
		for arg_list in ASMInstructions.AMD[inst.instruction.to_upper()]:
			if arg_list.size() == inst.arguments.size():
				var matching = true
				for iarg in range(len(arg_list)):
					if (arg_list[iarg] & inst.arguments[iarg].flags) != inst.arguments[iarg].flags:
						matching = false
				if matching:
					print("match!")
