using Godot;
using System.Threading.Tasks;

public class Main : Node
{
    private const string VTS_WEBSOCKET = "ws://localhost:8001";
    private Node _socketHelper;
    // Declare member variables here. Examples:
    // private int a = 2;
    // private string b = "text";

    // Called when the node enters the scene tree for the first time.
    public override void _Ready()
    {
        //GDScript SocketHelperScript = GD.Load<GDScript>("res://Scripts/SocketHelper.gd");
        Node _socketHelper = GetNode("SocketHelper");
        _socketHelper.Connect("connected", this, "OnConnected");
        _socketHelper.Connect("disconnected", this, "OnDisconnected");
        _socketHelper.Connect("response_received", this, "OnResponseReceived");
        _socketHelper.Call("connect_to_websocket", VTS_WEBSOCKET);
    }

    private void OnConnected()
    {
        string testMessage = "{\"apiName\":\"VTubeStudioPublicAPI\",\"apiVersion\":\"1.0\",\"requestID\":\"MyIDWithLessThan64Characters\",\"messageType\":\"APIStateRequest\"}";

        Node _socketHelper = GetNode("SocketHelper");
        _socketHelper.Call("send_to_websocket", testMessage);
    }

    private void OnDisconnected()
    {

    }

    private void OnResponseReceived(string data)
    {
        GD.Print(data);
    }

    private async Task ConnectToAPI()
    {
        await Task.Delay(2000);
	}
}
