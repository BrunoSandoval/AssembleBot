extends Node3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var registers = {
	"reg0":0,
	"reg1":0,
	"reg2":0,
	"reg3":0,
	"reg4":0,
	"reg5":0,
	"rob":0,
	"eye":0
	}

var program = []
var programCounter = 0

var instructions = [
	"mov", # from:int/reg to:reg
	"jmp", # to:int/reg
	"jez", # in:int/reg to:int/reg
	"jnz", # in:int/reg to:int/reg
	"jeq", # inA:int/reg inB:int/reg to:int/reg
	"jne", # inA:int/reg inB:int/reg to:int/reg
	"jgt", # inA:int/reg inB:int/reg to:int/reg
	"jlt", # inA:int/reg inB:int/reg to:int/reg
	"add", # inA:int/reg inB:int/reg out:reg
	"sub", # inA:int/reg inB:int/reg out:reg
	"mul", # inA:int/reg inB:int/reg out:reg
	"div", # inA:int/reg inB:int/reg out:reg
	"mod", # inA:int/reg inB:int/reg out:reg
	"shr", # in:int/reg out:reg
	"shl", # in:int/reg out:reg
	"and", # inA:int/reg inB:int/reg out:reg
	"or",  # inA:int/reg inB:int/reg out:reg
	"xor", # inA:int/reg inB:int/reg out:reg
	"not"  # in:int/reg out:reg
	]

var running = false
var executing = false
var errored = false

const maxInstructionTimeout = 0.1
var instructionTimeout = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	await $GameMap.loadFromJSON(GameMaster.mapData)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if running:
		if instructionTimeout > 0:
			instructionTimeout -= delta
		else:
			if not $Robot.executing:
				programStep()
				instructionTimeout = maxInstructionTimeout
	$Camera3D.updatePos($Robot.position, $Robot.rotation_degrees)

func programStep():
	if program.size() == 0:
		resetRobot()
	$GUI/Program.set_caret_line(programCounter)
	if program[programCounter][0] in instructions:
		Callable(self, "_"+program[programCounter][0]).call(program[programCounter])
		#funcref(self, "_"+program[programCounter][0]).call_func(program[programCounter])
		if registers["rob"] != 0:
			$Robot.do(registers["rob"])
			registers["rob"] = 0
	else:
		raiseError("ERROR: "+program[programCounter][0]+" is not a valid instruction.")
		return
	programCounter += 1
	if programCounter >= program.size():
		programCounter = 0
	registers["eye"] = $Robot.lookingAt()
	$GUI.refreshRegisters(registers)

func prepareProgram():
	program.clear()
	programCounter = 0
	for line in $GUI/Program.text.split("\n", false):
		var tmp = []
		for ins in line.split(" ", false):
			tmp.append(String(ins).to_lower())
		program.append(tmp)

func raiseError(msg):
	running = false
	errored = true
	$GUI.displayError(msg)





func _mov(args:Array):
	if args.size() < 3:
		self.raiseError("ERROR: Not enough arguments for mov")
		return
	if args[2] in registers.keys():
		if args[1] in registers.keys():
			registers[args[2]] = clamp8bit(registers[args[1]])
		else:
			registers[args[2]] = clamp8bit(int(args[1]))
	else:
		self.raiseError("ERROR: "+args[2]+" is not a valid register.")


func _jmp(args:Array):
	if args.size() < 2:
		self.raiseError("ERROR: Not enough arguments for jmp")
		return
	programCounter = clamp8bit(registers[args[1]]-1)-1 if args[1] in registers.keys() else clamp8bit(int(args[1])-1)-1

func _jez(args:Array):
	if args.size() < 3:
		self.raiseError("ERROR: Not enough arguments for jez")
		return
	var tmp = registers[args[1]] if args[1] in registers.keys() else clamp8bit(int(args[1]))
	if tmp == 0:
		programCounter = clamp8bit(registers[args[2]]-1)-1 if args[2] in registers.keys() else clamp8bit(int(args[2])-1)-1

