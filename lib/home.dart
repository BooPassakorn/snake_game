import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:snake_game/auth/auth_service.dart';
import 'package:snake_game/level/level_one.dart';
import 'package:snake_game/widget/show_dialog.dart';

import 'level/Level_three.dart';
import 'level/level_four.dart';
import 'level/level_two.dart';
import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  void logout(BuildContext context) async {
    //เรียกใช้ AuthService เพื่อทำการ logout
    final _auth = AuthService();
    await _auth.signOut();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MyHomePage()),
    );
  }

  int? bestScore;

  @override
  void initState() {
    super.initState();
    fetchBestScore(); //ดึงคะแนนเมื่อโหลดหน้าจอ
  }

  Future<void> fetchBestScore() async {
    final user = AuthService().getCurrentUser();
    if (user == null) return;

    final uid = user.uid;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('play_history')
          .where('uid', isEqualTo: uid) //ค้นหา uid
          .orderBy('score', descending: true) //เรียงจากมากไปน้อย
          .limit(1) //เอาแค่ 1 อันดับแรกที่เจอ
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final score = querySnapshot.docs.first.data()['score'];
        setState(() {
          bestScore = score;
        });
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการดึงคะแนน: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    //ดึงข้อมูลของผู้ใช้
    final user = AuthService().getCurrentUser();

    return Scaffold(
      backgroundColor: Colors.lightBlue,
      appBar: AppBar(
        automaticallyImplyLeading: false, //ซ่อนปุ่มย้อนกลับ
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
              "Best Score: ${bestScore != null ? bestScore.toString() : "0"}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LevelFour()),
                );
              },
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
