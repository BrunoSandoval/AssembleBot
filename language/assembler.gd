class_name Assembler

signal error_found(message:String, line:int)

var has_errors:bool = false

func assemble(program_text:String) -> Array[Parser.ParsedStatement]:
	var lexer:Lexer = Lexer.new()
	lexer.error_found.connect(self.subprocess_error)
	var lexemes:Array[Lexer.Lexeme] = lexer.lex(program_text)
	print(lexemes)
	if has_errors:
		self.error_found.emit(tr("ERROR_ASS_LEXER_FAILED"), -1)
		return []
	var parser:Parser = Parser.new()
	parser.error_found.connect(self.subprocess_error)
	var statements:Array[Parser.ParsedStatement] = parser.parse(lexemes)
	print(statements)
	if has_errors:
		self.error_found.emit(tr("ERROR_ASS_PARSER_FAILED"), -1)
		return []
	var seman:SemanticAnalizer = SemanticAnalizer.new()
	seman.error_found.connect(self.subprocess_error)
	seman.analyze(statements)
	print(statements)
	if has_errors:
		self.error_found.emit(tr("ERROR_ASS_PARSER_FAILED"), -1)
		return []
	return statements

func subprocess_error(message:String, line:int):
	has_errors = true
	self.error_found.emit(message, line)
