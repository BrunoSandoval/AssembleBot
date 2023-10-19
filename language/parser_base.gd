# interface containing the functions of a parser
# don't use directly
class_name ParserBase

# the already parsed data
var parsedData:Array[ParsedStatement]
# all the errors encountered during parsing, in order of line appearance
var errors:Array[ParseError]

#the actual parsing function, implement in a subclass
func parse(text:String):
	assert(false, "use a subclass, not ParserBase")


# a constructor, that optionally can auto parse the
func _init(text:String = ""):
	# if we have a string to parse, parse it
	if text:
		self.parse(text)

# inner class to hold the error information
class ParseError:
	# the possible types of error
	enum errorType {
		
	}
	
	# the error descriptions for users
	const errorDescriptions:Array[String] = [
		
	]
	
	# the line the error appears at
	var line:int
	# the type of error
	var type:errorType
	
	# a simple initializer
	func _init(line:int, type:errorType):
		self.line = line
		self.type = type
