import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:websoccetchat/chat/chatpages.dart';

const apiKey = "AIzaSyDz2U1DC4qdgEwrwDSeZTxCeSxgYFbRbEo";
void main() {
  Gemini.init(apiKey: apiKey);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Chatpages()
    );
  }
}
