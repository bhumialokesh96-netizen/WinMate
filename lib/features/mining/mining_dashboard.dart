import 'dart:async';
import 'dart:math'; // <-- ADD THIS IMPORT for cos and sin functions
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MiningDashboard extends StatefulWidget {
  const MiningDashboard({super.key});

  @override
  State<MiningDashboard> createState() => _MiningDashboardState();
}

class _MiningDashboardState extends State<MiningDashboard> {
  static const platform = MethodChannel('com.smsindia.app/mining');
  final SupabaseClient supabase = Supabase.instance.client;
  
  bool isMining = false;
  double balance = 0.00;
  int _selectedSimSlot = 0; 
  String statusLog = "Ready to start Native Mining Node.";
  Timer? _balanceWatcher;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _balanceWatcher = Timer.periodic(const Duration(seconds: 5), (_) => _loadBalance());
  }

  @override
  void dispose() {
    _balanceWatcher?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await _loadBalance();
    setState(() => _isLoading = false);
  }

  Future<void> _loadBalance() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'User not authenticated';
          balance = 0.00;
        });
      }
      return;
    }

    try {
      final data = await supabase.from('users').select('balance').eq('id', user.id).single();
      if (mounted) {
        setState(() {
          balance = (data['balance'] as num).toDouble();
          _errorMessage = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load balance';
          balance = 0.00;
        });
      }
    }
  }

  Future<void> _toggleMining() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        statusLog = "Error: User not authenticated";
      });
      return;
    }

    try {
      if (!isMining) {
        final String result = await platform.invokeMethod('START_MINING', {
          'userId': user.id,
          'simSlot': _selectedSimSlot, 
        });

        setState(() {
          isMining = true;
          statusLog = "Scanning Network (SIM ${_selectedSimSlot + 1}): $result";
        });
      } else {
        final String result = await platform.invokeMethod('STOP_MINING');
        setState(() {
          isMining = false;
          statusLog = "Node Offline: $result";
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        statusLog = "Error: '${e.message}'.";
        isMining = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading State
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF00C853),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              Text(
                'Loading mining data...', 
                style: GoogleFonts.poppins(color: Colors.white)
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF00C853),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("SMS Node", style: GoogleFonts.poppins(color: Colors.white)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF00E676), // Bright Green Top
                  Color(0xFF00C853), // Medium Green
                  Color(0xFF00BFA5), // Teal Bottom
                ],
              ),
            ),
          ),
          
          // Pattern Overlay
          Opacity(
            opacity: 0.05,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage("https://www.transparenttextures.com/patterns/cubes.png"),
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
          ),

          SingleChildScrollView( 
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // STATUS BADGE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMining ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: isMining ? Colors.green : Colors.red, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: isMining ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMining ? Icons.circle : Icons.circle_outlined,
                        color: isMining ? Colors.green : Colors.red,
                        size: 12,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isMining ? "● ACTIVE (SIM ${_selectedSimSlot + 1})" : "● OFFLINE",
                        style: GoogleFonts.poppins(
                          color: isMining ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),

                // --- MINING RADAR ---
                Container(
                  height: 220,
                  width: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE8F5E9).withOpacity(0.8),
                    boxShadow: [
                      BoxShadow(
                        color: isMining ? Colors.green.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                      const BoxShadow(
                        color: Colors.white24,
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                    border: Border.all(
                      color: isMining ? Colors.green : Colors.grey,
                      width: 3,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Radar lines
                      CustomPaint(
                        painter: RadarPainter(isMining: isMining),
                      ),
                      Center(
                        child: Icon(
                          isMining ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                          size: 80,
                          color: isMining ? const Color(0xFF00C853) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // BALANCE CARD
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Wallet Balance", 
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF666666),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        )
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "₹${balance.toStringAsFixed(2)}", 
                        style: GoogleFonts.poppins(
                          fontSize: 48, 
                          fontWeight: FontWeight.bold, 
                          color: const Color(0xFF00C853),
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        )
                      ),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            _errorMessage,
                            style: GoogleFonts.poppins(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),

                // --- SIM SELECTOR WIDGET ---
                SimSelector(
                  selectedSlot: _selectedSimSlot,
                  isMining: isMining, 
                  onSimChanged: (slot) {
                    setState(() => _selectedSimSlot = slot);
                  },
                ),

                const SizedBox(height: 30),
                
                // Status Log
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Text(
                    statusLog, 
                    textAlign: TextAlign.center, 
                    style: GoogleFonts.poppins(
                      color: Colors.white, 
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    )
                  ),
                ),
                const SizedBox(height: 20),

                // ACTION BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _toggleMining,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMining ? Colors.red : const Color(0xFFFF9100),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 8,
                      shadowColor: isMining ? Colors.red.withOpacity(0.5) : const Color(0xFFFF9100).withOpacity(0.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isMining ? Icons.stop_circle : Icons.play_circle_fill,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isMining ? "STOP NODE" : "START NODE",
                          style: GoogleFonts.poppins(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
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

// Custom Radar Painter for visual effect
class RadarPainter extends CustomPainter {
  final bool isMining;
  
  RadarPainter({required this.isMining});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = isMining ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Draw concentric circles
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i / 4, paint);
    }
    
    // Draw radar lines - FIXED: Use math.cos and math.sin
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (pi / 180); // Use pi from dart:math
      final dx = radius * cos(angle); // Use cos from dart:math
      final dy = radius * sin(angle); // Use sin from dart:math
      canvas.drawLine(center, center + Offset(dx, dy), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------------------------------------------------
// SIM SELECTOR WIDGET (Updated for green theme)
// ---------------------------------------------------------
class SimSelector extends StatelessWidget {
  final int selectedSlot;
  final Function(int) onSimChanged;
  final bool isMining; 

  const SimSelector({
    super.key,
    required this.selectedSlot,
    required this.onSimChanged,
    required this.isMining,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(
            "Select SIM Card",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                )
              ]
            ),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            _buildSimCard(context, "SIM 1", 0),
            const SizedBox(width: 15),
            _buildSimCard(context, "SIM 2", 1),
          ],
        ),
      ],
    );
  }

  Widget _buildSimCard(BuildContext context, String title, int slotIndex) {
    final isSelected = selectedSlot == slotIndex;
    
    return Expanded(
      child: GestureDetector(
        onTap: isMining ? null : () => onSimChanged(slotIndex),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected 
                ? Colors.white.withOpacity(0.9)
                : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? const Color(0xFF00C853) : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected 
                    ? const Color(0xFF00C853).withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.sim_card,
                color: isSelected ? const Color(0xFF00C853) : Colors.white,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "Selected",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
