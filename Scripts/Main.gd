extends Control

# The URL we will connect to
@onready var socket_helper: SocketHelper = $SocketHelper
@onready var message_constructor: TVTSAPIMessageConstructor = $TVTSAPIMessageConstructor
@onready var config_helper: ConfigHelper = $ConfigHelper

@onready var api_button: Button = $CanvasLayer/GridContainer/APIPanel/ConnectAPI
@onready var api_port: SpinBox = $CanvasLayer/GridContainer/APIPanel/APIPort
@onready var network_status_label: Label = $CanvasLayer/GridContainer/NetworkStatusLabel

@onready var current_mouse_label: Label = $CanvasLayer/GridContainer/CurrentMouse
@onready var output_estimate_label: Label = $CanvasLayer/GridContainer/OutputEstimate

@onready var range_window: RangeEditWindow = $RangeEditWindow

@onready var ranges_grid_3: GridContainer = $CanvasLayer/GridContainer/RangesGrid
static var mouse_ranges: Array = []

const VTS_MOUSE_RANGE_INDEX: int = 0

const CUSTOM_MOUSE_X_PARAMETER = "MousePositionXRemapped"
const CUSTOM_MOUSE_Y_PARAMETER = "MousePositionYRemapped"

const MOUSE_X_PARAMETER = "MousePositionX"
const MOUSE_Y_PARAMETER = "MousePositionY"

const PARAMETER_NAME_KEY = "name"
const PARAMETER_VALUE_KEY = "value"

const MINX_KEY = "minX"
const MINY_KEY = "minY"
const MAXX_KEY = "maxX"
const MAXY_KEY = "maxY"

var _current_editing_range_index = 0

var _do_process_network = false
var _last_pixel: Vector2 = Vector2(0, 0)
var _last_output: Vector2 = Vector2(0, 0)

var _authentication_token_valid = false

func _ready():
	socket_helper.connect("connected", Callable(self, "_connected"))
	socket_helper.connect("disconnected", Callable(self, "_closed"))
	socket_helper.connect("response_received_json", Callable(self, "_on_response_message"))
	_connect_to_websocket()
	
	if !config_helper.has_mouse_ranges():
		_save_ranges()
	mouse_ranges = config_helper.get_mouse_ranges()
	_refresh_range_list()
	
	get_viewport().gui_embed_subwindows = false

#Runtime loop
func _process(delta):
	_request_mouse_values()
	_update_mouse_estimates()

func _connect_to_websocket():
	network_status_label.text = "Connecting websocket..."
	socket_helper.connect_to_websocket(config_helper.get_ws_url())

func _on_connect_api_pressed():
	if !socket_helper.is_websocket_connected():
		_connect_to_websocket()
		return
	if _authentication_token_valid:
		pass
	else:
		_request_authentication_token()

func _refresh_connect_button():
	if !socket_helper.is_websocket_connected():
		api_button.disabled = false
		api_button.text = "Connect to API"
		return
	if _authentication_token_valid:
		api_button.disabled = true
		api_button.text = "API Ready..."
	else:
		api_button.disabled = false
		api_button.text = "Retry authentication"

func _closed():
	#network_status_label.text = "Not connected to API..."
	_do_process_network = false
	_refresh_connect_button()

func _connected():
	if (config_helper.has_authentication_token()):
		_authenticate()
	else:
		_request_authentication_token()

func _request_authentication_token():
	network_status_label.text = "Requesting authentication token..."
	socket_helper.send_to_websocket_dictionary(message_constructor.get_authentication_token_request())

func _on_authentication_token_data(data: Dictionary):
	var token = data["authenticationToken"]
	config_helper.set_authentication_token(token)
	_authenticate()

func _authenticate():
	network_status_label.text = "Authenticating..."
	var token = config_helper.get_authentication_token()
	socket_helper.send_to_websocket_dictionary(message_constructor.get_authentication_request(token))

func _on_authentication_data(data: Dictionary):
	if data["authenticated"]:
		_authentication_token_valid = true
		_refresh_connect_button()
		_on_authenticated()
	else:
		network_status_label.text = "Could not authenticate: " + data["reason"]
		_authentication_token_valid = false
		_refresh_connect_button()
		#socket_helper.disconnect_from_websocket()

func _on_authenticated():
	network_status_label.text = "Connected!"
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
	_do_process_network = true

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
	var error_message = "Error connecting to API: " + data["message"]
	network_status_label.text = error_message
	print(error_message)

func _request_mouse_values():
	if !_do_process_network:
		return
	if mouse_ranges.is_empty():
		return
	socket_helper.send_to_websocket_dictionary(message_constructor.get_get_parameter_value_request(MOUSE_X_PARAMETER))
	socket_helper.send_to_websocket_dictionary(message_constructor.get_get_parameter_value_request(MOUSE_Y_PARAMETER))

func _on_parameter_value(data: Dictionary):
	match(data[PARAMETER_NAME_KEY]):
		MOUSE_X_PARAMETER:
			_update_custom_mouse_x(data[PARAMETER_VALUE_KEY])
		MOUSE_Y_PARAMETER:
			_update_custom_mouse_y(data[PARAMETER_VALUE_KEY])

func _update_custom_mouse_x(base_value: float):
	_last_pixel.x = _x_to_screen_pixel(base_value)
	_update_custom_mouse()

