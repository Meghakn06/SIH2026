// ignore_for_file: avoid_print

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization skipped or failed: $e');
  }
  runApp(const InspectraApp());
}

class InspectraApp extends StatelessWidget {
  const InspectraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Firebase Test')),
        body: Center(
          child: ElevatedButton(
            child: const Text('Test Firebase'),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').add({
                'name': 'Firebase Test',
                'email': 'test@inspectra.com',
                'role': 'inspector',
              });

              print('Firebase write successful!');
            },
          ),
        ),
      ),
    );
  }
}  