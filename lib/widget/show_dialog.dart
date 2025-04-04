import 'dart:async';

import 'package:flutter/material.dart';
import 'package:snake_game/home.dart';

class ShowAllScore {
  static void showAllScore(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade300,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10),
              Text("Best Score : 0", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Best Time : 00:00:00", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Best Level : 1", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
}

class ShowGameOver {
  static void showGameOver(BuildContext context, int score, Duration duration, VoidCallback startGame) {
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
              Text("Level : ", style: TextStyle(fontSize: 18)),
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