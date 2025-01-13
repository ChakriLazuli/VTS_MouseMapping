extends Node

# The URL we will connect to
onready var socket_helper: SocketHelper = $SocketHelper
onready var message_constructor: TVTSAPIMessageConstructor = $TVTSAPIMessageConstructor
onready var config_helper: ConfigHelper = $ConfigHelper

#Placeholder UI
onready var vts_min_x: TextEdit = $CanvasLayer/GridContainer/VTSMinX
onready var vts_min_y: TextEdit = $CanvasLayer/GridContainer/VTSMinY
onready var vts_max_x: TextEdit = $CanvasLayer/GridContainer/VTSMaxX
onready var vts_max_y: TextEdit = $CanvasLayer/GridContainer/VTSMaxY
onready var custom1_min_x: TextEdit = $CanvasLayer/GridContainer/CustomMinX
onready var custom1_min_y: TextEdit = $CanvasLayer/GridContainer/CustomMinY
onready var custom1_max_x: TextEdit = $CanvasLayer/GridContainer/CustomMaxX
onready var custom1_max_y: TextEdit = $CanvasLayer/GridContainer/CustomMaxY
onready var custom2_min_x: TextEdit = $CanvasLayer/GridContainer/CustomMinX2
onready var custom2_min_y: TextEdit = $CanvasLayer/GridContainer/CustomMinY2
onready var custom2_max_x: TextEdit = $CanvasLayer/GridContainer/CustomMaxX2
onready var custom2_max_y: TextEdit = $CanvasLayer/GridContainer/CustomMaxY2

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
	if _try_update_custom_mouse(CUSTOM_MOUSE_X_PARAMETER, base_value, vts_min_x.text.to_float(), vts_max_x.text.to_float(), custom1_min_x.text.to_float(), custom1_max_x.text.to_float()):
		return
	if _try_update_custom_mouse(CUSTOM_MOUSE_X_PARAMETER, base_value, vts_min_x.text.to_float(), vts_max_x.text.to_float(), custom2_min_x.text.to_float(), custom2_max_x.text.to_float()):
		return

func _update_custom_mouse_y(base_value: float):
	if _try_update_custom_mouse(CUSTOM_MOUSE_Y_PARAMETER, base_value, vts_min_y.text.to_float(), vts_max_y.text.to_float(), custom1_min_y.text.to_float(), custom1_max_y.text.to_float()):
		return
	if _try_update_custom_mouse(CUSTOM_MOUSE_Y_PARAMETER, base_value, vts_min_y.text.to_float(), vts_max_y.text.to_float(), custom2_min_y.text.to_float(), custom2_max_y.text.to_float()):
		return

func _try_update_custom_mouse(name: String, base_value: float, vts_min: float, vts_max: float, custom_min: float, custom_max: float) -> bool:
	var vts_range_size: float = vts_max - vts_min
	var mouse_coord: float = ((base_value + 1) / 2) * vts_range_size + vts_min
	var custom_range_size: float = custom_max - custom_min
	var custom_0_1: float = (mouse_coord - custom_min) / custom_range_size
	var result: float = custom_0_1 * 2 - 1
	if result < -1.0 || 1.0 < result:
		return false
	socket_helper.send_to_websocket_dictionary(message_constructor.get_set_parameter_value_request(name, result))
	return true
