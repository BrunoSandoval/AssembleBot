extends Node

# signal sent when the map picker opens
signal opened
# signal sent when the map picker closes
signal closed(JSONPath:String)
# for web, sent when there's an error on the levels_manifest.json
signal RequestError(errorText:String)

const defaultURL:String = "https://brunosandoval.github.io/AssembleBot"

var levelList:Array[String] = []
@onready var levelButtonsGroup:ButtonGroup = \
	$MapPicker/MapsPanel/Scroll/VBox/DefaultMapButton.button_group
var levelButtons = []

# a function to tell anyone who asks if we have anything on display
func is_visible():
	return $MapPicker.visible or $URLInput.visible

# a simple function other elements can call to open the level picking ui
func show_picker():
	$MapPicker.visible = true
	if levelButtons.is_empty():
		search_levels()
	emit_signal("opened")


#a function to be called by the back button
func go_back():
	# we hide this ui
	$MapPicker.visible = false
	# we give the path to the json
	emit_signal("closed", get_map_path())
	

# we get back the path from the text in the button
func get_map_path():
	if $MapPicker/MapsPanel/Scroll/VBox/DefaultMapButton.button_pressed:
		return "res://game_map/playground.json"
	if OS.has_feature("editor"):
		return "res://levels/"+levelButtonsGroup.get_pressed_button().text+".json"
	elif OS.get_name() == "Web":
		return (
			$URLInput/DialogPanel/LineEdit.text.trim_suffix("/")
			if $URLInput/DialogPanel/LineEdit.text else
			defaultURL
		)+"/"+levelButtonsGroup.get_pressed_button().text+".json"
	return OS.get_executable_path().get_base_dir()+"/" \
			+levelButtonsGroup.get_pressed_button().text+".json"

#a function to reload the level list, 
#should be called by the reload button and by the open this ui function
func search_levels():
	$MapPicker/MapsPanel/Scroll/VBox/DefaultMapButton.button_pressed = false
	if not levelList:
		update_level_list()
	# we remove all the buttons from existance
	for btn in levelButtons:
		btn.queue_free()
	levelButtons.clear()
	# we duplicate and put the buttons into the container
	for level in levelList:
		levelButtons.append(
			$MapPicker/MapsPanel/Scroll/VBox/DefaultMapButton.duplicate()
		)
		levelButtons[len(levelButtons)-1].text = (level.trim_suffix(".json"))
	# we add the buttons to their container
	for btn in levelButtons:
		$MapPicker/MapsPanel/Scroll/VBox.add_child(btn)
	$MapPicker/MapsPanel/Scroll/VBox/DefaultMapButton.button_pressed = true


# this calls the appropriate OS function
func update_level_list():
	if OS.has_feature("editor"):
		update_level_folder_editor()
	elif OS.get_name() == "Web":
		$MapPicker.visible = false
		$URLInput.visible = true
	else:
		update_level_folder_os()

# update_level_folder for development environments
func update_level_folder_editor():
	# we try to open the levels folder in res://
	update_level_list_local(DirAccess.open("res://levels"))

# update_level_folder for windows, linux, BSDs and others
func update_level_folder_os():
	# we update the level list with the appropriate path
	update_level_list_local(DirAccess.open(OS.get_executable_path().get_base_dir()))

func update_level_list_local(levelsDir:DirAccess):
	levelList.clear()
	# we check the loose level files
	for file in levelsDir.get_files():
		# add the jsons
		if file.ends_with(".json"):
				levelList.append(file)
	for folder in levelsDir.get_directories():
		var folderOpener = DirAccess.open(levelsDir.get_current_dir()+"/"+folder)
		# if a folder fails to open, we ignore it
		if folderOpener == null:
			continue
		# put all the jsons into the level list
		for file in folderOpener.get_files():
			# then make the button
			if file.ends_with(".json"):
				levelList.append(folder+"/"+file)

# we grab the info over the net
func update_level_list_html(url:String = ""):
	levelList.clear()
	# we disable the ok button, and send the request
	$URLInput/OkButton.disabled = true
	$HTTPRequest.request(
		(url.trim_suffix("/") if url else defaultURL) \
		+ "/levels_manifest.json"
	)

func _on_http_request_request_completed(result, response_code, _headers, body):
	# we reenable the button we disabled in update_level_list_html
	$URLInput/OkButton.disabled = false
	# we hide the input field, its job is done for now
	$URLInput.visible = false
	if result:
		# we emit the error signal
		emit_signal("RequestError", 
			"Could not fetch levels_manifest.json: Error %s" % response_code
		) # TODO add better error messages
	# we parse the json that was sent over
	var parser = JSON.new()
	var parseResult = parser.parse(body.get_string_from_utf8())
	# if the json isn't a json or lacks the levels array
	if parseResult \
			or (not parser.data.has("levels")) \
			or (not parser.data["levels"] is Array):
		emit_signal("RequestError", "Could not parse levels_manifest.json")
		return
	print("data:")
	print(parser.data)
	levelList.append_array(parser.data["levels"])
	search_levels()
	$MapPicker.visible = true

# function connected to the ok button on the url input panel
func _on_url_ok_button_pressed():
	# we yoink that url and do the level list updating
	update_level_list_html($URLInput/DialogPanel/LineEdit.text)
	# then hide the element
	$URLInput.visible = false

# function connected to the cancek button on the url input panel
func _on_url_cancel_button_pressed():
	# we just close the element and pretend nothing happened
	$URLInput.visible = false

