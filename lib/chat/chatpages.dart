import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

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
  bool _isGeminiThinking = false;

  @override
  void initState() {
    super.initState();
    channel = WebSocketChannel.connect(Uri.parse("ws://192.168.1.10:8080"));

    channel.stream.listen((message) {
      final decoded = jsonDecode(message);
      setState(() {
        messages.add({
          "sender": "server",
          "type": decoded["type"],
          "data": decoded["data"],
        });
      });
    });
  }

  void _sent_messages() async {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"sender": "user", "type": "text", "data": text});
      _isGeminiThinking = true;
    });
    _controller.clear();

    try {
      channel.sink.add(jsonEncode({"type": "text", "data": text}));
      final gemini = Gemini.instance;
      final response = await gemini.chat([
        Content(
          role: "user",
          parts: [Parts(text: text)],
        ),
      ]);

      String geminiResponseText = response?.output ?? "Javob yo'q";

      setState(() {
        messages.add({
          "sender": "gemini",
          "type": "text",
          "data": geminiResponseText,
        });
        _isGeminiThinking = false;
      });
    } catch (e) {
      setState(() {
        messages.add({
          "sender": "gemini",
          "type": "text",
          "data": "Gemini aloqada xato: $e",
        });
        _isGeminiThinking = false;
      });
      print("Gemini xatosi: $e");
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
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      channel.sink.add(jsonEncode({"type": "image", "data": base64Image}));
      setState(() {
        messages.add({"sender": "user", "type": "image", "data": base64Image});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat"), backgroundColor: Colors.blueGrey),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length + (_isGeminiThinking ? 1 : 0),
              itemBuilder: (BuildContext context, int index) {
                if (index == messages.length && _isGeminiThinking) {
                  return const Center(child: CircularProgressIndicator());
                }

                final msg = messages[index];
                final isUser = msg["sender"] == "user";
                final isGemini = msg["sender"] == "gemini";

                if (msg["type"] == "text") {
                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0,
                      ),
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.blueAccent[100]
                            : (isGemini
                                  ? Colors.greenAccent[100]
                                  : Colors.grey[300]),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(msg["data"]),
                    ),
                  );
                } else if (msg["type"] == "image") {
                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0,
                      ),
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.blueAccent[100]
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Image.memory(
                        base64Decode(msg["data"]),
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
          if (_isGeminiThinking)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            child: Row(
              children: [
                IconButton(onPressed: imagepickerchoose, icon: Icon(Icons.add)),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Enter something..",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
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
