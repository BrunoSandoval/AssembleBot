class_name ASMInstructions

const ANY_SIZE = 8 | 16 | 32 | 64
const SAME_SIZE = 0b0000_1_0000_000

enum ArgType {
	imm = 0b0000_0_0000_001,
	reg = 0b0000_0_0000_010,
	mem = 0b0000_0_0000_100,
	regmem = reg | mem,
}

# each instruction entry consists of an array of arrays of argument sets
# []
const AMD = {
	"ADD": [
		[ArgType.regmem | ANY_SIZE | SAME_SIZE, ArgType.imm | ANY_SIZE | SAME_SIZE],
		[ArgType.regmem | ANY_SIZE | SAME_SIZE, ArgType.reg | ANY_SIZE | SAME_SIZE],
		[ArgType.reg | ANY_SIZE | SAME_SIZE,    ArgType.regmem | ANY_SIZE | SAME_SIZE],
	],
	"DIV": [
		[ArgType.regmem | ANY_SIZE],
	],
	"JEZ": [
		[ArgType.imm | ANY_SIZE],
	],
	"JMP": [
		[ArgType.regmem | ANY_SIZE],
		[ArgType.imm | ANY_SIZE],
	],
	"MOV": [
		[ArgType.regmem | ANY_SIZE | SAME_SIZE, ArgType.reg | ANY_SIZE | SAME_SIZE],
		[ArgType.reg | ANY_SIZE | SAME_SIZE,    ArgType.regmem | ANY_SIZE | SAME_SIZE],
		[ArgType.regmem | ANY_SIZE | SAME_SIZE, ArgType.imm | ANY_SIZE | SAME_SIZE],
	],
	"MUL": [
		[ArgType.regmem | ANY_SIZE],
	],
	"SUB": [
		[ArgType.regmem | ANY_SIZE | SAME_SIZE, ArgType.imm | ANY_SIZE | SAME_SIZE],
		[ArgType.regmem | ANY_SIZE | SAME_SIZE, ArgType.reg | ANY_SIZE | SAME_SIZE],
		[ArgType.reg | ANY_SIZE | SAME_SIZE,    ArgType.regmem | ANY_SIZE | SAME_SIZE],
	],
	
}

const RISC = {
	
}

const PENDING_INSTRUCTIONS = [
	
]

static func debug_format_arg(arg_flags:int) -> String:
	var out:String = ""
	var ilen:int = out.length()
	if arg_flags & 8:
		out += "8"
	if arg_flags & 16:
		out += ", 16" if out.length() != ilen else "16"
	if arg_flags & 32:
		out += ", 32" if out.length() != ilen else "32"
	if arg_flags & 64:
		out += ", 64" if out.length() != ilen else "64"
	if out.length() != ilen:
		out += " bit "
	ilen = out.length()
	if arg_flags & ArgType.imm:
		out += "immediate"
	if arg_flags & ArgType.reg:
		out += ", register" if out.length() != ilen else "register"
	if arg_flags & ArgType.mem:
		out += ", memory loc" if out.length() != ilen else "memory loc"
	return out
