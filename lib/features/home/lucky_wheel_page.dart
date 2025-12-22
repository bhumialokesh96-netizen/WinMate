import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:winmate/utils/style.dart'; // Custom styling import

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
  
  List<Map<String, dynamic>> prizes = [];
  bool isLoading = true;
  bool isSpinning = false;
  double selectedPrizeValue = 0;
  String selectedPrizeLabel = '';
  int spinsAvailable = 0;
  
  // Premium wheel design with iPhone image background
  static const List<Color> wheelColors = [
    Color(0xFF3ED598), // Luxury Green
    Color(0xFFFFD600), // Gold
    Color(0xFFFA5C7C), // Rose Gold
    Color(0xFF6C5DD3), // Deep Purple
    Color(0xFFFF754C), // Orange
    Color(0xFF00E1FF), // Cyan
    Color(0xFFFFFFFF), // White
    Color(0xFF000000), // Black
  ];

  @override
  void initState() {
    super.initState();
    _loadPrizesAndSpins();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadPrizesAndSpins() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Get spins available
        final userData = await supabase
            .from('users')
            .select('spins_available')
            .eq('id', user.id)
            .single();
        
        // Load prizes
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
    
    // Reduce spin count
    await _updateSpins(spinsAvailable - 1);

    // Random prize selection
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
      
      // Animation setup
      final prizeIndex = prizes.indexOf(selectedPrize!);
      final totalPrizes = prizes.length;
      final segmentAngle = 360 / totalPrizes;
      final targetAngle = 360 * 5 + (segmentAngle * prizeIndex) - (segmentAngle / 2);
      
      _animation = Tween<double>(
        begin: 0,
        end: targetAngle,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.decelerate),
      ));
      
      _controller.forward().then((_) async {
        if (selectedPrizeValue > 0) {
          _confettiController.play();
          await _addPrizeToBalance(selectedPrizeValue);
        }
        
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
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value > 0 ? Icons.celebration : Icons.sentiment_neutral,
              size: 60,
              color: value > 0 ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 20),
            Text(
              value > 0 ? "🎉 Congratulations! " : "Better Luck Next Time!",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("You won:", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: value > 0 ? Colors.green : Colors.orange,
              ),
            ),
            if (value > 0) ...[
              const SizedBox(height: 5),
              Text(
                "₹$value has been added to your balance!",
                style: const TextStyle(fontSize: 14, color: Colors.green),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: value > 0 ? Colors.green : Colors.orange,
                minimumSize: const Size(150, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("OK", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lucky Wheel", style: TextStyle(color: Colors.white)),
        backgroundColor: AppStyle.primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // iPhone background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assests/iphone_background.jpg"), // Add iPhone image to assets
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Spins Remaining
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.casino, color: Colors.white, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          "Spins Available: $spinsAvailable",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Wheel Container
                  Container(
                    height: 300,
                    width: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Wheel
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _animation.value * (pi / 180),
                              child: child,
                            );
                          },
                          child: Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: wheelColors,
                                stops: List.generate(wheelColors.length, (i) => i / wheelColors.length),
                              ),
                            ),
                            child: CustomPaint(
                              painter: _WheelPainter(prizes: prizes, wheelColors: wheelColors),
                            ),
                          ),
                        ),

                        // Center Circle with iPhone icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.black, Colors.grey.shade800],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Icon(
                                Icons.phone_iphone,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),

                        // Pointer
                        Positioned(
                          top: 0,
                          child: Container(
                            width: 30,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Spin Button
                  SizedBox(
                    width: 200,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: spinsAvailable > 0 && !isSpinning ? _spinWheel : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyle.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                      ),
                      child: isSpinning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.casino, size: 24),
                                const SizedBox(width: 10),
                                Text("SPIN WHEEL", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 20,
              minBlastForce: 10,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> prizes;
  final List<Color> wheelColors;

  _WheelPainter({required this.prizes, required this.wheelColors});

  @override
  void paint(Canvas canvas, Size size) {
    if (prizes.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * pi / prizes.length;

    for (int i = 0; i < prizes.length; i++) {
      final startAngle = i * segmentAngle;
      final sweepAngle = segmentAngle;

      // Draw segment
      final segmentPaint = Paint()
        ..color = wheelColors[i % wheelColors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        segmentPaint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      // Draw prize text
      final textAngle = startAngle + sweepAngle / 2;
      final textRadius = radius * 0.7;
      final textX = center.dx + textRadius * cos(textAngle);
      final textY = center.dy + textRadius * sin(textAngle);

      final textSpan = TextSpan(
        text: prizes[i]['label'].toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1))],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final textOffset = Offset(
        textX - textPainter.width / 2,
        textY - textPainter.height / 2,
      );

      canvas.save();
      canvas.translate(textOffset.dx, textOffset.dy);
      canvas.rotate(textAngle + pi / 2);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
