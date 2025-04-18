import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:snake_game/widget/show_dialog.dart';

class SnakeGameSurvival extends StatefulWidget {
  const SnakeGameSurvival({super.key});

  @override
  State<SnakeGameSurvival> createState() => _SnakeGameSurvivalState();
}

enum Direction { up, down, left, right }

class _SnakeGameSurvivalState extends State<SnakeGameSurvival> {
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

  int snakeSpeed = 300; //เริ่มต้น 300 milliseconds
  int lastSpeedUpAt = 0; //บันทึกว่าวินาทีไหนเราปรับความเร็วครั้งล่าสุด

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
      hasSavedResult = false;
      borderList.clear();
      snakeSpeed = 300;
      lastSpeedUpAt = 0;
    });

    stopwatch.reset();
    stopwatch.start();

    startTimer();

    makeBorder();
    generateFood();
    direction = Direction.right;
    snakePosition = [46, 45, 44];
    snakeHead = snakePosition.first;

    snakeTimer?.cancel();
    snakeTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) async {
      if (isGamePause) {
        timer.cancel();
      } else {
        updateSnake();
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
    snakeTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) async {
      if (isGamePause) {
        timer.cancel();
      } else {
        updateSnake();
        if (checkCollision()) {
          final gameOverTime = stopwatch.elapsed;
          timer.cancel();
          stopwatch.stop();
          if (!hasSavedResult) {
            hasSavedResult = true;
            ShowGameSurvivalOver.showGameSurvivalOver(context, score, gameOverTime, restartGame);
            unawaited(savePlaySurvivalResult(score, gameOverTime));
          }
        }
      }
    });
  }

  void restartGame() {
    setState(() {
      isGamePause = false;
      hasSavedResult = false;
    });
    startTimer();
    startGame();
  }

  bool checkCollision() { //ตรวจการชน
    if (borderList.contains(snakeHead)) return true; //ชนขอบ
    if (snakePosition.sublist(1).contains(snakeHead)) return true; //ชนตัวเอง
    return false;
  }

  void generateFood() {
    do {
      foodPosition = Random().nextInt(row * column);
    } while (borderList.contains(foodPosition) || snakePosition.contains(foodPosition));
  }

  Future<void> updateSnake() async {
    if (isGamePause) return;

    //ตรวจสอบว่าเวลาผ่านไปแล้วกี่วิ
    int secondsElapsed = stopwatch.elapsed.inSeconds;

    //ถ้าผ่านไปทีละ 30 วินาที
    if (secondsElapsed - lastSpeedUpAt >= 30) {
      if (snakeSpeed > 100) { //จำกัดความเร็วไม่ให้เร็วเกินไป
        snakeSpeed -= 10;
        lastSpeedUpAt = secondsElapsed;

        //รีสตาร์ท snakeTimer ด้วยความเร็วใหม่
        snakeTimer?.cancel();
        snakeTimer = Timer.periodic(Duration(milliseconds: snakeSpeed), (timer) async {
          if (isGamePause) {
            timer.cancel();
          } else {
            updateSnake();
            if (checkCollision()) {
              final gameOverTime = stopwatch.elapsed;
              timer.cancel();
              stopwatch.stop();
              if (!hasSavedResult) {
                hasSavedResult = true;
                ShowGameSurvivalOver.showGameSurvivalOver(context, score, gameOverTime, restartGame);
                unawaited(savePlaySurvivalResult(score, gameOverTime));
              }
            }
          }
        });
      }
    }

    int newHead;
    switch (direction) {
      case Direction.up:
        newHead = snakeHead - column;
        break;
      case Direction.down:
        newHead = snakeHead + column;
        break;
      case Direction.right:
        newHead = snakeHead + 1;
        break;
      case Direction.left:
        newHead = snakeHead - 1;
        break;
    }

    // ตรวจชนก่อนอัปเดต
    if (borderList.contains(newHead) || snakePosition.contains(newHead)) {
      final gameOverTime = stopwatch.elapsed;
      stopwatch.stop();

      setState(() {
        isGamePause = true;
      });

      if (!hasSavedResult) {
        hasSavedResult = true;
        ShowGameSurvivalOver.showGameSurvivalOver(context, score, gameOverTime, restartGame);
        unawaited(savePlaySurvivalResult(score, gameOverTime));
      }
      return;
    }

    setState(() {
      snakePosition.insert(0, newHead);

      if (newHead == foodPosition) {
        score++;
        generateFood();
      } else {
        snakePosition.removeLast();
      }

      snakeHead = newHead;
    });
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
                      Text("🧩 Mode : Survival",
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
    if(borderList.contains(index))
      return Colors.yellowAccent;
    else{
      if(snakePosition.contains(index)) {
        if(snakeHead == index) {
          return Colors.green.shade800;
        } else {
          return Colors.green.shade400;
        }
      } else {
        if (index == foodPosition) {
          return Colors.redAccent;
        }
      }
    }
    return Colors.grey.withValues(alpha: 0.3);
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

  Future<void> savePlaySurvivalResult(int score, Duration time) async {
    try {
      final String uid = FirebaseAuth.instance.currentUser!.uid;
      final String formattedTime = formatTime(time);

      await FirebaseFirestore.instance.collection('play_survival_history').add({
        'uid': uid,
        'time': formattedTime,
        'score': score,
        'created_at': Timestamp.now(),
      });
      print("บันทึกข้อมูลสำเร็จ");
    } catch (e) {
      print("บันทึกข้อมูลไม่สำเร็จ: $e");
    }
  }

}
