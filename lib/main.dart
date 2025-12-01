import 'package:ai/auth_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (replace with your project's values if different)
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyD1LM1P2TSd5UfUoTG4A0a8rSKf4ASxiQM',
      appId: '1:209541996134:android:8388e7ead166b4cde217a7',
      messagingSenderId: '209541996134',
      projectId: 'flutter-ai-868fb',
    ),
  );

  // Don't auto-sign in - let AuthScreen handle authentication
  debugPrint('Firebase initialized');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPT Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        primaryColor: Colors.blue.shade400,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade400,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home:  AuthScreen(),
    );
  }
}
