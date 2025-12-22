import 'dart:async'; // CRITICAL: Added for Timer
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';

class LuckyWheelPage extends StatefulWidget {
  const LuckyWheelPage({super.key});

  @override
  State<LuckyWheelPage> createState() => _LuckyWheelPageState();
}

class _LuckyWheelPageState extends State<LuckyWheelPage> with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  late AnimationController _controller;
  late Animation<double> _animation;
  ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  bool _isLedOn = false;
  Timer? _timer;

  List<Map<String, dynamic>> prizes = [];
  bool isLoading = true;
  bool isSpinning = false;
  double selectedPrizeValue = 0;
  String selectedPrizeLabel = '';
  int spinsAvailable = 0;

  // Premium casino colors
  static const List<Color> wheelColors = [
    Color(0xFFC62828), // Deep Red
    Color(0xFF283593), // Deep Blue
    Color(0xFF2E7D32), // Forest Green
    Color(0xFFF9A825), // Golden Yellow
    Color(0xFF6A1B9A), // Royal Purple
    Color(0xFF00838F), // Teal
    Color(0xFFEF6C00), // Deep Orange
    Color(0xFF37474F), // Dark Grey
  ];

  @override
  void initState() {
    super.initState();
    _loadPrizesAndSpins();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500), // Casino-style duration
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutExpo, // Premium casino feel
    );

    // Start LED animation
    _timer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() => _isLedOn = !_isLedOn);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadPrizesAndSpins() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final userData = await supabase
            .from('users')
            .select('spins_available')
            .eq('id', user.id)
            .single();

        final prizesData = await supabase
            .from('wheel_prizes')
            .select()
            .order('probability', ascending: false);

        setState(() {
          spinsAvailable = (userData['spins_available'] ?? 0) as int;
          prizes = List<Map<String, dynamic>>.from(prizesData);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading data: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _spinWheel() async {
    if (isSpinning || prizes.isEmpty || spinsAvailable <= 0) return;

    setState(() => isSpinning = true);
    HapticFeedback.mediumImpact(); // Tactile feedback on spin start
    await _updateSpins(spinsAvailable - 1);

    final random = Random();
    final randomValue = random.nextDouble() * 100;

    double cumulativeProbability = 0;
    Map<String, dynamic>? selectedPrize;

    for (var prize in prizes) {
      cumulativeProbability += (prize['probability'] as num).toDouble();
      if (randomValue <= cumulativeProbability) {
        selectedPrize = prize;
        break;
      }
    }

    if (selectedPrize != null) {
      setState(() {
        selectedPrizeValue = (selectedPrize!['value'] as num).toDouble();
        selectedPrizeLabel = selectedPrize!['label'] as String;
      });

      final prizeIndex = prizes.indexOf(selectedPrize!);
      final totalPrizes = prizes.length;
      final segmentAngle = 360 / totalPrizes;
      
      // CRITICAL: -90 adjustment for 12 o'clock pointer alignment
      final targetAngle =
          360 * 5 + (segmentAngle * prizeIndex) - (segmentAngle / 2) - 90;

      _animation = Tween<double>(
        begin: 0,
        end: targetAngle,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutExpo),
      ));

      _controller.forward().then((_) async {
        if (selectedPrizeValue > 0) {
          _confettiController.play();
          await _addPrizeToBalance(selectedPrizeValue);
        }

        HapticFeedback.heavyImpact(); // Tactile feedback on result
        _showResultDialog(selectedPrizeLabel, selectedPrizeValue);
        setState(() => isSpinning = false);
      });
    }
  }

  Future<void> _updateSpins(int newSpinCount) async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase
            .from('users')
            .update({'spins_available': newSpinCount})
            .eq('id', user.id);
        setState(() => spinsAvailable = newSpinCount);
      }
    } catch (e) {
      print("Error updating spins: $e");
    }
  }

  Future<void> _addPrizeToBalance(double amount) async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final userData = await supabase
            .from('users')
            .select('balance')
            .eq('id', user.id)
            .single();

        final currentBalance = (userData['balance'] as num).toDouble();
        final newBalance = currentBalance + amount;

        await supabase
            .from('users')
            .update({'balance': newBalance})
            .eq('id', user.id);
      }
    } catch (e) {
      print("Error updating balance: $e");
    }
  }

  void _showResultDialog(String label, double value) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 25,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                value > 0 ? Icons.celebration : Icons.sentiment_neutral,
                size: 70,
                color: value > 0 ? Colors.white : Colors.black,
              ),
              const SizedBox(height: 25),
              Text(
                value > 0 ? "🎉 JACKPOT! " : "Better Luck Next Time!",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 5, offset: Offset(2, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Text(
                      "You won:",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: value > 0 ? Colors.white : Colors.yellow,
                        shadows: [
                          Shadow(color: Colors.black, blurRadius: 8, offset: const Offset(2, 2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (value > 0) ...[
                const SizedBox(height: 15),
                Text(
                  "₹$value has been added to your balance!",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 25),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.white, Colors.grey.shade200],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Text(
                    "CONTINUE",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "LUCKY WHEEL",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F0F0F),
              Color(0xFF1A1A1A),
              Color(0xFF0F0F0F),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            Opacity(
              opacity: 0.05,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage("https://www.transparenttextures.com/patterns/dark-stripes.png"),
                    repeat: ImageRepeat.repeat,
                  ),
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Spins Counter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.casino, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            "SPINS: $spinsAvailable",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 3, offset: Offset(1, 1)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Premium Wheel Container
                    Container(
                      padding: const EdgeInsets.all(15), // Golden ring padding
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFD700),
                            Color(0xFFFFA000),
                            Color(0xFFFFD700),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.8),
                            blurRadius: 25,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glowing lights
                          ...List.generate(24, (index) {
                            final angle = (2 * pi / 24) * index;
                            final radius = 165.0;
                            return Positioned(
                              left: 165 + cos(angle) * radius,
                              top: 165 + sin(angle) * radius,
                              child: AnimatedOpacity(
                                opacity: _isLedOn ? 1.0 : 0.3,
                                duration: const Duration(milliseconds: 300),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.yellowAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.yellowAccent,
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),

                          // Wheel Container
                          Container(
                            height: 330,
                            width: 330,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Wheel with premium painting
                                AnimatedBuilder(
                                  animation: _animation,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle: _animation.value * (pi / 180),
                                      child: child,
                                    );
                                  },
                                  child: Container(
                                    width: 320,
                                    height: 320,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black,
                                    ),
                                    child: CustomPaint(
                                      painter: _PremiumWheelPainter(prizes: prizes, wheelColors: wheelColors),
                                    ),
                                  ),
                                ),

                                // Inner decorative ring
                                Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Premium Triangle Pointer
                          Positioned(
                            top: 0,
                            child: CustomPaint(
                              size: const Size(40, 50),
                              painter: _TrianglePointerPainter(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 50),

                    // Premium SPIN Button
                    GestureDetector(
                      onTap: spinsAvailable > 0 && !isSpinning ? _spinWheel : null,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.6),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isSpinning
                              ? const SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.casino,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "SPIN",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black,
                                            blurRadius: 5,
                                            offset: const Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumWheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> prizes;
  final List<Color> wheelColors;

  _PremiumWheelPainter({
    required this.prizes,
    required this.wheelColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (prizes.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * pi / prizes.length;

    for (int i = 0; i < prizes.length; i++) {
      final startAngle = i * segmentAngle - pi / 2;

      final rect = Rect.fromCircle(center: center, radius: radius);

      // Gradient for depth
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            wheelColors[i % wheelColors.length].withOpacity(0.95),
            wheelColors[i % wheelColors.length].withOpacity(0.75),
          ],
        ).createShader(rect);

      canvas.drawArc(rect, startAngle, segmentAngle, true, paint);

      // Divider line
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawArc(rect, startAngle, segmentAngle, true, borderPaint);

      // Text
      final textAngle = startAngle + segmentAngle / 2;
      final textRadius = radius * 0.65;

      final textPainter = TextPainter(
        text: TextSpan(
          text: prizes[i]['label'].toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 4),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(
        center.dx + cos(textAngle) * textRadius,
        center.dy + sin(textAngle) * textRadius,
      );
      canvas.rotate(textAngle + pi / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class _TrianglePointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFF0000),
          Color(0xFFFF4500),
          Color(0xFFFF0000),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawShadow(path, Colors.black, 4, true);
    canvas.drawPath(path, paint);

    // Add shine effect
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final shinePath = Path()
      ..moveTo(size.width * 0.3, size.height * 0.3)
      ..lineTo(size.width * 0.7, size.height * 0.3)
      ..lineTo(size.width * 0.6, size.height * 0.7)
      ..lineTo(size.width * 0.4, size.height * 0.7)
      ..close();

    canvas.drawPath(shinePath, shinePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
