import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/native_bridge.dart';

class MiningDashboard extends StatefulWidget {
  const MiningDashboard({super.key});

  @override
  State<MiningDashboard> createState() => _MiningDashboardState();
}

class _MiningDashboardState extends State<MiningDashboard> {
  bool _isMining = false;
  int _selectedSim = 0; // 0 = SIM 1, 1 = SIM 2

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Header
              const Text("SMS Miner Engine", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
              const Text("Turn your unused SMS into Cash", style: TextStyle(color: Colors.grey)),
              
              const SizedBox(height: 40),

              // 1. THE RADAR ANIMATION
              Container(
                height: 250,
                width: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)],
                ),
                child: _isMining 
                  ? Lottie.asset('assets/animations/radar.json') // You need a Lottie file here later, or use Loading Spinner
                  : const Icon(Icons.power_settings_new, size: 100, color: Colors.grey),
              ),

              const SizedBox(height: 40),

              // 2. STATUS TEXT
              Text(
                _isMining ? "MINING ACTIVE..." : "MINING PAUSED",
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.bold,
                  color: _isMining ? Colors.green : Colors.redAccent
                ),
              ),
              
              const Spacer(),

              // 3. SIM SELECTOR
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(30)),
                child: Row(
                  children: [
                    _simOption("SIM 1", 0),
                    _simOption("SIM 2", 1),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. BIG START BUTTON
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _toggleMining,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isMining ? Colors.redAccent : const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 5,
                  ),
                  child: Text(
                    _isMining ? "STOP MINING" : "START MINING",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _simOption(String label, int index) {
    bool isSelected = _selectedSim == index;
    return Expanded(
      child: GestureDetector(
        onTap: _isMining ? null : () => setState(() => _selectedSim = index), // Disable changing SIM while mining
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
          ),
          child: Center(
            child: Text(
              label, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: isSelected ? Colors.black : Colors.grey[600]
              ),
            ),
          ),
        ),
      ),
    );
  }

  // LOGIC TO START/STOP
  void _toggleMining() async {
    if (_isMining) {
      // STOP
      await NativeBridge.stopMiningService();
      setState(() => _isMining = false);
    } else {
      // START
      // A. Ask Permissions First
      if (await _requestPermissions()) {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        
        await NativeBridge.startMiningService(userId, _selectedSim);
        setState(() => _isMining = true);
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mining Started! App will work in background."), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Permissions Denied! Cannot Mine."), backgroundColor: Colors.red));
      }
    }
  }

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.sms,
      Permission.phone,
      Permission.notification,
    ].request();

    return statuses[Permission.sms]!.isGranted && statuses[Permission.phone]!.isGranted;
  }
}
