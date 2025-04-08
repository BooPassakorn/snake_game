import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'auth/auth_service.dart';
import 'home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  void _signInAndNavigate() async {
    //เรียกใช้ Google Sign in
    var userCredential = await AuthService().signInWithGoogle();

    if (userCredential != null) {
      var user = userCredential.user;

      if (user != null) {
        final usersRef = FirebaseFirestore.instance.collection('users');

        final doc = await usersRef.doc(user.uid).get();

        if (!doc.exists) {
          await usersRef.doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'displayName': user.displayName,
          });
        }

        //ไปที่หน้า HomePage เมื่อ sign in ผ่าน
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "Snake Game",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signInAndNavigate,
              child: const Text("Google Sign In"),
            ),
          ],
        ),
      ),
    );
  }
}
