import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:snake_game/widget/show_dialog.dart';

class SnakeGameLevel extends StatefulWidget {
  final int levelNumber;

  const SnakeGameLevel({super.key, required this.levelNumber});

  @override
  State<SnakeGameLevel> createState() => _SnakeGameLevelState();
}

enum Direction { up, down, left, right }

class _SnakeGameLevelState extends State<SnakeGameLevel> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  int row = 20;
  int column = 20;
  List<int> borderList = [];
  List<int> snakePosition = [];
  int snakeHead = 0;
  int score = 0;
  late Direction direction;
  int? foodPosition;
  Stopwatch stopwatch = Stopwatch();
  Timer? timer;
  bool isGamePause = false;
  Timer? snakeTimer;  //สำหรับงู
  Timer? uiTimer;     //สำหรับแสดงเวลา
  bool hasSavedResult = false;
  List<int> obstacles = []; //สิ่งกีดขวาง

  Map<int, List<int>> levelSnakePositions = {};

  Future<LevelConfig> fetchLevelConfig(int levelNumber) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('levels')
        .doc('level_$levelNumber')
        .get();

    final data = snapshot.data();

    if (data == null) {
      throw Exception('Level data not found for level_$levelNumber');
    }

    return LevelConfig(
      obstacles: List<int>.from(data['obstacles'] ?? []),
      nextLevel: data['nextLevel'],
      requiredScore: data['requiredScore'],
      initialSnakePosition:
      List<int>.from(data['initialSnakePosition'] ?? []),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startGame();
      generateFood();
    });
  }

  void startTimer({bool resetStopwatch = true}) { //ถ้าได้(Restart) true จะรีเซ็ตเวลา, ได้(Go) false จะไม่รีเซ็ตเวลา
    if (resetStopwatch) {
      stopwatch.reset();
      stopwatch.start();
    }
    uiTimer?.cancel();

    uiTimer = Timer.periodic(Duration(milliseconds: 10), (_) {
      if (!isGamePause) {
        setState(() {}); //รีเฟรชเวลา
      }
    });
  }

  Future<void> startGame() async {
    final config = await fetchLevelConfig(widget.levelNumber);

    setState(() {
      score = 0;
      isGamePause = false;
      obstacles = config.obstacles;
      snakePosition = List.from(config.initialSnakePosition);
      snakeHead = snakePosition.first;
      levelSnakePositions[widget.levelNumber] = List.from(snakePosition);
    });

    stopwatch.reset();
    stopwatch.start();

    uiTimer?.cancel();
    startTimer();

    makeBorder();
    obstacles = config.obstacles;
    generateFood();

    direction = Direction.right;
    // snakePosition = List.from(config.initialSnakePosition);
    snakeHead = snakePosition.first;

    levelSnakePositions[widget.levelNumber] = List.from(snakePosition); //บันทึกตำแหน่งงูที่ level นี้

    snakeTimer?.cancel();
    snakeTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) async {
      if (isGamePause) {
        timer.cancel();
      } else {
        updateSnake(config);
        if (checkCollision()) {
          timer.cancel();
          stopwatch.stop();
          if (!hasSavedResult) {
            hasSavedResult = true;
            ShowGameOver.showGameOver(context, widget.levelNumber, score, stopwatch.elapsed, restartGame);
            savePlayResult(score, stopwatch.elapsed, widget.levelNumber);
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

  Future<void> playContinueGame() async {
    setState(() {
      isGamePause = false;
    });

    stopwatch.start();
    startTimer(resetStopwatch: false);

    final config = await fetchLevelConfig(widget.levelNumber);

    //งูเดินต่อ
    snakeTimer?.cancel();
    snakeTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (isGamePause) {
        timer.cancel();
      } else {
        updateSnake(config);
        if (checkCollision()) {
          timer.cancel();
          stopwatch.stop();
          if (!hasSavedResult) {
            hasSavedResult = true;
            ShowGameOver.showGameOver(context, widget.levelNumber, score, stopwatch.elapsed, restartGame);
            savePlayResult(score, stopwatch.elapsed, widget.levelNumber);
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
    //ให้ Level 1 สามารถทะลุขอบได้
    if (widget.levelNumber == 1) {
      if (snakePosition.sublist(1).contains(snakeHead)) return true; //ชนตัวเอง
    } else {
      if (borderList.contains(snakeHead)) return true; //ชนขอบ
      if (snakePosition.sublist(1).contains(snakeHead)) return true; //ชนตัวเอง
      if (obstacles.contains(snakeHead)) return true; //ชนสิ่งกีดขวาง
    }
    return false;
  }

  void generateFood() {
    int newFoodPos;
    do {
      newFoodPos = Random().nextInt(row * column);
    } while (borderList.contains(newFoodPos) || obstacles.contains(newFoodPos) || snakePosition.contains(newFoodPos));

    foodPosition = newFoodPos;
  }

  Future<void> updateSnake(LevelConfig config) async {
    if (isGamePause) return;

    int newHead;
    switch (direction) {
      case Direction.up:
        newHead = snakeHead - column;
        if (widget.levelNumber == 1 && newHead < 0) newHead = snakeHead + (row - 1) * column; //ทะลุบน ไป ล่าง
        break;
      case Direction.down:
        newHead = snakeHead + column;
        if (widget.levelNumber == 1 && newHead >= row * column) newHead = snakeHead % column; //ทะลุล่าง ไป บน
        break;
      case Direction.right:
        newHead = snakeHead + 1;
        if (widget.levelNumber == 1 && snakeHead % column == column -1) newHead = snakeHead - (column - 1); //ทะลุขวา ไป ซ้าย
        break;
      case Direction.left:
        newHead = snakeHead - 1;
        if (widget.levelNumber == 1 && snakeHead % column == 0) newHead = snakeHead + (column - 1); //ทะลุซ้าย ไป ขวา
        break;
    }

    if (borderList.contains(newHead) || snakePosition.contains(newHead) || obstacles.contains(newHead)) {
      stopwatch.stop();  //หยุดเวลา
      setState(() {
        isGamePause = true;
      });

      if (!hasSavedResult) {
        hasSavedResult = true;
        //แสดง GameOver ทันที
        ShowGameOver.showGameOver(context, widget.levelNumber, score, stopwatch.elapsed, restartGame);
        savePlayResult(score, stopwatch.elapsed, widget.levelNumber);
      }
      return;
    }

    //ถ้ายังไม่ชน
    setState(() {
      snakePosition.insert(0, newHead);

      if (newHead  == foodPosition) {
        score++;
        generateFood();

        if (score == config.requiredScore && !hasSavedResult) {
          hasSavedResult = true;
          stopwatch.stop();
          isGamePause = true;
          savePlayResult(score, stopwatch.elapsed, widget.levelNumber);

          if (widget.levelNumber == 5) {
            LevelCongratulation.showLevelCongratulationDialog(context);
          } else {
            LevelPass.showLevelPassDialog(context, stopwatch.elapsed, restartGame, widget.levelNumber, () => goNextLevel(config));
          }
        }
      } else {
        snakePosition.removeLast();
      }

      snakeHead = snakePosition.first;
      levelSnakePositions[widget.levelNumber] = List.from(snakePosition); //บันทึกตำแหน่งงูที่อัปเดต
    });
  }

  void goNextLevel(LevelConfig config) {
    if (config.nextLevel != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SnakeGameLevel(levelNumber: config.nextLevel!),
        ),
      );
    }
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
                      Text("🧩 Level: ${widget.levelNumber}",
                          style: const TextStyle(fontSize: 16, fontFamily: 'Silkscreen', color: Colors.white)),
                      Text("🏆 Score: $score",
                          style: const TextStyle(fontSize: 16, fontFamily: 'Silkscreen', color: Colors.white)),
                    ],
                  ),
                  _buildTime(),
                ],
              ),
            ),
            Expanded(child: _buildGameView()),
            _buildPause(),
            _buildGameControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameView() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: column),
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.all(1),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7), color: fillBoxColor(index)),
        );
      },
      itemCount: row * column,
    );
  }

  Widget _buildGameControls() {
    return Container(
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(onPressed: () {
              if (direction != Direction.down) direction = Direction.up;
            }, icon: const Icon(Icons.arrow_circle_up), iconSize: 80, color: Colors.green,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: () {
                  if (direction != Direction.right) direction = Direction.left;
                }, icon: const Icon(Icons.arrow_circle_left_outlined), iconSize: 80, color: Colors.green,
              ),
              SizedBox(width: 100),
              IconButton(onPressed: () {
                  if (direction != Direction.left) direction = Direction.right;
                }, icon: const Icon(Icons.arrow_circle_right_outlined), iconSize: 80, color: Colors.green,
              ),
            ],
          ),
          IconButton(onPressed: () {
              if (direction != Direction.up) direction = Direction.down;
            }, icon: const Icon(Icons.arrow_circle_down_outlined), iconSize: 80, color: Colors.green,
          ),
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
      style: const TextStyle(fontSize: 16, fontFamily: 'Silkscreen', color: Colors.white),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    } else if (foodPosition != null && index == foodPosition) {
      return Colors.redAccent; //อาหาร
    } else if (obstacles.contains(index)) {
      return Colors.brown; //สิ่งกีดขวาง
    }
    return Colors.grey.withValues(alpha: 0.3);
  }

  makeBorder() {
    borderList.clear();
    if (widget.levelNumber != 1) { //level 1 จะไม่โชว์ขอบ
      for (int i = 0; i < column; i++) { //บน
        if (!borderList.contains(i)) borderList.add(i);
      }
      for (int i = 0; i < row * column; i = i + column) { //ซ้าย
        if (!borderList.contains(i)) borderList.add(i);
      }
      for (int i = column - 1; i < row * column; i = i + column) { //ขวา
        if (!borderList.contains(i)) borderList.add(i);
      }
      for (int i = (row * column) - column; i < row * column;
      i = i + 1) { //ล่าง
        if (!borderList.contains(i)) borderList.add(i);
      }
    }
  }

  Future<void> savePlayResult(int score, Duration time, int level) async {
    try {
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

class LevelConfig {
  final List<int> obstacles;
  final int? nextLevel;
  final int requiredScore;
  final List<int> initialSnakePosition;

  LevelConfig({
    required this.obstacles,
    required this.nextLevel,
    required this.requiredScore,
    required this.initialSnakePosition
  });
}
