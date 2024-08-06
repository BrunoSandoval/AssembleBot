class_name Parser extends ParserData


static func get_register_index(reg:String) -> int:
	for i in range(BASE_VALID_REGISTERS.size()):
		if BASE_VALID_REGISTERS[i].has(reg):
			return i
	return -1

static func get_register_size(reg:String) -> int:
	for reg_type in BASE_VALID_REGISTERS:
		if reg in reg_type:
			return reg_type.find(reg)
	return -1

static func get_register(reg:String) -> Vector2i: # Vector2i( index, size )
	for i in range(BASE_VALID_REGISTERS.size()):
		if reg in BASE_VALID_REGISTERS[i]:
			match BASE_VALID_REGISTERS[i].find(reg):
				ParserData.RegSizes.byte_low, ParserData.RegSizes.byte_high:
					return Vector2i(i, 8)
				ParserData.RegSizes.word:
					return Vector2i(i, 16)
				ParserData.RegSizes.dword:
					return Vector2i(i, 32)
				ParserData.RegSizes.qword:
					return Vector2i(i, 64)
	return Vector2i(-1, -1)

const VALID_STATES:Dictionary = {
	Lexer.TokenType.EndOfLine: [
		Lexer.TokenType.EndOfLine,
		Lexer.TokenType.Label_,
		Lexer.TokenType.Identifier,
	],
	Lexer.TokenType.Identifier: [
		Lexer.TokenType.EndOfLine,
		Lexer.TokenType.Identifier,
		Lexer.TokenType.Number,
		Lexer.TokenType.Separator_,
	],
	Lexer.TokenType.Label_: [
		Lexer.TokenType.EndOfLine,
		Lexer.TokenType.Identifier,
	],
	Lexer.TokenType.Number: [
		Lexer.TokenType.Separator_,
		Lexer.TokenType.EndOfLine,
	],
	Lexer.TokenType.String_: [
		Lexer.TokenType.EndOfLine,
	],
	Lexer.TokenType.Separator_: [
		Lexer.TokenType.Identifier,
		Lexer.TokenType.Number,
	]
}

# TODO implement this fully
const INSTRUCTION_SIZES:Dictionary = {
	"B":RegSizes.byte,
	"W":RegSizes.word,
	"L":RegSizes.dword,
	"Q":RegSizes.qword,
}

signal error_found(message:String, line:int)


func parse(program:Array[Lexer.Lexeme]) -> Array[ParsedStatement]:
	var instructions:Array[ParsedStatement] = []
	var errata:Array[ParsedStatement.Argument] = []
	var jmp_labels:Dictionary = {}# Dictionary{string:int}
	var statement:ParsedStatement
	
	var state:Lexer.TokenType = Lexer.TokenType.EndOfLine
	for lexeme in program:
		if not lexeme.type in VALID_STATES[state]:
			error_found.emit(tr("ERROR_PAR_INVALID_NEXT_TOKEN")
					.format({"token":lexeme.text, "type":lexeme.type})
					, lexeme.line)
		match lexeme.type:
			Lexer.TokenType.Identifier:
				if statement == null:
					var tmp:String = lexeme.text.to_upper()
							#.trim_suffix("B").trim_suffix("W").trim_suffix("D").trim_suffix("Q")
					if tmp in ASMInstructions.AMD.keys():
						statement = ParsedStatement.new(lexeme.line, tmp)
					state = lexeme.type
					continue
				var reg:Vector2i = get_register(lexeme.text.to_upper().trim_prefix("%"))
				if reg.x >= 0:
					var arg:ParsedStatement.Argument = \
							ParsedStatement.Argument.new(reg.x, reg.y | ASMInstructions.ArgType.reg)
					statement.add_arg(arg)
					state = lexeme.type
					continue
				elif lexeme.text.begins_with("%"):
						error_found.emit(tr("ERROR_PAR_INVALID_REGISTER")
								.format({"register":lexeme.text}), lexeme.line)
						state = lexeme.type
						continue
				var err:ParsedStatement.Argument = ParsedStatement.Argument.new(lexeme.text)
				errata.append(err)
				statement.add_arg(err)
				#var reg = Parser.get_register(lexeme.text)
				#if reg.x >= 0 and reg.y >= 0:
					#lexeme.type = Lexer.TokenType.Register
			Lexer.TokenType.Number:
				if statement != null:
					var num:int = 0
					var txt:String = lexeme.text.trim_prefix("$")
					if Parser.is_valid_bin_number(txt, true):
						num = txt.bin_to_int()
					elif txt.is_valid_int():
						num = txt.to_int()
					elif txt.is_valid_hex_number(true):
						num = txt.hex_to_int()
					else:
						self.error_found.emit(tr("ERROR_PAR_INVALID_NUMBER").format({"number":lexeme.text}), lexeme.line)
						state = lexeme.type
						continue
					var arg:ParsedStatement.Argument = ParsedStatement.Argument.new(num, ASMInstructions.ArgType.imm)
					arg.set_number_size()
					statement.add_arg(arg)
			Lexer.TokenType.Label_:
				jmp_labels[lexeme.text.trim_suffix(":")] = instructions.size()
			Lexer.TokenType.EndOfLine:
				if statement != null:
					instructions.append(statement)
				statement = null
				
		state = lexeme.type
	for erratum in errata:
		if not jmp_labels.has(erratum.data):
			self.error_found.emit(tr("ERROR_PAR_LABEL_NOT_FOUND").format({"label":erratum.data}), erratum.statement.line)
		else:
			# a bit cursed, but it works because References
			erratum.data = jmp_labels[erratum.data]
			erratum.set_number_size()
	return instructions


