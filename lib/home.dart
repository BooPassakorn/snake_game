import 'package:flutter/material.dart';
import 'package:snake_game/auth/auth_service.dart';
import 'package:snake_game/widget/show_dialog.dart';

import 'main.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void logout(BuildContext context) async {
    //เรียกใช้ AuthService เพื่อทำการ logout
    final _auth = AuthService();
    await _auth.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MyHomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    //ดึงข้อมูลของผู้ใช้
    final user = AuthService().getCurrentUser();

    return Scaffold(
      backgroundColor: Colors.lightBlue,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
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
            Text(
              "Snake Game",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
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
              "${user.displayName}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Best Score: ",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => (),
              child: const Text("Start"),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ShowAllScore.showAllScore(context),
              child: const Text("View All Score"),
            ),
          ],
        )
            : const Text("No user signed in"),
      ),
    );
  }

}
