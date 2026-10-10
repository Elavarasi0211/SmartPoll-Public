import 'package:flutter/material.dart';

import 'voter_id_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const SmartPollApp());
}

class SmartPollApp extends StatelessWidget {
  const SmartPollApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartPoll',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF102A43),
        ),
        useMaterial3: true,
      ),
      home: const VoterIdScreen(),
    );
  }
}