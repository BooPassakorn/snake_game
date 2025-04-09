import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:snake_game/home.dart';
import 'package:snake_game/widget/show_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LevelFive extends StatefulWidget {
  const LevelFive({super.key});

  @override
  State<LevelFive> createState() => _LevelFiveState();
}

enum Direction {up, down, left, right}

class _LevelFiveState extends State<LevelFive> {

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  int row = 20;
  int column = 20;
  List<int> borderList = [];
  List<int> snakePosition = [];
  int snakeHead = 0;
  int score = 0;
  late Direction direction;
  late int foodPosition;
  Stopwatch stopwatch = Stopwatch();
  Timer? timer;
  bool isGamePause = false;
  Timer? snakeTimer;  //สำหรับงู
  Timer? uiTimer;     //สำหรับแสดงเวลา
  bool hasSavedResult = false;
  List<int> obstacles = []; //สิ่งกีดขวาง

  @override
  void initState() {
    startGame();
    super.initState();
  }

  void startTimer({bool resetStopwatch = true}) { //ถ้าได้(Restart) true จะรีเซ็ตเวลา, ได้(Go) false จะไม่รีเซ็ตเวลา

    if (resetStopwatch) {
      stopwatch.reset();
      stopwatch.start();
    }
    uiTimer?.cancel();

    uiTimer = Timer.periodic(Duration(milliseconds: 10), (_) {
      if (!isGamePause) {
        setState(() {});  //รีเฟรชเวลา
      }
    });
  }

