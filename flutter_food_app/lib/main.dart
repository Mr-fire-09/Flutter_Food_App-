import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

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

class _KnifeVegetableGameState extends State<KnifeVegetableGame>
    with SingleTickerProviderStateMixin {
  double knifeX = 0;
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
  late ConfettiController _confettiController;
  int combo = 0;
  Timer? comboResetTimer;
  double knifeAngle = -pi / 4;
  bool knifeMoving = false;
  List<Offset> cutParticles = [];
  Timer? particleTimer;
  late AnimationController _animationController;
  double backgroundOffset = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _animationController.addListener(() {
      setState(() {
        backgroundOffset = _animationController.value * 100;
      });
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    comboResetTimer?.cancel();
    particleTimer?.cancel();
    _confettiController.dispose();
    _animationController.dispose();
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

      combo = 0;
      cutParticles = [];
    });

    addVegetable();

    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!isGameRunning || isPaused) return;

      setState(() {
        // Update particle positions
        cutParticles =
            cutParticles
                .map((particle) => Offset(particle.dx, particle.dy + 0.01))
                .where((particle) => particle.dy < 1.0)
                .toList();

        // Update vegetables
        for (int i = 0; i < vegPositions.length; i += 2) {
          vegPositions[i + 1] += speed;

          // Cutting detection
          if ((vegPositions[i + 1] >= 0.7 && vegPositions[i + 1] <= 0.8)) {
            if ((vegPositions[i] - knifeX).abs() < 0.15) {
              // Successful cut
              score += 10;
              combo++;
              if (combo % 5 == 0) {
                score += 5; // Combo bonus
                _confettiController.play();
              }

              // Add cutting particles
              final particleCount = Random().nextInt(5) + 5;
              for (int j = 0; j < particleCount; j++) {
                cutParticles.add(
                  Offset(
                    vegPositions[i] + Random().nextDouble() * 0.1 - 0.05,
                    vegPositions[i + 1] + Random().nextDouble() * 0.1 - 0.05,
                  ),
                );
              }

              // Reset combo timer
              comboResetTimer?.cancel();
              comboResetTimer = Timer(const Duration(seconds: 2), () {
                setState(() {
                  combo = 0;
                });
              });

              speed += 0.005;
              vegPositions.removeAt(i);
              vegPositions.removeAt(i);
              vegTypes.removeAt(i ~/ 2);
              addVegetable();
              return;
            }
          }

          // Missed vegetable
          if (vegPositions[i + 1] > 1.2) {
            lives--;
            combo = 0;
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

        // Add more vegetables as score increases
        if (score > 30 && Random().nextDouble() < 0.02) {
          addVegetable();
        }
      });
    });

    particleTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!isGameRunning || isPaused) return;
      setState(() {});
    });
  }

  void addVegetable() {
    final random = Random();
    vegPositions.add(random.nextDouble() * 2 - 1);
    vegPositions.add(-0.2 - random.nextDouble() * 0.3);
    final types = [
      'carrot',
      'tomato',
      'eggplant',
      'broccoli',
      'pepper',
      'mushroom',
    ];
    vegTypes.add(types[random.nextInt(types.length)]);
  }

  void endGame() {
    setState(() {
      isGameRunning = false;
      isGameOver = true;
      if (score > highScore) {
        highScore = score;
        _confettiController.play();
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
            backgroundColor: Colors.green[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.green, width: 3),
            ),
            title: const Text(
              "Game Over!",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            content: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, size: 50, color: Colors.amber),
                  const SizedBox(height: 16),
                  Text(
                    "Your Score: $score",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "High Score: $highScore",
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (score == highScore && score > 0)
                    const Text(
                      "New Record!",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  startGame();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Play Again",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
    );
  }

  void togglePause() {
    setState(() {
      isPaused = !isPaused;
      if (isPaused) {
        gameTimer?.cancel();
        _animationController.stop();
      } else {
        startGame();
        _animationController.repeat();
      }
    });
  }

  void moveKnife(double direction) {
    if (!isGameRunning || isPaused) return;

    setState(() {
      knifeX += direction * 0.2;
      knifeX = knifeX.clamp(-1.0, 1.0);
      knifeMoving = true;
      knifeAngle = -pi / 4 + direction * 0.1;
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          knifeAngle = -pi / 4;
          knifeMoving = false;
        });
      }
    });
  }

  Widget getVegetableIcon(String type) {
    IconData icon;
    Color color;
    double size = 40;

    switch (type) {
      case 'carrot':
        icon = Icons.emoji_food_beverage;
        color = Colors.orange;
        break;
      case 'tomato':
        icon = Icons.emoji_food_beverage;
        color = Colors.red;
        break;
      case 'eggplant':
        icon = Icons.emoji_food_beverage;
        color = Colors.purple;
        size = 45;
        break;
      case 'broccoli':
        icon = Icons.emoji_food_beverage;
        color = Colors.green;
        size = 42;
        break;
      case 'pepper':
        icon = Icons.emoji_food_beverage;
        color = Colors.redAccent;
        size = 38;
        break;
      case 'mushroom':
        icon = Icons.emoji_food_beverage;
        color = Colors.brown;
        size = 36;
        break;
      default:
        icon = Icons.emoji_food_beverage;
        color = Colors.red;
    }

    return Transform.translate(
      offset: Offset(0, -10),
      child: Icon(icon, size: size, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen[50],
      appBar: AppBar(
        title: const Text(
          "🥕 Veggie Cutter 🍅",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        elevation: 10,
        shadowColor: Colors.green[900],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          if (isGameRunning && !isGameOver)
            IconButton(
              icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, size: 28),
              onPressed: togglePause,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Animated background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.lightGreen[100]!,
                    Colors.lightGreen[50]!,
                    Colors.lightGreen[100]!,
                  ],
                ),
              ),
            ),
          ),

          // Subtle pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Transform.translate(
                offset: Offset(backgroundOffset, 0),
                child: Image.asset(
                  'assets/veggie_pattern.png', // You can create this asset
                  repeat: ImageRepeat.repeat,
                  fit: BoxFit.none,
                ),
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),

          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildScoreCard("SCORE", "$score", Colors.green),
                      if (combo > 0)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: Text(
                            "COMBO x$combo",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      _buildScoreCard(
                        "HIGH SCORE",
                        "$highScore",
                        Colors.orange,
                      ),
                      _buildScoreCard("LIVES", "❤️" * lives, Colors.red),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: Stack(
                  children: [
                    // Cutting board with shine effect
                    Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.height * 0.6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFA67C52),
                              const Color(0xFF8B4513),
                              const Color(0xFF5D2906),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.brown.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 3,
                              offset: const Offset(0, 5),
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 5,
                              spreadRadius: 1,
                              offset: const Offset(-2, -2),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFA0522D),
                            width: 3,
                          ),
                        ),
                      ),
                    ),

                    // Vegetables with smooth animations
                    for (int i = 0; i < vegPositions.length; i += 2)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 16),
                        curve: Curves.easeOut,
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
                        child: Column(
                          children: [
                            // Shadow with animation
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              width: 30,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 5,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            // Vegetable with slight bounce
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              transform:
                                  Matrix4.identity()..translate(
                                    0.0,
                                    (vegPositions[i + 1] >= 0.7 &&
                                            vegPositions[i + 1] <= 0.8)
                                        ? -5.0
                                        : 0.0,
                                  ),
                              child: getVegetableIcon(vegTypes[i ~/ 2]),
                            ),
                          ],
                        ),
                      ),

                    // Cutting particles
                    for (final particle in cutParticles)
                      Positioned(
                        left:
                            (particle.dx + 1) *
                                MediaQuery.of(context).size.width /
                                2 -
                            5,
                        top:
                            (particle.dy + 1) *
                                MediaQuery.of(context).size.height /
                                2 -
                            5,
                        child: Transform.rotate(
                          angle: Random().nextDouble() * pi * 2,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width: 8 + Random().nextDouble() * 4,
                            height: 8 + Random().nextDouble() * 4,
                            decoration: BoxDecoration(
                              color: Colors.green[700]!.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),

                    // Knife with smooth movement
                    Align(
                      alignment: Alignment(knifeX, 0.85),
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: knifeAngle / (2 * pi),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          transform:
                              Matrix4.identity()
                                ..translate(0.0, knifeMoving ? -10.0 : 0.0),
                          child: const Icon(
                            Icons.cut,
                            size: 70,
                            color: Colors.grey,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 10,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Start screen
                    if (!isGameRunning && !isGameOver)
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "🍅 Veggie Cutter 🥦",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black12,
                                      blurRadius: 5,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Slice the falling vegetables!\nUse the buttons to move the knife.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton.icon(
                                onPressed: startGame,
                                icon: const Icon(Icons.play_arrow, size: 28),
                                label: const Text(
                                  "START GAME",
                                  style: TextStyle(fontSize: 20),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 8,
                                  shadowColor: Colors.green[900],
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "High Score:",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                "$highScore",
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Paused overlay
                    if (isPaused)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.pause,
                                size: 80,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "PAUSED",
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 10,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Tap the play button to continue",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Controls with touch feedback
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(Icons.arrow_left, () => moveKnife(-1)),
                    _buildControlButton(Icons.arrow_right, () => moveKnife(1)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(1, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTapDown: (_) => onPressed(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[400]!, Colors.green[700]!],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.green[800]!,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 30, color: Colors.white),
      ),
    );
  }
}
