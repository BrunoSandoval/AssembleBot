class_name AMDProcessor extends Processor

func _init():
	CALLABLES = {
		"ADD": func(proc:AMDProcessor, args:Array[Parser.ParsedStatement.Argument]):
			if args[1].flags & ASMInstructions.ArgType.imm:
				proc.registers[args[0].data] += args[1].data
			if args[1].flags & ASMInstructions.ArgType.reg:
				proc.registers[args[0].data] += proc.registers[args[1].data]
			,
		"DIV": func(proc:AMDProcessor, args:Array[Parser.ParsedStatement.Argument]):
			pass,
		"JEZ": func(proc:AMDProcessor, args:Array[Parser.ParsedStatement.Argument]):
			if not proc.registers[16] & ParserData.ZF:
				return
			if args[0].flags & ASMInstructions.ArgType.imm:
				proc.registers[17] = args[0].data-1
			if args[0].flags & ASMInstructions.ArgType.reg:
				proc.registers[17] = proc.registers[args[0].data]-1
			,
		"JMP": func(proc:AMDProcessor, args:Array[Parser.ParsedStatement.Argument]):
			if args[0].flags & ASMInstructions.ArgType.imm:
				proc.registers[17] = args[0].data-1
			if args[0].flags & ASMInstructions.ArgType.reg:
				proc.registers[17] = proc.registers[args[0].data]-1
			,
		"MOV": func(proc:AMDProcessor, args:Array[Parser.ParsedStatement.Argument]):
			if args[1].flags & ASMInstructions.ArgType.imm:
				proc.registers[args[0].data] = args[1].data
			if args[1].flags & ASMInstructions.ArgType.reg:
				proc.registers[args[0].data] = proc.registers[args[1].data]
			,
		"MUL": func(proc:AMDProcessor, args:Array[Parser.ParsedStatement.Argument]):
			pass,
		"SUB": func(proc:AMDProcessor, args:Array[Parser.ParsedStatement.Argument]):
			if args[1].flags & ASMInstructions.ArgType.imm:
				proc.registers[args[0].data] -= args[1].data
			if args[1].flags & ASMInstructions.ArgType.reg:
				proc.registers[args[0].data] -= proc.registers[args[1].data]
			if proc.registers[args[0].data] == 0:
				proc.registers[16] |= ParserData.ZF
			else:
				proc.registers[16] -= proc.registers[16] & ParserData.ZF
			,
	}
	super()
