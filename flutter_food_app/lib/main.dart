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

class _KnifeVegetableGameState extends State<KnifeVegetableGame> {
  double knifeX = 0;
  int score = 0;
  int highScore = 0;
  bool isGameRunning = false;
  bool isGameOver = false;
  double speed = 0.03;
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

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    comboResetTimer?.cancel();
    particleTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void startGame() {
    setState(() {
      isGameRunning = true;
      isGameOver = false;
      score = 0;
      lives = 3;
      speed = 0.03;
      knifeX = 0;
      vegPositions = [];
      vegTypes = [];
      isPaused = false;
      combo = 0;
      cutParticles = [];
    });

    addVegetable();

    gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
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

    // Particle animation timer
    particleTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!isGameRunning || isPaused) return;
      setState(() {});
    });
  }

  void addVegetable() {
    final random = Random();
    vegPositions.add(random.nextDouble() * 2 - 1);
    vegPositions.add(
      -0.2 - random.nextDouble() * 0.3,
    ); // Stagger starting positions
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
      } else {
        startGame();
      }
    });
  }

  void moveKnife(double direction) {
    if (!isGameRunning || isPaused) return;

    setState(() {
      knifeX += direction * 0.2;
      knifeX = knifeX.clamp(-1.0, 1.0);
      knifeMoving = true;

      // Add a little tilt animation when moving
      knifeAngle = -pi / 4 + direction * 0.1;
    });

    // Reset knife angle after movement
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

    return Icon(icon, size: size, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
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
          // Background pattern
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage(
                    'assets/wood_texture.jpg',
                  ), // You'd need to add this asset
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.green[50]!.withOpacity(0.2),
                    BlendMode.dstOver,
                  ),
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
                        Container(
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
                    // Cutting board
                    Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.height * 0.6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B4513), // Wooden color
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.brown.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 3,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFA0522D),
                            width: 3,
                          ),
                        ),
                      ),
                    ),

                    // Vegetables
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
                        child: Column(
                          children: [
                            // Shadow
                            Container(
                              width: 30,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 5,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            getVegetableIcon(vegTypes[i ~/ 2]),
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
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.green[700],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                    // Knife
                    Align(
                      alignment: Alignment(knifeX, 0.85),
                      child: Transform.rotate(
                        angle: knifeAngle,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          transform:
                              Matrix4.identity()
                                ..translate(0.0, knifeMoving ? -5.0 : 0.0),
                          child: const Icon(
                            Icons.restaurant,
                            size: 70,
                            color: Colors.blueGrey,
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
                        child: Container(
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
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pause, size: 80, color: Colors.white),
                              SizedBox(height: 20),
                              Text(
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
                              SizedBox(height: 10),
                              Text(
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

              // Controls
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
      onTapUp: (_) => setState(() {}),
      onTapCancel: () => setState(() {}),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green,
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
