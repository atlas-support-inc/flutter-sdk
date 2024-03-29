import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '_config.dart';

Function connectCustomer(
    {required String atlasId, required Function onMessage}) {
  bool killed = false;
  WebSocketChannel? channel;
  int reconnectDelay = 1000;

  void kill() {
    killed = true;
    channel?.sink.close();
  }

  void connect() {
    if (killed) return;
    channel = WebSocketChannel.connect(
        Uri.parse("$atlasWebSocketBaseUrl/ws/CUSTOMER::$atlasId"));

    var ch = channel;
    if (ch == null) return;

    ch.stream.listen((message) {
      reconnectDelay = 1000;
      if (killed) return kill();
      onMessage(message);
    }, onDone: () {
      if (killed) return;
      channel = null;
      Future.delayed(Duration(milliseconds: reconnectDelay), connect);
      if (reconnectDelay < 120e3) reconnectDelay *= 2;
    });

    ch.sink.add(jsonEncode({
      'channel_id': atlasId,
      'channel_kind': 'CUSTOMER',
      'packet_type': 'SUBSCRIBE',
      'payload': {},
    }));
  }

  connect();

  return kill;
}
