import 'package:flutter/material.dart';
import 'package:snake_game/auth/auth_service.dart';

import 'main.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void logout(BuildContext context) async {
    //เรียกใช้ AuthService เพื่อทำการ sign out
    final _auth = AuthService();
    await _auth.signOut();

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
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //โชว์รูป Profile
            CircleAvatar(
              radius: 50, //ขนาดรูป
              backgroundImage: user.photoURL != null
                  ? NetworkImage(user.photoURL!) //ดึงรูปจาก Google
                  : const AssetImage("assets/default_avatar.png") as ImageProvider, //รูป default ถ้าไม่มีรูป
            ),
            SizedBox(height: 16),
            // แสดงชื่อผู้ใช้
            Text(
              "Welcome, ${user.displayName}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
          ],
        )
            : const Text("No user signed in"),
      ),
    );
  }

}
