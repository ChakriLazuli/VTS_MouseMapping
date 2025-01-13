extends Node

# The URL we will connect to
onready var socket_helper: SocketHelper = $SocketHelper
onready var message_constructor: TVTSAPIMessageConstructor = $TVTSAPIMessageConstructor
onready var config_helper: ConfigHelper = $ConfigHelper

const CUSTOM_MOUSE_X_PARAMETER = "MousePositionXRemapped"
const CUSTOM_MOUSE_Y_PARAMETER = "MousePositionYRemapped"

const MOUSE_X_PARAMETER = "MousePositionX"
const MOUSE_Y_PARAMETER = "MousePositionY"

const PARAMETER_NAME_KEY = "name"
const PARAMETER_VALUE_KEY = "value"

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

func _on_authentication_token_data(data: Dictionary):
	var token = data["authenticationToken"]
	config_helper.set_authentication_token(token)
	_authenticate()

func _authenticate():
	var token = config_helper.get_authentication_token()
	socket_helper.send_to_websocket_dictionary(message_constructor.get_authentication_request(token))

func _on_authentication_data(data: Dictionary):
	if data["authenticated"]:
		_on_authenticated()
	else:
		print("Could not authenticate: ", data["reason"])

func _on_authenticated():
	_create_custom_mouse_x()

func _create_custom_mouse_x():
	_create_custom_mouse(CUSTOM_MOUSE_X_PARAMETER)

func _create_custom_mouse_y():
	_create_custom_mouse(CUSTOM_MOUSE_Y_PARAMETER)

func _create_custom_mouse(name: String):
	var request = message_constructor.get_create_parameter_request(name, "Mouse coordinates mapped from multiple ranges onto [-1,1]", -1, 1, 0)
	socket_helper.send_to_websocket_dictionary(request)

func _on_parameter_created(data: Dictionary):
	if data["parameterName"] == CUSTOM_MOUSE_X_PARAMETER:
		_create_custom_mouse_y()
	if data["parameterName"] == CUSTOM_MOUSE_Y_PARAMETER:
		_on_vts_ready()

func _on_vts_ready():
	set_process(true)

#Response mapping
func _on_response_message(message: Dictionary):
	_on_response_data(message["messageType"], message["data"])

func _on_response_data(message_type: String, data: Dictionary):
	match(message_type):
		"APIError":
			_on_api_error(data)
		"AuthenticationTokenResponse":
			_on_authentication_token_data(data)
		"AuthenticationResponse":
			_on_authentication_data(data)
		"ParameterCreationResponse":
			_on_parameter_created(data)
		"ParameterValueResponse":
			_on_parameter_value(data)

func _on_api_error(data: Dictionary):
	print("Error connecting to API: ", data["message"])

#Runtime loop
func _process(delta):
	_request_mouse_values()

func _request_mouse_values():
	socket_helper.send_to_websocket_dictionary(message_constructor.get_get_parameter_value_request(MOUSE_X_PARAMETER))
	socket_helper.send_to_websocket_dictionary(message_constructor.get_get_parameter_value_request(MOUSE_Y_PARAMETER))

func _on_parameter_value(data: Dictionary):
	match(data[PARAMETER_NAME_KEY]):
		MOUSE_X_PARAMETER:
			_update_custom_mouse_x(data[PARAMETER_VALUE_KEY])
		MOUSE_Y_PARAMETER:
			_update_custom_mouse_y(data[PARAMETER_VALUE_KEY])

func _update_custom_mouse_x(base_value: float):
	socket_helper.send_to_websocket_dictionary(message_constructor.get_set_parameter_value_request(CUSTOM_MOUSE_X_PARAMETER, -0.5))

func _update_custom_mouse_y(base_value: float):
	socket_helper.send_to_websocket_dictionary(message_constructor.get_set_parameter_value_request(CUSTOM_MOUSE_Y_PARAMETER, 0.5))
