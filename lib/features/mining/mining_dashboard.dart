import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lottie/lottie.dart';
import 'sim_selector.dart'; // <--- IMPORT THE NEW FILE

class MiningDashboard extends StatefulWidget {
  const MiningDashboard({super.key});

  @override
  State<MiningDashboard> createState() => _MiningDashboardState();
}

class _MiningDashboardState extends State<MiningDashboard> {
  static const platform = MethodChannel('com.winmate.app/mining');
  final SupabaseClient supabase = Supabase.instance.client;
  
  bool isMining = false;
  double balance = 0.00;
  int _selectedSimSlot = 0; // <--- DEFAULT SIM 1 (0)
  String statusLog = "Ready to start Native Mining Node.";
  Timer? _balanceWatcher;

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _balanceWatcher = Timer.periodic(const Duration(seconds: 5), (_) => _loadBalance());
  }

  @override
  void dispose() {
    _balanceWatcher?.cancel();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final data = await supabase.from('wallet').select('balance').eq('user_id', user.id).single();
        if (mounted) setState(() => balance = (data['balance'] as num).toDouble());
      } catch (e) { }
    }
  }

  Future<void> _toggleMining() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      if (!isMining) {
        // PASS SELECTED SIM SLOT TO JAVA
        final String result = await platform.invokeMethod('START_MINING', {
          'userId': user.id,
          'simSlot': _selectedSimSlot, // <--- SENDING SELECTION (0 or 1)
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("SMS Node", style: GoogleFonts.poppins(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView( // Added ScrollView to prevent overflow
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // STATUS BADGE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isMining ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isMining ? Colors.green : Colors.red),
              ),
              child: Text(
                isMining ? "● ACTIVE (SIM ${_selectedSimSlot + 1})" : "● OFFLINE",
                style: GoogleFonts.poppins(
                  color: isMining ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // RADAR
            SizedBox(
              height: 200,
              width: 200,
              child: isMining
                  ? Lottie.asset('assets/animations/radar.json', fit: BoxFit.contain)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_tethering_off, size: 80, color: Colors.grey.withOpacity(0.3)),
                        const SizedBox(height: 10),
                        Text("Tap Start to Scan", style: GoogleFonts.poppins(color: Colors.grey)),
                      ],
                    ),
            ),

            const SizedBox(height: 20),

            // BALANCE
            Text("Wallet Balance", style: GoogleFonts.poppins(color: Colors.grey)),
            Text(
              "₹${balance.toStringAsFixed(2)}", 
              style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)
            ),
            
            const SizedBox(height: 30),

            // --- SIM SELECTOR WIDGET ---
            SimSelector(
              selectedSlot: _selectedSimSlot,
              isMining: isMining, // Lock if mining
              onSimChanged: (slot) {
                setState(() => _selectedSimSlot = slot);
              },
            ),
            // ---------------------------

            const SizedBox(height: 30),
            
            Text(statusLog, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 10),

            // BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _toggleMining,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isMining ? Colors.red : const Color(0xFFE94560),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                child: Text(
                  isMining ? "STOP NODE" : "START NODE",
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