func _x_to_screen_pixel(base_value: float) -> float:
	var screen_range = _get_screen_range()
	return _to_screen_pixel(base_value, screen_range[MINX_KEY], screen_range[MAXX_KEY])

func _get_screen_range() -> Dictionary:
	return mouse_ranges[0]

func _to_screen_pixel(base_value: float, min: float, max: float) -> float:
	var screen_range_size: float = max - min
	var screen_pixel: float = ((base_value + 1) / 2) * screen_range_size + min
	return screen_pixel

func _update_custom_mouse_y(base_value: float):
	_last_pixel.y = _y_to_screen_pixel(base_value)
	_update_custom_mouse()

func _y_to_screen_pixel(base_value: float) -> float:
	var screen_range = _get_screen_range()
	return _to_screen_pixel(base_value, screen_range[MINY_KEY], screen_range[MAXY_KEY])

func _update_custom_mouse():
	for i in range(1, mouse_ranges.size()):
		if _try_update_custom_mouse(i):
			return

func _try_update_custom_mouse(index: int) -> bool:
	if !_is_in_range(index):
		return false
	
	var mouse_range = mouse_ranges[index]
	_last_output.x = _update_custom_mouse_for_axis(CUSTOM_MOUSE_X_PARAMETER, _last_pixel.x, mouse_range[MINX_KEY], mouse_range[MAXX_KEY])
	_last_output.y = _update_custom_mouse_for_axis(CUSTOM_MOUSE_Y_PARAMETER, _last_pixel.y, mouse_range[MINY_KEY], mouse_range[MAXY_KEY])
	return true

func _is_in_range(index: int) -> bool:
	var range = mouse_ranges[index]
	if  _last_pixel.x < range[MINX_KEY] || range[MAXX_KEY] < _last_pixel.x:
		return false
	if  _last_pixel.y < range[MINY_KEY] || range[MAXY_KEY] < _last_pixel.y:
		return false
	return true

func _update_custom_mouse_for_axis(axis: String, pixel: float, min: float, max: float) -> float:
	var range_size: float = max - min
	var pixel_0_1: float = (pixel - min) / range_size
	var result: float = pixel_0_1 * 2 - 1
	socket_helper.send_to_websocket_dictionary(message_constructor.get_set_parameter_value_request(axis, result))
	return result

#UI interactions
func _on_range_edit_window_range_submitted():
	var range_window_position = range_window.position
	var range_window_end_position = range_window_position + range_window.size
	var range = {
		MINX_KEY: range_window_position.x, 
		MINY_KEY: range_window_position.y, 
		MAXX_KEY: range_window_end_position.x, 
		MAXY_KEY: range_window_end_position.y
	}
	if _current_editing_range_index >= mouse_ranges.size():
		mouse_ranges.append(range)
	else:
		mouse_ranges[_current_editing_range_index] = range
	_save_ranges()
	_refresh_range_list()

func _save_ranges():
	config_helper.set_mouse_ranges(mouse_ranges)

func _on_add_range_pressed():
	_current_editing_range_index = mouse_ranges.size()
	range_window.popup()

func _edit_range_pressed(index: int):
	_current_editing_range_index = index
	range_window.popup()

func _remove_range_pressed(index: int):
	mouse_ranges.remove_at(index)
	_save_ranges()
	_refresh_range_list()

func _refresh_range_list():
	var children = ranges_grid_3.get_children()
	for child in children:
		ranges_grid_3.remove_child(child)
	
	if mouse_ranges.size() == 0:
		var label = Label.new()
		label.text = "Please add the Mouse Input Config range from VTubeStudio"
		ranges_grid_3.add_child(label)
	
	for i in range(mouse_ranges.size()):
		var range_string = _range_to_string(i)
		var label = Label.new()
		label.text = range_string
		ranges_grid_3.add_child(label)
		var edit_button = Button.new()
		edit_button.text = "Edit Range"
		edit_button.connect("pressed", Callable(self, "_edit_range_pressed").bind(i))
		ranges_grid_3.add_child(edit_button)
		if i == 0:
			var screen_label = Label.new()
			screen_label.text = "Screen Range from VTS Mouse Input Config"
			ranges_grid_3.add_child(screen_label)
		else:
			var remove_button = Button.new()
			remove_button.text = "Remove Mapping Range"
			remove_button.connect("pressed", Callable(self, "_remove_range_pressed").bind(i))
			ranges_grid_3.add_child(remove_button)

func _range_to_string(index: int) -> String:
	var range = mouse_ranges[index]
	return "X range: {}, {} | Y range: {}, {}".format([range[MINX_KEY], range[MAXX_KEY], range[MINY_KEY], range[MAXY_KEY]], "{}")

func _on_api_port_value_changed(value):
	var new_url = socket_helper.get_websocket_url(value)
	config_helper.set_ws_url(new_url)
	network_status_label.text = "Port changed, please reconnect when you are ready!"
	socket_helper.disconnect_from_websocket()

func _update_mouse_estimates():
	if !_do_process_network:
		var real_mouse_pos = DisplayServer.mouse_get_position()
		_last_pixel = real_mouse_pos
		_update_custom_mouse()
	current_mouse_label.text = "Current Mouse Position X: {}, Y: {}".format([_last_pixel.x, _last_pixel.y], "{}")
	output_estimate_label.text = "Expected VTS Input X: {}, Y: {}".format([_last_output.x, _last_output.y], "{}")
