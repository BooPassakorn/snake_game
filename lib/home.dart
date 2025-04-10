import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:snake_game/auth/auth_service.dart';
import 'package:snake_game/level/level_one.dart';
import 'package:snake_game/widget/show_dialog.dart';

import 'level/Level_three.dart';
import 'level/level.dart';
import 'level/level_five.dart';
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
      backgroundColor: Colors.lightBlue.shade100,
      appBar: AppBar(
        automaticallyImplyLeading: false, //ซ่อนปุ่มย้อนกลับ
        backgroundColor: Colors.lightBlue.shade100,
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
            const Image(image: AssetImage('assets/SnakeLogo.png'), height: 150, width: 150,),
            Text(
              "Snake Game",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.deepOrange, fontFamily: "BungeeSpice"),
            ),
            SizedBox(height: 8),
            //โชว์รูป Profile
            CircleAvatar(
              radius: 70, //ขนาดรูป
              backgroundImage: user.photoURL != null
                  ? NetworkImage(user.photoURL!) //ดึงรูปจาก Google
                  : const AssetImage("assets/default_avatar.png") as ImageProvider, //รูป default ถ้าไม่มีรูป
            ),
            SizedBox(height: 16),
            // แสดงชื่อผู้ใช้
            Text(
              "${user.displayName}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: "Silkscreen"),
            ),
            SizedBox(height: 8),
            Text(
              "Best Score: ${bestScore != null ? bestScore.toString() : "0"}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: "Silkscreen"),
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SnakeGameLevel(levelNumber: 1,)),
                );
              },
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text("Start",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "Silkscreen", color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => ShowAllScore.showAllScore(context),
              icon: const Icon(Icons.leaderboard, color: Colors.white),
              label: const Text(
                "View All Score",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "Silkscreen", color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ],
        )
            : const Text(
          "No user signed in",
          style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: "Silkscreen"),
        ),
      ),
    );
  }
}
