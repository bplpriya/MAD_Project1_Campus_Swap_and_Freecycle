import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyBBV7HGyAR87WnslHd4y3wVMtZYzfqoXW0",
        authDomain: "maddemo-621ab.firebaseapp.com",
        projectId: "maddemo-621ab",
        storageBucket: "maddemo-621ab.firebasestorage.app",
        messagingSenderId: "652887940699",
        appId: "1:652887940699:web:9d5511f5d363cdeb0ba97e",
        measurementId: "G-S50PK1CSRY",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Auth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
    );
  }
}
