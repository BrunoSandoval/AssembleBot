class_name Lexer

signal error_found(message:String, line:int)

# identifiers, operators, grouping symbols and data types.
enum TokenType {
	Identifier,
	# any valid string identifier, includes registers
	Number,
	# a number literal, can't be anything other than a number
	String_,
	# a string literal
	Operator,
	# an operator or sequence of operators (i.e. +, <=, ==, *)
	Separator_,
	# a separator, like a comma
	Delimiter,
	# delimits a special space, for now only parenthesis
	Comment,
	# should not output, used to keep state
	Directive,
	# assembler directives, start with .
	Label_,
	# a label declaration, might be collapsed into identifier
	EndOfLine,
	# the end of an instruction or comment
}

func lex(program:String) -> Array[Lexeme]:
	var lexemes:Array[Lexeme] = []
	
	var tmp_lex:Lexeme = null
	var char_idx:int = 0
	var line:int = 0
	while char_idx < program.length():
		
		# if we don't have a token type, we try identify one
		if tmp_lex == null:
			if is_newline(program[char_idx]):
				lexemes.append(Lexeme.new(line, TokenType.EndOfLine, program[char_idx]))
				line += 1
			elif is_valid_identifier_start(program[char_idx]):
				tmp_lex = Lexeme.new(line, TokenType.Identifier, program[char_idx])
			elif is_valid_number_start(program[char_idx]):
				tmp_lex = Lexeme.new(line, TokenType.Number, program[char_idx])
			elif is_string_delimiter(program[char_idx]):
				tmp_lex = Lexeme.new(line, TokenType.String_)
			elif is_operator(program[char_idx]):
				tmp_lex = Lexeme.new(line, TokenType.Operator, program[char_idx])
			elif is_separator(program[char_idx]):
				tmp_lex = Lexeme.new(line, TokenType.Separator_, program[char_idx])
			elif is_delimiter(program[char_idx]):
				lexemes.append(Lexeme.new(line, TokenType.Delimiter, program[char_idx]))
			elif is_opening_comment(program[char_idx]):
				tmp_lex = Lexeme.new(line, TokenType.Comment)
			elif is_directive_start(program[char_idx]):
				tmp_lex = Lexeme.new(line, TokenType.Directive, program[char_idx])
			else:
				if not is_whitespace(program[char_idx]):
					self.error_found.emit(tr("ERROR_LEX_UNKNOWN_STARTING_CHAR").format({"char":program[char_idx]}), line)
			char_idx += 1
			continue
		
		if is_newline(program[char_idx]):
			if tmp_lex.type != TokenType.Comment:
				lexemes.append(tmp_lex)
			lexemes.append(Lexeme.new(line, TokenType.EndOfLine, program[char_idx]))
			tmp_lex = null
			line += 1
			char_idx += 1
			continue
		
		if tmp_lex.type == TokenType.Comment:
			char_idx += 1
			continue
		
		# if we have identified a token type, act accordingly
		if is_whitespace(program[char_idx]):
			lexemes.append(tmp_lex)
			tmp_lex = null
			char_idx += 1
			continue
		
		if is_opening_comment(program[char_idx]):
			lexemes.append(tmp_lex)
			tmp_lex = Lexeme.new(line, TokenType.Comment)
			char_idx += 1
			continue
		
		if is_separator(program[char_idx]):
			lexemes.append(tmp_lex)
			lexemes.append(Lexeme.new(line, TokenType.Separator_, program[char_idx]))
			tmp_lex = null
			char_idx += 1
			continue
			
		match tmp_lex.type:
			TokenType.Identifier, TokenType.Directive:
				tmp_lex.text += program[char_idx]
				if is_label_end(program[char_idx]):
					tmp_lex.type = TokenType.Label_
					lexemes.append(tmp_lex)
					tmp_lex = null
				if not is_valid_identifier_char(program[char_idx]):
					self.error_found.emit(tr("ERROR_LEX_INVALID_IDENTIFIER_CHAR").format({"char":program[char_idx]}), line)
			TokenType.Number:
				if not is_valid_number_char(program[char_idx]):
					self.error_found.emit(tr("ERROR_LEX_INVALID_NUMBER_CHAR").format({"char":program[char_idx]}), line)
				tmp_lex.text += program[char_idx]
			TokenType.String_:
				if is_string_delimiter(program[char_idx]) \
						and (char_idx > 0 and not is_string_delimiter_escape(program[char_idx-1])):
					lexemes.append(tmp_lex)
					tmp_lex = null
				else:
					tmp_lex.text += program[char_idx]
			TokenType.Operator:
				if not is_operator(program[char_idx]):
					if is_newline(program[char_idx]):
						line -= 1
					lexemes.append(tmp_lex)
					tmp_lex = null
					char_idx -= 1
				tmp_lex.text += program[char_idx]
		char_idx += 1
		continue
	return lexemes

static func is_whitespace(ch:String) -> bool:
	return ch == ' ' or ch == '\t'

static func is_newline(ch:String) -> bool:
	return ch == '\n'

static func is_valid_identifier_start(ch:String) -> bool:
	return ('a' <= ch and ch <= 'z') \
			or ('A' <= ch and ch <= 'Z') \
			or (ch == '_' or ch == '%')

static func is_valid_identifier_char(ch:String) -> bool:
	return not (is_operator(ch) or is_delimiter(ch) or is_directive_start(ch))

static func is_valid_number_start(ch:String) -> bool:
	return ('0' <= ch and ch <= '9') or ch == '$' or ch == '-'

static func is_valid_number_char(ch:String) -> bool:
	return ('0' <= ch and ch <= '9') or ch == '.' or ch == '_' or ch == 'x' or ch == 'X' \
			or ('a' <= ch and ch <= 'f') or ('A' <= ch and ch <= 'F')

static func is_string_delimiter(ch:String) -> bool:
	return (ch == '"' or ch == "'")

static func is_string_delimiter_escape(ch:String) -> bool:
	return ch == '\\'

static func is_operator(ch:String) -> bool:
	return ch == '+' or ch == '-' or ch == '*' or ch == '/' or ch == '='

static func is_separator(ch:String) -> bool:
	return ch == ','

static func is_delimiter(ch:String) -> bool:
	return ch == '[' or ch == '{' or ch == '('\
			or ch == ']' or ch == '}' or ch == ')'

static func is_opening_comment(ch:String) -> bool:
	return ch == '#'

static func is_directive_start(ch:String) -> bool:
	return ch == '.'

static func is_label_end(ch:String) -> bool:
	return ch == ":"



class Lexeme:
	var type: TokenType
	var text: String
	var line: int
	
	func _init(token_line:int, token_type: TokenType, token_text: String = ""):
		self.line = token_line
		self.type = token_type
		self.text = token_text
	
	func is_empty():
		return self.text.is_empty()
	
	func _to_string():
		return "%s at line %d"% [to_lineless_string(), self.line]
	
	func to_lineless_string():
		if self.text.is_empty():
			return TokenType.keys()[self.type]
		return "%s: \"%s\""% [TokenType.keys()[self.type], self.text]
