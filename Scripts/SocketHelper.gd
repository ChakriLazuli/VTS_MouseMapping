class_name SocketHelper
extends Node

signal connected()
signal disconnected()
signal response_received(data)
signal response_received_json(json_data)

# Our WebSocketClient instance
var _client = WebSocketPeer.new()

var connection_open = false

func _ready():
	set_process(false)

func _closed(was_clean = false):
	var code = _client.get_close_code()
	var reason = _client.get_close_reason()
	print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
	set_process(false)
	connection_open = false
	emit_signal("disconnected")

func _connected():
	# This is called on connection, "proto" will be the selected WebSocket
	# sub-protocol (which is optional)
	print("Connected")
	connection_open = true
	emit_signal("connected")

func _on_data():
	# Print the received packet, you MUST always use get_peer(1).get_packet
	# to receive data from server, and not get_packet directly when not
	# using the MultiplayerAPI.
	var data = _client.get_packet().get_string_from_utf8()
	emit_signal("response_received", data)
	var test_json_conv = JSON.new()
	test_json_conv.parse(data)
	var json_data = test_json_conv.get_data()
	emit_signal("response_received_json", json_data)

func _process(delta):
	# Call this in _process or _physics_process. Data transfer, and signals
	# emission will only happen when calling this function.
	_client.poll()
	var state = _client.get_ready_state()
	match state:
		WebSocketPeer.STATE_OPEN:
			if connection_open:
				while _client.get_available_packet_count():
					_on_data()
			else:
				_connected()
		WebSocketPeer.STATE_CLOSING:
			# Keep polling to achieve proper close.
			pass
		WebSocketPeer.STATE_CLOSED:
			_closed()

func connect_to_websocket(url: String) -> bool:
	print("Connecting to websocket: ", url)
	_client.close()
	# Initiate connection to the given URL.
	var err = _client.connect_to_url(url)
	var result = err == OK
	set_process(result)
	return result

func send_to_websocket(data: String):
	# You MUST always use get_peer(1).put_packet to send data to server,
	# and not put_packet directly when not using the MultiplayerAPI.
	_client.put_packet(data.to_utf8_buffer())

func send_to_websocket_json(data):
	_client.put_packet(data.to_utf8_buffer())

func send_to_websocket_dictionary(data: Dictionary):
	var json = JSON.new().stringify(data)
	send_to_websocket_json(json)
