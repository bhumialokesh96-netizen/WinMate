import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:lottie/lottie.dart'; // We don't need this anymore since we removed the animation

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
  int _selectedSimSlot = 0; 
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
        // CORRECTED: Targets 'users' table and 'id' column
        final data = await supabase.from('users').select('balance').eq('id', user.id).single();
        if (mounted) setState(() => balance = (data['balance'] as num).toDouble());
      } catch (e) { }
    }
  }

  Future<void> _toggleMining() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("SMS Node", style: GoogleFonts.poppins(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView( 
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
            
            const SizedBox(height: 30),

            // --- RADAR (SAFE MODE - NO CRASH) ---
            // Replaced the Lottie asset with this Container
            Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF16213E),
                boxShadow: [
                  if (isMining)
                    BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 30, spreadRadius: 5)
                ],
              ),
              child: Icon(
                Icons.wifi_tethering, // Uses a built-in Icon instead of a file
                size: 100,
                color: isMining ? Colors.green : Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

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
              isMining: isMining, 
              onSimChanged: (slot) {
                setState(() => _selectedSimSlot = slot);
              },
            ),

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

// ---------------------------------------------------------
// SIM SELECTOR WIDGET
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
        Text(
          "Select SIM Card",
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
        ),
        const SizedBox(height: 10),
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
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFFE94560).withOpacity(0.2) 
                : const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFFE94560) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.sim_card,
                color: isSelected ? const Color(0xFFE94560) : Colors.grey,
                size: 30,
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Color(0xFFE94560), size: 16)
            ],
          ),
        ),
      ),
    );
  }
}
