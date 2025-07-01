import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Chatpages extends StatefulWidget {
  const Chatpages({super.key});

  @override
  State<Chatpages> createState() => _ChatpagesState();
}

class _ChatpagesState extends State<Chatpages> {
  final TextEditingController _controller = TextEditingController();
  late WebSocketChannel channel;
  final ImagePicker picker = ImagePicker();
  final List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(Uri.parse("ws://192.168.1.10:8080"));

    channel.stream.listen((message) {
      final decoded = jsonDecode(message);
      setState(() {
        messages.add({"type": decoded["type"], "data": decoded["data"]});
      });
    });
  }

  void _sent_messages() {
    if (_controller.text.isNotEmpty) {
      final String text = _controller.text;
      channel.sink.add(jsonEncode({"type": "text", "data": text}));
      setState(() {
        messages.add({"type": "text", "data": text});
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

  void imagepickerchoose() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text("Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.image_rounded),
              title: Text("Galareya"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final PickedFile = await picker.pickImage(source: source, imageQuality: 50);
    if (PickedFile != null) {
      final bytes = await PickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      channel.sink.add(jsonEncode({"type": "image", "data": base64Image}));
      setState(() {
        messages.add({"type": "image", "data": base64Image});
      });
    }
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
                final msg = messages[index];
                if (msg["type"] == "text") {
                  return ListTile(title: Text(msg["data"]));
                } else if (msg["type"] == "image") {
                  return Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Image.memory(base64Decode(msg["data"])),
                  );
                } else {
                  return SizedBox.shrink();
                }
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 20, right: 20),
            child: Row(
              children: [
                IconButton(onPressed:imagepickerchoose, icon: Icon(Icons.add)),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(hintText: "Enter somthing.."),
                  ),
                ),
                IconButton(onPressed: _sent_messages, icon: Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
