import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

        if (!mounted) return; //หน้ายังทำงานอยู่ไหม ป้องกันการพัง ถ้า widget หายไปแล้ว

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
      backgroundColor: Colors.lightBlue.shade100,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Image(image: AssetImage('assets/SnakeLogo.png'), height: 150, width: 150,),
              // const Icon(
              //   Icons.videogame_asset,
              //   size: 100,
              //   color: Colors.white70,
              // ),
              const SizedBox(height: 20),
              Text(
                "Snake Game",
                style: TextStyle(
                  fontFamily: "BungeeSpice",
                  fontSize: 40,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _signInAndNavigate,
                icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white),
                label: const Text(
                  "Sign in with Google",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, fontFamily: "Anton"),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
