
extends CanvasLayer

export var accountCache: String

var _email: String = ""
var _password: String = ""
var _create: bool = false

onready var field_email: LineEdit = get_node("ui/Field_Email")
onready var field_password: LineEdit = get_node("ui/Field_Password")
onready var field_passwordrepeat: LineEdit = get_node("ui/Field_PasswordRepeat")
onready var label_error: Label = get_node("ui/Label_Error")
onready var button_play: Button = get_node("ui/Button_Play")
onready var button_cancel: Button = get_node("ui/Button_Cancel")
onready var container_user := get_node("ui/User")

onready var preload_lobbyUser = preload("res://scenes/Lobby/LobbyUser/lobbyUser.tscn")

func _ready():
	_loadAccountCache()
	field_email.text = _email
	field_password.text = _password
	MyNakama.connect("authenticated", self, "_on_authenticated")
	MyNakama.connect("accountInfo", self, "_on_accountInfo")


func _on_Field_Email_text_changed(new_text: String):
	_email = new_text


func _on_Field_Password_text_changed(new_text: String):
	_password = new_text

func _on_Field_PasswordRepeat_text_changed(new_text):
	if new_text != field_password.text:
		field_passwordrepeat.modulate = Color.red
	else:
		field_passwordrepeat.modulate = Color.green

func _on_Button_Play_pressed():
	field_email.editable = false
	field_password.editable = false
	if (_create && field_passwordrepeat.modulate == Color.green) || not _create:
		MyNakama.Authenticate(_email, _password, _create)

func _on_Button_Cancel_pressed():
	button_cancel.visible = false
	button_cancel.disabled = true
	button_play.text = "Play"
	field_passwordrepeat.editable = false
	field_passwordrepeat.visible = false
	_create = false

func _on_authenticated(error):
	label_error.text = error.Message
	if error.Code == 0:
		_saveAccountCache()
		MyNakama.GetAccount()
		get_tree().change_scene("res://scenes/Lobby/lobby.tscn")
	elif error.Code == 404:
		_create = true
		field_passwordrepeat.editable = true
		field_passwordrepeat.visible = true
		button_play.text = "New Account"
		button_cancel.visible = true
		button_cancel.disabled = false
	field_email.editable = true
	field_password.editable = true
	
func _on_accountInfo():
	var lobbyUser = preload_lobbyUser.instance()
	container_user.add_child(lobbyUser)
	lobbyUser.LoadAvatar(MyNakama.myAccount.user.avatar_url)
	lobbyUser.SetName(MyNakama.myAccount.user.username)

func _loadAccountCache():
	var file := File.new()
	if file.file_exists(accountCache):
		file.open(accountCache, File.READ)
		var loadedAccount = JSON.parse(file.get_line()).result
		_email = loadedAccount.email
		_password = loadedAccount.password
		file.close()

func _saveAccountCache():
	var file := File.new()
	file.open(accountCache, File.WRITE)
	file.seek(0)
	file.store_string(JSON.print({
		email = _email,
		password = _password
	}))
