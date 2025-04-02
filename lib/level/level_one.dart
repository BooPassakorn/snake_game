import 'dart:async';

import 'package:flutter/material.dart';

class LevelOne extends StatefulWidget {
  const LevelOne({super.key});

  @override
  State<LevelOne> createState() => _LevelOneState();
}

class _LevelOneState extends State<LevelOne> {

  int row = 30;
  int column = 30;
  List<int> borderList = [];
  List<int> snakePosition = [];
  int snakeHead = 0;
  int score = 0;

  @override
  void initState() {
    startGame();
    super.initState();
  }

  void startGame() {
    makeBorder();
    snakePosition = [63,64,65];
    snakeHead = snakePosition.first;
    Timer.periodic(const Duration(milliseconds: 300), (timer){
      updateSnake();
    });
  }

  void updateSnake() {
    setState(() {
      snakePosition.insert(0, snakeHead + 1);
    });
    snakePosition.removeLast();
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
          IconButton(onPressed: (){}, icon: const Icon(Icons.arrow_circle_up), iconSize: 80),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: (){}, icon: const Icon(Icons.arrow_circle_left_outlined), iconSize: 80),
              SizedBox(width: 100),
              IconButton(onPressed: (){}, icon: const Icon(Icons.arrow_circle_right_outlined), iconSize: 80),
            ],
          ),
          IconButton(onPressed: (){}, icon: const Icon(Icons.arrow_circle_down_outlined), iconSize: 80),
        ],
      ),
    );
  }

  Color fillBoxColor(int index) {
    if(borderList.contains(index))
      return Colors.yellow;
    else{
      if(snakePosition.contains(index)) {
        return Colors.green;
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