  void startGame() {

    setState(() {
      score = 0;
      isGamePause = false;
    });

    stopwatch.reset();
    stopwatch.start();

    uiTimer?.cancel();
    startTimer();

    makeBorder();
    Obstacles();
    generateFood();
    direction = Direction.right;
    // snakePosition = [65,63,64];
    snakePosition = [365,364,363];
    snakeHead = snakePosition.first;

    snakeTimer?.cancel(); //หยุดงู
    snakeTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) async {
      if (isGamePause) {
        timer.cancel();
      } else {
        updateSnake();
        if (checkCollision()) {
          timer.cancel();
          stopwatch.stop();
          if (!hasSavedResult) {
            hasSavedResult = true;
            await savePlayResult(score, stopwatch.elapsed, 5);
            ShowGameOver.showGameOver(context, 5, score, stopwatch.elapsed, startGame);
          }
        }
      }
    });
  }

  void pauseGame() {
    setState(() {
      isGamePause = true;
    });

    stopwatch.stop();
    uiTimer?.cancel();
    snakeTimer?.cancel();

    PauseDialog.showPauseDialog(context, restartGame, playContinueGame);
  }

  void playContinueGame() {
    setState(() {
      isGamePause = false;
    });

    stopwatch.start();
    startTimer(resetStopwatch: false);

    //งูเดินต่อ
    snakeTimer?.cancel();
    snakeTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (isGamePause) {
        timer.cancel();
      } else {
        updateSnake();
        if (checkCollision()) {
          timer.cancel();
          stopwatch.stop();
          ShowGameOver.showGameOver(context, 5, score, stopwatch.elapsed, startGame);
        }
      }
    });
  }

  void restartGame() {
    setState(() {
      isGamePause = false;
      hasSavedResult = false;
      Obstacles();
    });
    startTimer();
    startGame();
  }

  bool checkCollision() { //ตรวจการชน
    if (borderList.contains(snakeHead)) return true; //ชนขอบ
    if (snakePosition.sublist(1).contains(snakeHead)) return true; //ชนตัวเอง
    if (obstacles.contains(snakeHead)) return true; //ชนสิ่งกีดขวาง
    return false;
  }

  void generateFood() {
    int newFoodPos;
    do {
      newFoodPos = Random().nextInt(row * column);
    } while (borderList.contains(newFoodPos) || obstacles.contains(newFoodPos));

    foodPosition = newFoodPos;
  }


  Future<void> updateSnake() async {
    if (isGamePause) return;

    setState(() {

      switch(direction){
        case Direction.up:
          snakePosition.insert(0, snakeHead - column);
          break;
        case Direction.down:
          snakePosition.insert(0, snakeHead + column);
          break;
        case Direction.right:
          snakePosition.insert(0, snakeHead + 1);
          break;
        case Direction.left:
          snakePosition.insert(0, snakeHead - 1);
          break;
      }
      // snakePosition.insert(0, snakeHead + 1);
    });

    if (snakeHead == foodPosition) {
      score++;
      generateFood();

      if (score == 20 && !hasSavedResult){
        hasSavedResult = true;
        stopwatch.stop();
        isGamePause = true;
        await savePlayResult(score, stopwatch.elapsed, 5);
        LevelCongratulation.showLevelCongratulationDialog(context);
      }
    } else {
      snakePosition.removeLast();
    }

    snakeHead = snakePosition.first; //
  }

  void goNextLevel() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  void Obstacles() {
    obstacles = [
      350, 330, 310, 290, 270, 250, 230, 210, 190, 170, 150, 130, 110, 90, 70, 50,
      349, 329, 309, 289, 269, 249, 229, 209, 189, 169, 149, 129, 109, 89, 69, 49,
      91, 92, 93, 94, 95, 96, 89, 88, 87, 86, 85, 84, 83,
      151, 152, 153, 154, 155, 156, 149, 148, 147, 146, 145, 144, 143,
      211, 212, 213, 214, 215, 216, 209, 208, 207, 206, 205, 204, 203,
      271, 272, 273, 274, 275, 276, 269, 268, 267, 266, 265, 264, 263,
      331, 332, 333, 334, 335, 336, 329, 328, 327, 326, 325, 324, 323
    ];  //กำหนดตำแหน่งสิ่งกีดขวางคงที่
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.blueGrey,
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text("Level : 5"),
                      Text("Score : $score"),
                    ],
                  ),
                  _buildTime(),
                ],
              ),
            ),
            Expanded(
                child: _buildGameView()),
            _buildPause(),
            _buildGameControls()
          ],
        ),
      ),
    );
  }

  Widget _buildGameView() {
    return GridView.builder(gridDelegate:
    SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: column),
      itemBuilder: (context, index){
        return Container(
          margin: EdgeInsets.all(1),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7), color: fillBoxColor(index)),
        );
      },
      itemCount: row*column,
    );
  }

  Widget _buildGameControls() {
    return Container(
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(onPressed: (){
            if(direction!=Direction.down) direction = Direction.up;
          }, icon: const Icon(Icons.arrow_circle_up), iconSize: 80),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: (){
                if(direction!=Direction.right) direction = Direction.left;
              }, icon: const Icon(Icons.arrow_circle_left_outlined), iconSize: 80),
              SizedBox(width: 100),
              IconButton(onPressed: (){
                if(direction!=Direction.left) direction = Direction.right;
              }, icon: const Icon(Icons.arrow_circle_right_outlined), iconSize: 80),
            ],
          ),
          IconButton(onPressed: (){
            if(direction!=Direction.up) direction = Direction.down;
          }, icon: const Icon(Icons.arrow_circle_down_outlined), iconSize: 80),
        ],
      ),
    );
  }

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    String milliseconds = twoDigits((duration.inMilliseconds.remainder(1000) ~/ 10));
    return "$minutes:$seconds:$milliseconds";
  }

  Widget _buildTime() {
    return Text("Time : ${formatTime(stopwatch.elapsed)}",
      style: TextStyle(),);
  }

  Widget _buildPause() {
    return Align(
      alignment: Alignment(-0.95, 0),
      child: ElevatedButton(
          onPressed: () {
            pauseGame();
          }, child: Text("Pause")),
    );
  }

  Color fillBoxColor(int index) {
    if (borderList.contains(index)) {
      return Colors.yellow;  //ขอบ
    } else if (snakePosition.contains(index)) {
      if (snakeHead == index) {
        return Colors.greenAccent; //หัวงู
      } else {
        return Colors.green.shade400; //ตัวงู
      }
    } else if (index == foodPosition) {
      return Colors.red; //อาหาร
    } else if (obstacles.contains(index)) {
      return Colors.brown; //สิ่งกีดขวาง
    }
    return Colors.grey.withOpacity(0.05);
  }

  makeBorder() {
    for(int i=0; i<column; i++) { //บน
      if(!borderList.contains(i)) borderList.add(i);
    }
    for(int i=0; i<row*column; i=i+column){ //ซ้าย
      if(!borderList.contains(i)) borderList.add(i);
    }
    for(int i=column-1; i<row*column; i=i+column){ //ขวา
      if(!borderList.contains(i)) borderList.add(i);
    }
    for(int i= (row*column)-column; i<row*column; i=i+1){ //ล่าง
      if(!borderList.contains(i)) borderList.add(i);
    }
  }

  Future<void> savePlayResult(int score, Duration time, int level) async {
    try {
      final String uid = FirebaseAuth.instance.currentUser!.uid;
      final String formattedTime = formatTime(time);

      await FirebaseFirestore.instance.collection('play_history').add({
        'uid': uid,
        'time': formattedTime,
        'score': score,
        'levelreach': level,
        'created_at': Timestamp.now(),
      });
      print("บันทึกข้อมูลสำเร็จ");
    } catch (e) {
      print("บันทึกข้อมูลไม่สำเร็จ: $e");
    }
  }

}
