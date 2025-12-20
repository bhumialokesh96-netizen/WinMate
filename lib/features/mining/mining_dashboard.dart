import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MiningDashboard extends StatefulWidget {
  const MiningDashboard({super.key});

  @override
  State<MiningDashboard> createState() => _MiningDashboardState();
}

class _MiningDashboardState extends State<MiningDashboard> {
  static const platform = MethodChannel('com.smsindia.app/mining');
  bool isMining = false;
  int logsToday = 0;
  double earnedToday = 0.0;
  Timer? _uiTimer;
  
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkMiningStatus();
    _loadDailyStats();
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  // 1. Check if Service is already running
  Future<void> _checkMiningStatus() async {
    try {
      final bool active = await platform.invokeMethod('isServiceRunning');
      setState(() {
        isMining = active;
      });
      if (active) {
        _startUiTicker();
      }
    } catch (e) {
      print("Error checking status: $e");
    }
  }

  // 2. Load Stats from Supabase
  Future<void> _loadDailyStats() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      // Get logs created today
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await supabase
          .from('mining_logs')
          .select()
          .eq('user_id', user.id)
          .gte('created_at', today); // Filter by date (approx)
      
      if (response != null) {
        final List data = response as List;
        setState(() {
          logsToday = data.length;
          earnedToday = logsToday * 2.0; // ₹2.0 per log
        });
      }
    }
  }

  // 3. Start/Stop Mining Logic
  Future<void> _toggleMining() async {
    if (isMining) {
      // STOP
      await platform.invokeMethod('stopMining');
      setState(() => isMining = false);
      _uiTimer?.cancel();
    } else {
      // START
      if (await Permission.sms.request().isGranted) {
        await platform.invokeMethod('startMining');
        setState(() => isMining = true);
        _startUiTicker();
        _simulateMiningForDemo(); // TEMPORARY: Triggers DB update for testing
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("SMS Permission Required")));
      }
    }
  }

  // --- CRITICAL: THE MONEY MAKER ---
  // Since we can't easily call Supabase from background Java yet,
  // We will simulate the DB update here for the demo.
  // In Phase 7, we connect the Native Service callback.
  void _simulateMiningForDemo() {
    _uiTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (!isMining) {
        timer.cancel();
        return;
      }
      
      final user = supabase.auth.currentUser;
      if (user != null) {
        // INSERT LOG -> TRIGGERS SQL -> UPDATES WALLET
        await supabase.from('mining_logs').insert({
          'user_id': user.id,
          'sms_count': 1,
          'earned_amount': 2.00, // ₹2.00
        });
        
        // Refresh UI
        _loadDailyStats();
        
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text("SMS Sent! ₹2.00 Added"), 
             duration: Duration(milliseconds: 1000),
             backgroundColor: Colors.green,
           )
        );
      }
    });
  }

  void _startUiTicker() {
    // Just updates the UI stats periodically
    _uiTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text("Mining Node", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- STATUS CARD ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isMining ? const Color(0xFF16213E) : const Color(0xFF252525),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isMining ? Colors.green : Colors.white10,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    isMining ? Icons.wifi_tethering : Icons.wifi_off,
                    size: 60,
                    color: isMining ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    isMining ? "MINING ACTIVE" : "MINING PAUSED",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isMining ? Colors.green : Colors.grey,
                    ),
                  ),
                  Text(
                    isMining ? "Processing transactions..." : "Tap button to start",
                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- STATS GRID ---
            Row(
              children: [
                Expanded(child: _buildStatCard("SMS Sent", "$logsToday", Icons.message, Colors.blue)),
                const SizedBox(width: 15),
                Expanded(child: _buildStatCard("Earned Today", "₹${earnedToday.toStringAsFixed(0)}", Icons.attach_money, Colors.orange)),
              ],
            ),

            const Spacer(),

            // --- BIG BUTTON ---
            GestureDetector(
              onTap: _toggleMining,
              child: Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isMining 
                      ? [Colors.redAccent, Colors.red] 
                      : [const Color(0xFFE94560), const Color(0xFF0F3460)],
                  ),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: (isMining ? Colors.red : const Color(0xFFE94560)).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    isMining ? "STOP MINING" : "START MINING",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(title, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54)),
        ],
      ),
    );
  }
}
