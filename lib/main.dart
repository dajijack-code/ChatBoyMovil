import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'viewmodels/chat_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChatBoyApp());
}

class ChatBoyApp extends StatelessWidget {
  const ChatBoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatViewModel()..loadPreferences(),
      child: MaterialApp(
        title: 'ChatBoy Voice',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
