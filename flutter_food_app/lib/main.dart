import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: KnifeVegetableGame(),
    ),
  );
}

class KnifeVegetableGame extends StatefulWidget {
  const KnifeVegetableGame({super.key});

  @override
  State<KnifeVegetableGame> createState() => _KnifeVegetableGameState();
}

class _KnifeVegetableGameState extends State<KnifeVegetableGame> {
  double knifeX = 0;
  double vegY = -1;
  double vegX = 0;
  int score = 0;
  int highScore = 0;
  bool isGameRunning = false;
  bool isGameOver = false;
  double speed = 0.05;
  Timer? gameTimer;
  List<double> vegPositions = [];
  List<String> vegTypes = [];
  int lives = 3;
  bool isPaused = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void startGame() {
    setState(() {
      isGameRunning = true;
      isGameOver = false;
      score = 0;
      lives = 3;
      speed = 0.05;
      knifeX = 0;
      vegPositions = [];
      vegTypes = [];
      isPaused = false;
    });

    addVegetable();

    gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!isGameRunning || isPaused) return;

      setState(() {
        for (int i = 0; i < vegPositions.length; i += 2) {
          vegPositions[i + 1] += speed;

          if ((vegPositions[i + 1] >= 0.7 && vegPositions[i + 1] <= 0.8)) {
            if ((vegPositions[i] - knifeX).abs() < 0.15) {
              score += 10;
              speed += 0.005;
              vegPositions.removeAt(i);
              vegPositions.removeAt(i);
              vegTypes.removeAt(i ~/ 2);
              addVegetable();
              return;
            }
          }

          if (vegPositions[i + 1] > 1.2) {
            lives--;
            vegPositions.removeAt(i);
            vegPositions.removeAt(i);
            vegTypes.removeAt(i ~/ 2);
            if (lives <= 0) {
              endGame();
              return;
            }
            addVegetable();
          }
        }

        if (score > 30 && Random().nextDouble() < 0.02) {
          addVegetable();
        }
      });
    });
  }

  void addVegetable() {
    final random = Random();
    vegPositions.add(random.nextDouble() * 2 - 1);
    vegPositions.add(-1);
    final types = ['carrot', 'tomato', 'eggplant', 'broccoli'];
    vegTypes.add(types[random.nextInt(types.length)]);
  }

  void endGame() {
    setState(() {
      isGameRunning = false;
      isGameOver = true;
      if (score > highScore) {
        highScore = score;
      }
    });
    gameTimer?.cancel();
    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text(
              "Game Over!",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Your Score: $score",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  "High Score: $highScore",
                  style: const TextStyle(fontSize: 18, color: Colors.orange),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  startGame();
                },
                child: const Text("Play Again"),
              ),
            ],
          ),
    );
  }

  void togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
  }

  void moveKnife(double direction) {
    if (!isGameRunning || isPaused) return;
    setState(() {
      knifeX += direction * 0.2;
      knifeX = knifeX.clamp(-1.0, 1.0);
    });
  }

  Widget getVegetableIcon(String type) {
    switch (type) {
      case 'carrot':
        return const Icon(
          Icons.emoji_food_beverage,
          size: 40,
          color: Colors.orange,
        );
      case 'tomato':
        return const Icon(
          Icons.emoji_food_beverage,
          size: 40,
          color: Colors.red,
        );
      case 'eggplant':
        return const Icon(
          Icons.emoji_food_beverage,
          size: 40,
          color: Colors.purple,
        );
      case 'broccoli':
        return const Icon(
          Icons.emoji_food_beverage,
          size: 40,
          color: Colors.green,
        );
      default:
        return const Icon(
          Icons.emoji_food_beverage,
          size: 40,
          color: Colors.red,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text(
          "Veggie Cutter",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        actions: [
          if (isGameRunning && !isGameOver)
            IconButton(
              icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
              onPressed: togglePause,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const Text(
                      "SCORE",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      "$score",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      "HIGH SCORE",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      "$highScore",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      "LIVES",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      "$lives",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                for (int i = 0; i < vegPositions.length; i += 2)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 50),
                    left:
                        (vegPositions[i] + 1) *
                            MediaQuery.of(context).size.width /
                            2 -
                        20,
                    top:
                        (vegPositions[i + 1] + 1) *
                            MediaQuery.of(context).size.height /
                            2 -
                        20,
                    child: getVegetableIcon(vegTypes[i ~/ 2]),
                  ),
                Align(
                  alignment: Alignment(knifeX, 0.85),
                  child: Transform.rotate(
                    angle: -pi / 4,
                    child: const Icon(
                      Icons.restaurant,
                      size: 60,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                if (!isGameRunning && !isGameOver)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Veggie Cutter",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: startGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 16,
                            ),
                          ),
                          child: const Text(
                            "START GAME",
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isPaused)
                  const Center(
                    child: Text(
                      "PAUSED",
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => moveKnife(-1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                  ),
                  child: const Icon(
                    Icons.arrow_left,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => moveKnife(1),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                  ),
                  child: const Icon(
                    Icons.arrow_right,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
