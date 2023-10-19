# a class to represent an already parsed statement
class_name ParsedStatement

# an integer representing the instruction itself
var inst:int
# the arguments of that instruction
var args:Array[StatementArgument]

# a simple initializer, args being optional
func _init(inst:int, args:Array[StatementArgument] = []):
	self.inst = inst
	self.args = args

# an inner class representing an argument, i want typed arrays
class StatementArgument:
	# an enum of the possible types of arguments
	enum argType {
		integer,
		register
	}
	
	# an option of the type enum, so whe know what value means
	var type:argType
	# the actual value of the argument
	var value:int
	
	# a simple initializer
	func _init(type:argType, value:int):
		self.type = type
		self.value = value
