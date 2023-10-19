extends Control


const lookObjects = ["none","wall"]
const regColor = Color("#42fdc1")
const kwordColor = Color("#af6792")
const keywordColors = {
	"reg0": regColor,
	"reg1": regColor,
	"reg2": regColor,
	"reg3": regColor,
	"reg4": regColor,
	"reg5": regColor,
	"rob": regColor,
	"eye": regColor,
	"mov": kwordColor,
	"jmp": kwordColor,
	"jez": kwordColor,
	"jnz": kwordColor,
	"jeq": kwordColor,
	"jne": kwordColor,
	"jgt": kwordColor,
	"jlt": kwordColor,
	"add": kwordColor,
	"sub": kwordColor,
	"mul": kwordColor,
	"div": kwordColor,
	"mod": kwordColor,
	"shr": kwordColor,
	"shl": kwordColor,
	"and": kwordColor,
	"or": kwordColor,
	"xor": kwordColor,
	"not": kwordColor
}

# Called when the node enters the scene tree for the first time.
func _ready():
	$Program.syntax_highlighter.set_keyword_colors(keywordColors)

func displayError(msg):
	$ErrorRect/ErrorLabel.text = msg
	$ErrorRect.visible = true

func refreshRegisters(regs):
	$RegisterScroll/Registers/ContainerReg0/Value.text = "%d" %regs["reg0"]
	$RegisterScroll/Registers/ContainerReg0/BinValue.text = binString(regs["reg0"])
	$RegisterScroll/Registers/ContainerReg1/Value.text =  "%d" %regs["reg1"]
	$RegisterScroll/Registers/ContainerReg1/BinValue.text = binString(regs["reg1"])
	$RegisterScroll/Registers/ContainerReg2/Value.text =  "%d" %regs["reg2"]
	$RegisterScroll/Registers/ContainerReg2/BinValue.text = binString(regs["reg2"])
	$RegisterScroll/Registers/ContainerReg3/Value.text =  "%d" %regs["reg3"]
	$RegisterScroll/Registers/ContainerReg3/BinValue.text = binString(regs["reg3"])
	$RegisterScroll/Registers/ContainerReg4/Value.text =  "%d" %regs["reg4"]
	$RegisterScroll/Registers/ContainerReg4/BinValue.text = binString(regs["reg4"])
	$RegisterScroll/Registers/ContainerReg5/Value.text =  "%d" %regs["reg5"]
	$RegisterScroll/Registers/ContainerReg5/BinValue.text = binString(regs["reg5"])
	$RegisterScroll/Registers/ContainerRegBot/Value.text =  "%d" %regs["rob"]
	$RegisterScroll/Registers/ContainerRegBot/BinValue.text = binString(regs["rob"])
	$RegisterScroll/Registers/ContainerRegBotEyes/Value.text =  "%d" %regs["eye"]
	$RegisterScroll/Registers/ContainerRegBotEyes/BinValue.text = lookObjects[regs["eye"]]

func binString(number):
	var bin = ""
	var n = number
	for i in range(8):
		bin = "%d%s" % [n%2, bin]
		n = int(floor(n/2))
	return bin


func _on_CamMenu_toggled(button_pressed):
	$CamMenu/Options.visible = button_pressed


func _on_back_button_pressed():
	GameMaster.back_to_main_menu()
