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

#requstID can be unique to map request to response, if needed
var authentication_token_request: Dictionary = {
	"apiName": "VTubeStudioPublicAPI",
	"apiVersion": "1.0",
	"requestID": "authentication_request",
	"messageType": "AuthenticationTokenRequest",
	"data": {
		"pluginName": "VTS_MouseMapping",
		"pluginDeveloper": "ChakriLazuli",
	}
}

func _ready():
	pass 

func _get_base_request() -> Dictionary:
	return BASE_REQUEST.duplicate(true)

func get_authentication_token_request() -> Dictionary:
	var request = _get_base_request()
	request[MESSAGE_TYPE_KEY] = "AuthenticationTokenRequest"
	request[DATA_KEY] = BASE_AUTHENTICATION_DATA.duplicate(true)
	return request

func get_authentication_request(token) -> Dictionary:
	var request = _get_base_request()
	request[MESSAGE_TYPE_KEY] = "AuthenticationRequest"
	request[DATA_KEY] = BASE_AUTHENTICATION_DATA.duplicate(true)
	request[DATA_KEY][AUTHENTICATION_TOKEN_KEY] = token
	return request
