import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Chatpages extends StatefulWidget {
  const Chatpages({super.key});

  @override
  State<Chatpages> createState() => _ChatpagesState();
}

class _ChatpagesState extends State<Chatpages> {
  final TextEditingController _controller = TextEditingController();
  late WebSocketChannel channel;
  final List<String> messages = [];

  @override
  void initState() {
    super.initState();
    final channel = WebSocketChannel.connect(
      Uri.parse("ws://192.168.1.10:8080"),
    );

    channel.stream.listen((message) {
      setState(() {
        messages.add("$message");
      });
    });
  }

  void _sent_messages() {
    if (_controller.text.isNotEmpty) {
      channel.sink.add(_controller.text);
      setState(() {
        messages.add("siz ${_controller.text}");
      });
      _controller.clear();
    }
  }

  @override
  void dispose() {
    channel.sink.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(title: Text(messages[index]));
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 20, right: 20),
            child: Row(
              children: [
               Expanded(child:  TextField(
                  controller: _controller,
                  decoration: InputDecoration(hintText: "Enter somthing.."),
                ),),
                IconButton(onPressed:_sent_messages, icon: Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