func _jnz(args:Array):
	if args.size() < 3:
		self.raiseError("ERROR: Not enough arguments for jnz")
		return
	var tmp = registers[args[1]] if args[1] in registers.keys() else clamp8bit(int(args[1]))
	if tmp != 0:
		programCounter = clamp8bit(registers[args[2]]-1)-1 if args[2] in registers.keys() else clamp8bit(int(args[2])-1)-1

func _jeq(args:Array):
	if args.size() < 4:
		self.raiseError("ERROR: Not enough arguments for jeq")
		return
	var tmp1 = registers[args[1]] if args[1] in registers.keys() else clamp8bit(int(args[1]))
	var tmp2 = registers[args[2]] if args[2] in registers.keys() else clamp8bit(int(args[2]))
	if tmp1 == tmp2:
		programCounter = clamp8bit(registers[args[3]]-1)-1 if args[3] in registers.keys() else clamp8bit(int(args[3])-1)-1

func _jne(args:Array):
	if args.size() < 4:
		self.raiseError("ERROR: Not enough arguments for jne")
		return
	var tmp1 = registers[args[1]] if args[1] in registers.keys() else clamp8bit(int(args[1]))
	var tmp2 = registers[args[2]] if args[2] in registers.keys() else clamp8bit(int(args[2]))
	if tmp1 != tmp2:
		programCounter = clamp8bit(registers[args[3]]-1)-1 if args[3] in registers.keys() else clamp8bit(int(args[3])-1)-1

func _jgt(args:Array):
	if args.size() < 4:
		self.raiseError("ERROR: Not enough arguments for jgt")
		return
	var tmp1 = registers[args[1]] if args[1] in registers.keys() else clamp8bit(int(args[1]))
	var tmp2 = registers[args[2]] if args[2] in registers.keys() else clamp8bit(int(args[2]))
	if tmp1 > tmp2:
		programCounter = clamp8bit(registers[args[3]]-1)-1 if args[3] in registers.keys() else clamp8bit(int(args[3])-1)-1

func _jlt(args:Array):
	if args.size() < 4:
		self.raiseError("ERROR: Not enough arguments for jlt")
		return
	var tmp1 = registers[args[1]] if args[1] in registers.keys() else clamp8bit(int(args[1]))
	var tmp2 = registers[args[2]] if args[2] in registers.keys() else clamp8bit(int(args[2]))
	if tmp1 < tmp2:
		programCounter = clamp8bit(registers[args[3]]-1)-1 if args[3] in registers.keys() else clamp8bit(int(args[3])-1)-1

func _jge(args:Array):
	if args.size() < 4:
		self.raiseError("ERROR: Not enough arguments for jge")
		return
	var tmp1 = registers[args[1]] if args[1] in registers.keys() else clamp8bit(int(args[1]))
	var tmp2 = registers[args[2]] if args[2] in registers.keys() else clamp8bit(int(args[2]))
	if tmp1 >= tmp2:
		programCounter = clamp8bit(registers[args[3]]-1)-1 if args[3] in registers.keys() else clamp8bit(int(args[3])-1)-1

func _jle(args:Array):
	if args.size() < 4:
		self.raiseError("ERROR: Not enough arguments for jle")
		return
	var tmp1 = registers[args[1]] if args[1] in registers.keys() else clamp8bit(int(args[1]))
	var tmp2 = registers[args[2]] if args[2] in registers.keys() else clamp8bit(int(args[2]))
	if tmp1 <= tmp2:
		programCounter = clamp8bit(registers[args[3]]-1)-1 if args[3] in registers.keys() else clamp8bit(int(args[3])-1)-1


func _add(args:Array):
	if args.size() < 4:
		self.raiseError("ERROR: Not enough arguments for add")
		return
	if args[3] in registers.keys():
		if args[2] in registers.keys():
			if args[1] in registers.keys():
				registers[args[3]] = clamp8bit(registers[args[1]] + registers[args[2]])
			else:
				registers[args[3]] = clamp8bit(int(args[1]) + registers[args[2]])
		else:
			if args[1] in registers.keys():
				registers[args[3]] = clamp8bit(registers[args[1]] + int(args[2]))
			else:
				registers[args[3]] = clamp8bit(int(args[1]) + int(args[2]))
	else:
		self.raiseError("ERROR: "+args[3]+" is not a valid register.")

