class_name ConfigHelper
extends Node

#Should be found under user/Roaming/Godot/VTS_MouseMapping
onready var config = ConfigFile.new()
const config_location = "user://MouseMappingConfig.cfg"
const ws_config_section = "websocket"
const ws_url_config_key = "url"
const ws_authentication_config_key = "authentication_token"

const default_ws_url = "ws://localhost:8001"

func _ready():
	_initialize_config()

func _save_config():
	config.save(config_location)

func _load_config():
	config.load(config_location)

func _initialize_config():
	_load_config()
	if (!config.has_section(ws_config_section)):
		set_ws_url(default_ws_url)
		_save_config()

func get_ws_url() -> String:
	return config.get_value(ws_config_section, ws_url_config_key)

func set_ws_url(url: String):
	config.set_value(ws_config_section, ws_url_config_key, url)
	_save_config()

func has_authentication_token() -> bool:
	return config.has_section_key(ws_config_section, ws_authentication_config_key)

func get_authentication_token() -> String:
	return config.get_value(ws_config_section, ws_authentication_config_key, null)

func set_authentication_token(authentication_token: String):
	config.set_value(ws_config_section, ws_authentication_config_key, authentication_token)
	_save_config()
