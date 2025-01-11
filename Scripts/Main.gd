extends Node

# The URL we will connect to
onready var socket_helper: SocketHelper = $SocketHelper
export var websocket_url = "ws://localhost:8001"

# Our WebSocketClient instance
var _client = WebSocketClient.new()

func _ready():
	socket_helper.connect("connected", self, "_connected")
	socket_helper.connect("disconnected", self, "_closed")
	socket_helper.connect("response_received_json", self, "_on_data")
	socket_helper.connect_to_websocket(websocket_url)

func _closed():
	pass

func _connected():
	var request = {"apiName":"VTubeStudioPublicAPI", 
		"apiVersion":"1.0", 
		"requestID":"MyIDWithLessThan64Characters", 
		"messageType":"APIStateRequest"}
	socket_helper.send_to_websocket_dictionary(request)

func _on_data(json_data):
	print("Got data from server: ", json_data["data"])
	