static func is_valid_bin_number(text:String, with_prefix:bool = false) -> bool:
	if with_prefix and not text.begins_with("0b"):
		return false
	for ch:String in text.trim_prefix("0b"):
		if not (ch == '0' or ch == '1'):
			return false
	return true

# a class to represent an already parsed statement
class ParsedStatement:
	# an integer representing the instruction itself
	var instruction:String
	# the arguments of that instruction
	var arguments:Array[Argument]
	# the line that instruction is written on
	# this is stored to make showing errors easier
	var line:int = 0
	# the determined size of the instruction, not always relevant
	var size:int = 0

	# a simple initializer, args being optional
	func _init(line:int, inst:String, args:Array[Argument] = []):
		self.instruction = inst
		self.line = line
		self.arguments = args

	func add_arg(arg:Argument) -> void:
		arg.statement = self
		self.arguments.append(arg)

	func validate() -> bool:
		# TODO complete the statement validation
		if not self.instruction in ASMInstructions.AMD.keys():
			return false
		return true

	func _to_string() -> String:
		return "%d: %s %s" % [self.line, self.instruction, self.arguments]

	# an inner class representing an argument, i want typed arrays
	class Argument:
		
		# corresponds to flags from ASMInstructions
		# this includes both possible types and sizes
		var flags:int
		# the data of the argument
		var data:Variant
		# a reference to the containing statement
		var statement:ParsedStatement
		
		func _init(arg_data: Variant, starting_flags:int = 0):
			self.flags = starting_flags
			self.data = arg_data
		
		# should be called on number immediates and resolved labels
		func set_number_size() -> void:
			if not self.data is int:
				return
				
			self.flags |= ASMInstructions.ArgType.imm
			if self.data <= 0b11111111: #2^8
				self.flags |= 8
			if self.data <= 0b11111111_11111111:#2^16
				self.flags |= 16
			if self.data <= 0b11111111_11111111_11111111_11111111:#2^32
				self.flags |= 32
			self.flags |= 64

		func is_valid() -> bool:
			if self.type & ASMInstructions.ArgType.reg:
					return self.data >= 0 and self.size >= 0
			return false
		
		func _to_string() -> String:
			return "%s (%s)" % [ASMInstructions.debug_format_arg(self.flags), self.data]
			#return "%s %s %s" % [
				#Instruction.Argument.ArgType.keys()[self.type], 
				#self.data, self.size
			#]