func _sub(args:Array):
	if args.size() < 4:
		self.raiseError("ERROR: Not enough arguments for sub")
		return
	if args[3] in registers.keys():
		if args[2] in registers.keys():
			if args[1] in registers.keys():
				registers[args[3]] = clamp8bit(registers[args[1]] - registers[args[2]])
			else:
				registers[args[3]] = clamp8bit(int(args[1]) - registers[args[2]])
		else:
			if args[1] in registers.keys():
				registers[args[3]] = clamp8bit(registers[args[1]] - int(args[2]))
			else:
				registers[args[3]] = clamp8bit(int(args[1]) - int(args[2]))
	else:
		self.raiseError("ERROR: "+args[3]+" is not a valid register.")

func _mul(args:Array):
	if args.size() < 4:
		self.raiseError("ERROR: Not enough arguments for mul")
		return
	if args[3] in registers.keys():
		if args[2] in registers.keys():
			if args[1] in registers.keys():
				registers[args[3]] = clamp8bit(registers[args[1]] * registers[args[2]])
			else:
				registers[args[3]] = clamp8bit(int(args[1]) * registers[args[2]])
		else:
			if args[1] in registers.keys():
				registers[args[3]] = clamp8bit(registers[args[1]] * int(args[2]))
			else:
				registers[args[3]] = clamp8bit(int(args[1]) * int(args[2]))
	else:
		self.raiseError("ERROR: "+args[3]+" is not a valid register.")

func _div(args:Array):
	if args.size() < 4:
		self.raiseError("ERROR: Not enough arguments for div")
		return
	if args[3] in registers.keys():
		if args[2] in registers.keys():
			if args[1] in registers.keys():
				registers[args[3]] = clamp8bit(int(floor(registers[args[1]] / registers[args[2]])))
			else:
				registers[args[3]] = clamp8bit(int(floor(int(args[1]) / registers[args[2]])))
		else:
			if args[1] in registers.keys():
				registers[args[3]] = clamp8bit(int(floor(registers[args[1]] / int(args[2]))))
			else:
				registers[args[3]] = clamp8bit(int(floor(int(args[1]) / int(args[2]))))
	else:
		self.raiseError("ERROR: "+args[3]+" is not a valid register.")

func _mod(args:Array):
	if args.size() < 4:
		self.raiseError("ERROR: Not enough arguments for mod")
		return
	if args[3] in registers.keys():
		if args[2] in registers.keys():
			if args[1] in registers.keys():
				registers[args[3]] = clamp8bit(registers[args[1]] % registers[args[2]])
			else:
				registers[args[3]] = clamp8bit(int(args[1]) % registers[args[2]])
		else:
			if args[1] in registers.keys():
				registers[args[3]] = clamp8bit(registers[args[1]]  % int(args[2]))
			else:
				registers[args[3]] = clamp8bit(int(args[1]) % int(args[2]))
	else:
		self.raiseError("ERROR: "+args[3]+" is not a valid register.")


func _shr(args:Array):
	if args.size() < 3:
		self.raiseError("ERROR: Not enough arguments for shr")
		return
	if args[2] in registers.keys():
		if args[1] in registers.keys():
			registers[args[2]] = shr8bit(registers[args[1]])
		else:
			registers[args[2]] = shr8bit(clamp8bit(int(args[1])))
	else:
		self.raiseError("ERROR: "+args[2]+" is not a valid register.")

func _shl(args:Array):
	if args.size() < 3:
		self.raiseError("ERROR: Not enough arguments for shr")
		return
	if args[2] in registers.keys():
		if args[1] in registers.keys():
			registers[args[2]] = shl8bit(registers[args[1]])
		else:
			registers[args[2]] = shl8bit(clamp8bit(int(args[1])))
	else:
		self.raiseError("ERROR: "+args[2]+" is not a valid register.")

