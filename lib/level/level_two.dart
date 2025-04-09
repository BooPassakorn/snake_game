import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:snake_game/widget/show_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'Level_three.dart';

class LevelTwo extends StatefulWidget {
  const LevelTwo({super.key});

  @override
  State<LevelTwo> createState() => _LevelTwoState();
}

enum Direction {up, down, left, right}

class _LevelTwoState extends State<LevelTwo> {

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
    snakePosition = [166,165,164];
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
            await savePlayResult(score, stopwatch.elapsed, 2);
            ShowGameOver.showGameOver(context, 2, score, stopwatch.elapsed, restartGame);
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
          ShowGameOver.showGameOver(context, 2, score, stopwatch.elapsed, restartGame);
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

      if (score == 12 && !hasSavedResult){
        hasSavedResult = true;
        stopwatch.stop();
        isGamePause = true;
        await savePlayResult(score, stopwatch.elapsed, 2);
        LevelPass.showLevelPassDialog(context, stopwatch.elapsed, restartGame, 2, goNextLevel);
      }
    } else {
      snakePosition.removeLast();
    }

    snakeHead = snakePosition.first; //
  }

  void goNextLevel() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LevelThree()), // <-- เปลี่ยนเป็นหน้า Level 3
    );
  }

  void Obstacles() {
    obstacles = [63, 64, 65, 83, 103,
                74, 75, 76, 96, 116,
                283, 303, 323, 324, 325,
                334, 335, 296, 316, 336];  //กำหนดตำแหน่งสิ่งกีดขวางคงที่
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.lightBlue.shade100,
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text("🧩 Level: 2",
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Silkscreen',
                            color: Colors.white,
                          )),
                      Text("🏆 Score: $score",
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Silkscreen',
                            color: Colors.white,
                          )),
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
          }, icon: const Icon(Icons.arrow_circle_up), iconSize: 80, color: Colors.green),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: (){
                if(direction!=Direction.right) direction = Direction.left;
              }, icon: const Icon(Icons.arrow_circle_left_outlined), iconSize: 80, color: Colors.green),
              SizedBox(width: 100),
              IconButton(onPressed: (){
                if(direction!=Direction.left) direction = Direction.right;
              }, icon: const Icon(Icons.arrow_circle_right_outlined), iconSize: 80, color: Colors.green),
            ],
          ),
          IconButton(onPressed: (){
            if(direction!=Direction.up) direction = Direction.down;
          }, icon: const Icon(Icons.arrow_circle_down_outlined), iconSize: 80, color: Colors.green),
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
    return Text(
      "⏱ Time: ${formatTime(stopwatch.elapsed)}",
      style: const TextStyle(
        fontSize: 16,
        fontFamily: 'Silkscreen',
        color: Colors.white,
      ),
    );
  }

  Widget _buildPause() {
    return Align(
      alignment: const Alignment(-0.95, 0),
      child: ElevatedButton.icon(
        onPressed: pauseGame,
        icon: const Icon(Icons.pause_circle),
        label: const Text("Pause"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Color fillBoxColor(int index) {
    if (borderList.contains(index)) {
      return Colors.yellowAccent;  //ขอบ
    } else if (snakePosition.contains(index)) {
      if (snakeHead == index) {
        return Colors.green.shade800; //หัวงู
      } else {
        return Colors.green.shade400; //ตัวงู
      }
    } else if (index == foodPosition) {
      return Colors.redAccent; //อาหาร
    } else if (obstacles.contains(index)) {
      return Colors.brown; //สิ่งกีดขวาง
    }
    return Colors.grey.withOpacity(0.3);
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
