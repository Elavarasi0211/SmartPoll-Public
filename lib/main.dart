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

        scaffoldBackgroundColor:
        const Color(0xFFF5F8FC),

        useMaterial3: true,
      ),

      // Voter Login is the first screen.
      // Admin Login is opened from the Admin Login
      // button inside the Voter Login screen.
      home: const VoterIdScreen(),
    );
  }
}