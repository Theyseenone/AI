import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ai/chatgpt_screen.dart';

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

  // Sign in anonymously for dev (required by example Firestore rules)
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
    debugPrint('Signed-in uid: ${FirebaseAuth.instance.currentUser?.uid}');
  } catch (e, st) {
    debugPrint('Auth error: $e\n$st');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPT Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home:  ChatgptScreen(),
    );
  }
}
