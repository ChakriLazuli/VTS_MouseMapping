extends Node

# The URL we will connect to
onready var socket_helper: SocketHelper = $SocketHelper
onready var message_constructor: TVTSAPIMessageConstructor = $TVTSAPIMessageConstructor
onready var config_helper: ConfigHelper = $ConfigHelper

func _ready():
	set_process(false)
	socket_helper.connect("connected", self, "_connected")
	socket_helper.connect("disconnected", self, "_closed")
	socket_helper.connect("response_received_json", self, "_on_response_message")
	socket_helper.connect_to_websocket(config_helper.get_ws_url())

func _closed():
	set_process(false)

func _connected():
	if (config_helper.has_authentication_token()):
		_authenticate()
	else:
		_request_authentication_token()

func _request_authentication_token():
	socket_helper.send_to_websocket_dictionary(message_constructor.get_authentication_token_request())

func _authenticate():
	var token = config_helper.get_authentication_token()
	socket_helper.send_to_websocket_dictionary(message_constructor.get_authentication_request(token))

func _on_authenticated():
	set_process(true)

func _process(delta):
	pass #request updates from API

func _on_response_message(message: Dictionary):
	print("Got data from server: ", message["data"])
	_on_response_data(message["messageType"], message["data"])

func _on_response_data(message_type: String, data: Dictionary):
	match(message_type):
		"APIError":
			_on_api_error(data)
		"AuthenticationTokenResponse":
			_on_authentication_token_data(data)
		"AuthenticationResponse":
			_on_authentication_data(data)

func _on_api_error(data: Dictionary):
	print("Error connecting to API: ", data["message"])

func _on_authentication_token_data(data: Dictionary):
	var token = data["authenticationToken"]
	config_helper.set_authentication_token(token)
	_authenticate()

func _on_authentication_data(data: Dictionary):
	if data["authenticated"]:
		_on_authenticated()
	else:
		print("Could not authenticate: ", data["reason"])
