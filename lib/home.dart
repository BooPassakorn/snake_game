import 'package:flutter/material.dart';
import 'package:snake_game/auth/auth_service.dart';

import 'main.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void logout(BuildContext context) async {
    //เรียกใช้ AuthService เพื่อทำการ sign out
    final auth = AuthService();
    await auth.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MyHomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    //ดึงข้อมูลของผู้ใช้ท
    final user = AuthService().getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: user != null
            ? Text("Welcome, ${user.displayName}")
            : const Text("No user signed in"),
      ),
    );
  }
}
