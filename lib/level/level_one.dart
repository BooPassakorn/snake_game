import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:snake_game/widget/show_dialog.dart';

class LevelOne extends StatefulWidget {
  const LevelOne({super.key});

  @override
  State<LevelOne> createState() => _LevelOneState();
}

enum Direction {up, down, left, right}

class _LevelOneState extends State<LevelOne> {

  int row = 30;
  int column = 30;
  List<int> borderList = [];
  List<int> snakePosition = [];
  int snakeHead = 0;
  int score = 0;
  late Direction direction;
  late int foodPosition;

  @override
  void initState() {
    startGame();
    super.initState();
  }

  void startGame() {

    setState(() {
      score = 0;
    });

    makeBorder();
    generateFood();
    direction = Direction.right;
    snakePosition = [65,63,64];
    snakeHead = snakePosition.first;
    Timer.periodic(const Duration(milliseconds: 300), (timer){
      updateSnake();
      if (checkCollision()){
        timer.cancel();
        ShowGameOver.showGameOver(context, score, startGame);
      }
    });
  }


  bool checkCollision() { //ตรวจการชน
    if (borderList.contains(snakeHead)) return true; //ชนขอบ
    if (snakePosition.sublist(1).contains(snakeHead)) return true; //ชนตัวเอง
    return false;
  }

  void generateFood() {
    foodPosition = Random().nextInt(row*column);
    if(borderList.contains(foodPosition)) {
      generateFood();
    }
  }

  void updateSnake() {
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
    } else {
      snakePosition.removeLast();
    }

    snakeHead = snakePosition.first;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.blueGrey,
        body: Column(
          children: [
            Text("Score : $score"),
            Expanded(child: _buildGameView()), _buildGameControls()
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
      padding: const EdgeInsets.all(20),
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

  Color fillBoxColor(int index) {
    if(borderList.contains(index))
      return Colors.yellow;
    else{
      if(snakePosition.contains(index)) {
        if(snakeHead == index) {
          return Colors.greenAccent;
        } else {
          return Colors.green.shade400;
        }
      } else {
        if (index == foodPosition) {
          return Colors.red;
        }
      }
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
}