func _and(args:Array):
	if args.size() < 4:
		self.raiseError("ERROR: Not enough arguments for and")
		return
	if args[3] in registers.keys():
		if args[2] in registers.keys():
			if args[1] in registers.keys():
				registers[args[3]] = clamp8bit(registers[args[1]] & registers[args[2]])
			else:
				registers[args[3]] = clamp8bit(int(args[1]) & registers[args[2]])
		else:
			if args[1] in registers.keys():
				registers[args[3]] = clamp8bit(int(args[2]) & registers[args[1]])
			else:
				registers[args[3]] = clamp8bit(int(args[1]) & int(args[2]))
	else:
		self.raiseError("ERROR: "+args[3]+" is not a valid register.")

func _or(args:Array):
	if args.size() < 4:
		self.raiseError("ERROR: Not enough arguments for or")
		return
	if args[3] in registers.keys():
		if args[2] in registers.keys():
			if args[1] in registers.keys():
				registers[args[3]] = clamp8bit(registers[args[1]] | registers[args[2]])
			else:
				registers[args[3]] = clamp8bit(int(args[1]) | registers[args[2]])
		else:
			if args[1] in registers.keys():
				registers[args[3]] = clamp8bit(int(args[2]) | registers[args[1]])
			else:
				registers[args[3]] = clamp8bit(int(args[1]) | int(args[2]))
	else:
		self.raiseError("ERROR: "+args[3]+" is not a valid register.")

func _xor(args:Array):
	if args.size() < 4:
		self.raiseError("ERROR: Not enough arguments for xor")
		return
	if args[3] in registers.keys():
		if args[2] in registers.keys():
			if args[1] in registers.keys():
				registers[args[3]] = clamp8bit(registers[args[1]] ^ registers[args[2]])
			else:
				registers[args[3]] = clamp8bit(int(args[1]) ^ registers[args[2]])
		else:
			if args[1] in registers.keys():
				registers[args[3]] = clamp8bit(int(args[2]) ^ registers[args[1]])
			else:
				registers[args[3]] = clamp8bit(int(args[1]) ^ int(args[2]))
	else:
		self.raiseError("ERROR: "+args[3]+" is not a valid register.")

func _not(args:Array):
	if args.size() < 3:
		self.raiseError("ERROR: Not enough arguments for not")
		return
	if args[2] in registers.keys():
		if args[1] in registers.keys():
			registers[args[2]] = clamp8bit(registers[args[1]]^255)
		else:
			registers[args[2]] = clamp8bit((clamp8bit(int(args[1])))^255)
	else:
		self.raiseError("ERROR: "+args[2]+" is not a valid register.")





func clamp8bit(number):
	return number & 255

func shr8bit(number):
	return int(floor(number/2)+(128*(number & 1)))
func shl8bit(number):
	return int((number*2)+((number & 128)/128)-(2*(number & 128)))


func startupRobot():
	_on_Robot_robotFinished()
	prepareProgram()
	executing = true
	$GUI/Program.modulate.a8 = 128
	$GUI/Program.editable = false
	$GUI/Program.set_caret_column(0)
	$GUI/Program.set_caret_line(0)

func resetRobot():
	registers = {
	"reg0":0,
	"reg1":0,
	"reg2":0,
	"reg3":0,
	"reg4":0,
	"reg5":0,
	"rob":0,
	"eye":0
	}
	program = []
	programCounter = 0
	running = false
	executing = false
	errored = false
	instructionTimeout = 0
	$Robot.targetPos.x=0
	$Robot.targetPos.z=0
	$Robot.position.x=0
	$Robot.position.z=0
	$Robot.targetA=0
	$Robot.rotation_degrees.y=0
	$GUI/Program.modulate.a8 = 255
	$GUI/Program.editable = true
	$GUI.refreshRegisters(registers)
	$GUI/Run.text = "Run"
	$GUI/Step.disabled = false

func _on_Run_pressed():
	if !executing:
		startupRobot()
	if !running:
		$GUI/Step.disabled = true
		$GUI/Run.text = "Pause"
		running = true
	else:
		$GUI/Step.disabled = false
		$GUI/Run.text = "Run"
		running = false

func _on_Step_pressed():
	if !executing:
		startupRobot()
	elif !running:
		if not $Robot.executing:
			programStep()

func _on_Reset_pressed():
	resetRobot()

func _on_Robot_robotFinished():
	registers["eye"] = $Robot.lookingAt()
	$GUI.refreshRegisters(registers)
