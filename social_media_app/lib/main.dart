import 'package:flutter/material.dart';
import 'package:social_media_app/main_wrapper.dart';
import 'package:social_media_app/screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // 1. Ensures Flutter framework is ready before calling asynchronous code
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Connects your Flutter code to the Firebase project backend
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Start the app
  runApp(const MetaFlowApp()); // Changed from MyApp to MetaFlowApp
}

class MetaFlowApp extends StatelessWidget {
  const MetaFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FaceTagram',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
      ),
      home: const MainWrapper(),
    );
  }
}