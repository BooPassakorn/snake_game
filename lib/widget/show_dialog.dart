import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:snake_game/auth/auth_service.dart';
import 'package:snake_game/home.dart';
import 'package:snake_game/level/level_one.dart';

class ShowAllScore {
  static void showAllScore(BuildContext context) async {
    final user = AuthService().getCurrentUser();
    if (user == null) return;

    final uid = user.uid; //ดึง uid

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('play_history')
          .where('uid', isEqualTo: uid)  //เทียบ uid ที่ตรงกับผู้ใช้ปัจจุบัน
          .get();

      if (querySnapshot.docs.isEmpty) { //ถ้าไม่มีข้อมูล
        _showDialog(context, 0, "00:00:00", 1);
        return;
      }

      final allLevels = querySnapshot.docs //ดึงทุก level ที่เคยถึง
        .map((doc) => doc.data()['levelreach'] as int)
        .toList();

      final bestLevel = allLevels.reduce(max); //หา level ที่มากที่สุด

      //คัด Level ที่ดีที่สุด
      final bestLevelDocs = querySnapshot.docs
          .where((doc) => doc.data()['levelreach'] == bestLevel)
          .toList();

      //หา Score สูงสุดใน Level นี้ เรียงจากมากไปน้อย
      bestLevelDocs.sort((a, b) => (b.data()['score'] as int).compareTo(a.data()['score'] as int));
      final highestScore = bestLevelDocs.first.data()['score']; //ใช้ Score อันแรก

      //คัด score สูงสุดใน level นี้
      final topScoreDocs = bestLevelDocs
          .where((doc) => doc.data()['score'] == highestScore)
          .toList();

      //หาเวลาน้อยสุดจากคะแนนสูงสุด
      topScoreDocs.sort((a, b) {
        final timeA = _parseDuration(a.data()['time']);
        final timeB = _parseDuration(b.data()['time']);
        return timeA.compareTo(timeB);
      });

      final bestTime = topScoreDocs.first.data()['time'];

      _showDialog(context, highestScore, bestTime, bestLevel);
    } catch (e) {
      print("เกิดข้อผิดพลาด: $e");
    }
  }

  static void _showDialog(BuildContext context, int score, String time, int level) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade300,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10),
              Text("Best Score : $score", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: "Silkscreen")),
              SizedBox(height: 10),
              Text("Best Time : $time", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: "Silkscreen")),
              SizedBox(height: 10),
              Text("Best Level : $level", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: "Silkscreen")),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  static Duration _parseDuration(String timeString) {
    final parts = timeString.split(':');
    if (parts.length != 3) return Duration.zero;
    final minutes = int.tryParse(parts[0]) ?? 0;
    final seconds = int.tryParse(parts[1]) ?? 0;
    final milliseconds = int.tryParse(parts[2]) ?? 0;
    return Duration(minutes: minutes, seconds: seconds, milliseconds: milliseconds * 10);
  }
}


class ShowGameOver {
  static void showGameOver(BuildContext context, int level, int score, Duration duration, VoidCallback startGame) {
    //แปลงเวลาเป็น mm:ss:SS
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    String milliseconds = twoDigits((duration.inMilliseconds.remainder(1000) ~/ 10));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Center(
            child: Text(
              "Game Over",
              textAlign: TextAlign.center,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Level : $level", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Text("Score : $score", style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Text("Time : $minutes:$seconds:$milliseconds", style: const TextStyle(fontSize: 18)),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
              child: const Text("Home"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                startGame();
              },
              child: const Text("Restart"),
            ),
          ],
        );
      },
    );
  }
}

class PauseDialog {
  static void showPauseDialog(BuildContext context, VoidCallback restartGame, VoidCallback playContinueGame) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Game Paused", textAlign: TextAlign.center),
          content: const Text("Do you want to Restart the game?"),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                playContinueGame(); // เรียก resume
              },
              child: const Text("Go"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                restartGame();
              },
              child: const Text("Restart"),
            ),
          ],
        );
      },
    );
  }
}

class LevelPass {
  static void showLevelPassDialog(BuildContext context, Duration duration, VoidCallback restartGame, int level, VoidCallback goNextLevel) {

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    String milliseconds = twoDigits((duration.inMilliseconds.remainder(1000) ~/ 10));

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Level : $level", style: TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Text("You Passed", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Text("Time : $minutes:$seconds:$milliseconds", style: const TextStyle(fontSize: 18)),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  goNextLevel();  //เรียกฟังก์ชันเพื่อไป Level ต่อไป
                },
                child: const Text("Next Level"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  restartGame();
                },
                child: const Text("Restart"),
              ),
            ],
          );
        }
    );
  }
}

class LevelCongratulation {
  static void showLevelCongratulationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Congratulation", textAlign: TextAlign.center),
          // content: const Text("Do you want to Restart the game?"),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
              },
              child: const Text("Home"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LevelOne()),
                );
              },
              child: const Text("Play again"),
            ),
          ],
        );
      },
    );
  }
}