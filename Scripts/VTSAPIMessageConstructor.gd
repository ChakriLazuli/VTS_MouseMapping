class_name TVTSAPIMessageConstructor
extends Node

const MESSAGE_TYPE_KEY = "messageType"
const REQUEST_ID_KEY = "requestID"
const BASE_REQUEST: Dictionary = {
	"apiName": "VTubeStudioPublicAPI",
	"apiVersion": "1.0",
	"data": {
	}
}
const DATA_KEY = "data"

const BASE_AUTHENTICATION_DATA: Dictionary = {
	"pluginName": "VTS_MouseMapping",
	"pluginDeveloper": "ChakriLazuli",
}
const AUTHENTICATION_TOKEN_KEY = "authenticationToken"
#Encode to base64 and add to authentication_token_request["data"]
export var icon_png_128: Image
const PLUGIN_ICON_KEY = "pluginIcon"

const NEW_PARAMETER_NAME_KEY = "parameterName"
const NEW_PARAMETER_EXPLANATION_KEY = "explanation"
const NEW_PARAMETER_MIN_KEY = "min"
const NEW_PARAMETER_MAX_KEY = "max"
const NEW_PARAMETER_DEFAULT_KEY = "defaultValue"

const GET_PARAMETER_VALUE_NAME_KEY = "name"

func _ready():
	pass 

func _get_base_request() -> Dictionary:
	return BASE_REQUEST.duplicate(true)

func get_authentication_token_request() -> Dictionary:
	var request = _get_base_request()
	request[MESSAGE_TYPE_KEY] = "AuthenticationTokenRequest"
	var data = BASE_AUTHENTICATION_DATA.duplicate(true)
	request[DATA_KEY] = data
	return request

func get_authentication_request(token) -> Dictionary:
	var request = _get_base_request()
	request[MESSAGE_TYPE_KEY] = "AuthenticationRequest"
	var data = BASE_AUTHENTICATION_DATA.duplicate(true)
	data[AUTHENTICATION_TOKEN_KEY] = token
	request[DATA_KEY] = data
	return request

func get_create_parameter_request(name: String, explanation: String, minimum: int, maximum: int, default: int) -> Dictionary:
	var request = _get_base_request()
	request[MESSAGE_TYPE_KEY] = "ParameterCreationRequest"
	var data: Dictionary
	data[NEW_PARAMETER_NAME_KEY] = name
	data[NEW_PARAMETER_EXPLANATION_KEY] = explanation
	data[NEW_PARAMETER_MIN_KEY] = minimum
	data[NEW_PARAMETER_MAX_KEY] = maximum
	data[NEW_PARAMETER_DEFAULT_KEY] = default
	request[DATA_KEY] = data
	return request

func get_get_parameter_value_request(name: String) -> Dictionary:
	var request = _get_base_request()
	request[MESSAGE_TYPE_KEY] = "ParameterValueRequest"
	var data: Dictionary
	data[GET_PARAMETER_VALUE_NAME_KEY] = name
	request[DATA_KEY] = data
	return request


func get_set_parameter_value_request(name: String, value: float) -> Dictionary:
	var request = _get_base_request()
	request[MESSAGE_TYPE_KEY] = "InjectParameterDataRequest"
	var data: Dictionary
	data["mode"] = "set"
	var parameter_value: Dictionary = {
		"id": name,
		"value": value
	}
	var parameter_values: Array = [parameter_value]
	data["parameterValues"] = parameter_values
	request[DATA_KEY] = data
	return request
