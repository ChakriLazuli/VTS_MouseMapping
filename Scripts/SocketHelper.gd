class_name SocketHelper
extends Node

signal connected()
signal disconnected()
signal response_received(data)
signal response_received_json(json_data)

# Our WebSocketClient instance
var _client = WebSocketClient.new()

func _ready():
	set_process(false)

func _closed(was_clean = false):
	# was_clean will tell you if the disconnection was correctly notified
	# by the remote peer before closing the socket.
	print("Closed, clean: ", was_clean)
	set_process(false)
	_client.disconnect("connection_closed")
	_client.disconnect("connection_error")
	_client.disconnect("connection_established")
	_client.disconnect("data_received")
	emit_signal("disconnected")

func _connected(proto = ""):
	# This is called on connection, "proto" will be the selected WebSocket
	# sub-protocol (which is optional)
	print("Connected with protocol: ", proto)
	emit_signal("connected")

func _on_data():
	# Print the received packet, you MUST always use get_peer(1).get_packet
	# to receive data from server, and not get_packet directly when not
	# using the MultiplayerAPI.
	var data = _client.get_peer(1).get_packet().get_string_from_utf8()
	emit_signal("response_received", data)
	var json_parse = JSON.parse(data)
	var json_data = json_parse.result
	emit_signal("response_received_json", json_data)

func _process(delta):
	# Call this in _process or _physics_process. Data transfer, and signals
	# emission will only happen when calling this function.
	_client.poll()

func connect_to_websocket(url: String) -> bool:
	print("Connecting to websocket: ", url)
	
	# Connect base signals to get notified of connection open, close, and errors.
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_connected")
	# This signal is emitted when not using the Multiplayer API every time
	# a full packet is received.
	# Alternatively, you could check get_peer(1).get_available_packets() in a loop.
	_client.connect("data_received", self, "_on_data")
	
	# Initiate connection to the given URL.
	var err = _client.connect_to_url(url)
	var result = err == OK
	set_process(result)
	return result

func send_to_websocket(data: String):
	# You MUST always use get_peer(1).put_packet to send data to server,
	# and not put_packet directly when not using the MultiplayerAPI.
	_client.get_peer(1).put_packet(data.to_utf8())

func send_to_websocket_json(data):
	_client.get_peer(1).put_packet(data.to_utf8())

func send_to_websocket_dictionary(data: Dictionary):
	var json = to_json(data)
	send_to_websocket_json(json)
