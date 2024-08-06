class_name ParserData
# source for most of the information here
# https://www.amd.com/content/dam/amd/en/documents/processor-tech-docs/programmer-references/40332.pdf

# general purpose registers:
# +-----+-----+-------+--------+--------+
# | 8lo | 8hi | 16    | 32     | 64     |
# +-----+-----+-------+--------+--------+
# | AL  | AH  | AX    | EAX    | RAX    |
# | BL  | BH  | BX    | EBX    | RBX    |
# | CL  | CH  | CX    | ECX    | RCX    |
# | DL  | DH  | DX    | EDX    | RDX    |
# |     |     | SI    | ESI    | RSI    |
# |     |     | DI    | EDI    | RDI    |
# |     |     | BP    | EBP    | RBP    |
# |     |     | SP    | ESP    | RSP    |
# |     |     |       |        | R8     |
# |     |     |       |        | R9     |
# |     |     |       |        | R10    |
# |     |     |       |        | R11    |
# |     |     |       |        | R12    |
# |     |     |       |        | R13    |
# |     |     |       |        | R14    |
# |     |     |       |        | R15    |
# |     |     | FLAGS | EFLAGS | RFLAGS |
# |     |     | IP    | EIP    | RIP    |
# +-----+-----+-------+--------+--------+
enum RegSizes {
	byte_low, byte_high, word, dword, qword, byte
}
const BASE_VALID_REGISTERS:Array[Array] = [
	["AL", "AH", "AX", "EAX", "RAX"], # 0
	["BL", "BH", "BX", "EBX", "RBX"], # 1
	["CL", "CH", "CX", "ECX", "RCX"], # 2
	["DL", "DH", "DX", "EDX", "RDX"], # 3
	[null, null, "SI", "ESI", "RSI"], # 4
	[null, null, "DI", "EDI", "RDI"], # 5
	[null, null, "BP", "EBP", "RBP"], # 6
	[null, null, "SP", "ESP", "RSP"], # 7
	[null, null, null, null, "R8"],   # 8
	[null, null, null, null, "R9"],   # 9
	[null, null, null, null, "R10"],  #10
	[null, null, null, null, "R11"],  #11
	[null, null, null, null, "R12"],  #12
	[null, null, null, null, "R13"],  #13
	[null, null, null, null, "R14"],  #14
	[null, null, null, null, "R15"],  #15
	[null, null, "FLAGS", "EFLAGS", "RFLAGS"],#16
	[null, null, "IP", "EIP", "RIP"],  #17
	[null, null, null, null, "ROB"],  #18
	[null, null, null, null, "EYE"]  #19
]

const CF:int = 0b0000_0000_0001
const PF:int = 0b0000_0000_0100
const AF:int = 0b0000_0001_0000
const ZF:int = 0b0000_0100_0000
const SF:int = 0b0000_1000_0000
const DF:int = 0b0100_0000_0000
const OF:int = 0b1000_0000_0000

# bits for 8, 16, 32, 64 are reserved for operand sizes
const ARG_OPT:int = 0b0001
const SAME_SIZE:int = 0b0010_0000_0000
enum ArgT {
	reg = 0b0000_0010,
	mem = 0b0000_0100,
	imm = 0b1000_0000,
	off = 0b0001_0000_0000,
	regmem = reg | mem,
	anydat = reg | mem | imm,
}

# the possible types of error
enum CheckResult {
	OK,
	# nothing went wrong, a valid statement is guaranteed
	ERR_GENERIC,
	# something bad, but not sure what, this shouldn't be used
	ERR_INV_INST,
	# invalid instruction, the opcode wasn't recognized
	ERR_ARG_NUM
	# number of arguments is incorrect
}


# the raw error descriptions for users
# should have spaces to add specific details via string formatting (with %s)
const RAW_ERROR_TEXTS:Array[String] = [
	"",
	"An error has occurred: %s",
	"\"%s\" is not a recognized instruction",
	"%s arguments found, %s needs %s arguments",
]

# to make objects that contain error information, such as:
# type of error, the error text itself and the line of the error
class ParseError:
	# the error itself, shouldn't, but can, be OK
	var err:CheckResult
	# the text that describes the error, to be presented to the user
	var text:String
	# the line the error is in, to highlight it
	# if zero, no highlight is applied, and there's a timeout to the message
	# if not zero, highlight and message will persist until error is fixed
	var line:int
	# not yet implemented, but here for futureproofing
	var is_warning:bool
	
	func _init(err:CheckResult, text:String = "", line:int = -1, is_warning:bool = false):
		self.err = err
		self.text = text
		self.line = line
		self.is_warning = is_warning

class LineCheckResult:
	# the result of the check itself
	var res_code:CheckResult
	
	# the data of the error, to be formatted and displayed
	# an empty array if it's not an error
	var err_data:Array[String]
	
	func _init(res_code:CheckResult, err_data:Array[String] = []):
		self.res_code = res_code
		self.err_data = err_data
