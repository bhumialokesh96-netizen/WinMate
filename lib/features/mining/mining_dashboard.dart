import 'dart:async';
import 'dart:math';
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
  
  // SIM 1 Settings
  bool isMiningSim1 = false;
  int sim1DailyLimit = 100;
  int sim1SentToday = 0;
  String sim1Name = "SIM 1";
  
  // SIM 2 Settings
  bool isMiningSim2 = false;
  int sim2DailyLimit = 100;
  int sim2SentToday = 0;
  String sim2Name = "SIM 2";
  
  // Common
  double balance = 0.00;
  String statusLog = "Ready to start Native Mining Node.";
  Timer? _balanceWatcher;
  bool _isLoading = true;
  String _errorMessage = '';
  Timer? _dailyResetTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _balanceWatcher = Timer.periodic(const Duration(seconds: 5), (_) => _loadBalance());
    _startDailyResetTimer();
  }

  @override
  void dispose() {
    _balanceWatcher?.cancel();
    _dailyResetTimer?.cancel();
    super.dispose();
  }

  void _startDailyResetTimer() {
    // Reset counters at midnight
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final durationToMidnight = nextMidnight.difference(now);
    
    _dailyResetTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      final currentTime = DateTime.now();
      if (currentTime.hour == 0 && currentTime.minute == 0) {
        _resetDailyCounters();
      }
    });
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadBalance(),
      _loadSimSettings(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadSimSettings() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Load SIM settings from database
      final data = await supabase
          .from('sim_settings')
          .select()
          .eq('user_id', user.id)
          .order('sim_slot');

      if (data.isNotEmpty) {
        for (var sim in data) {
          if (sim['sim_slot'] == 0) {
            setState(() {
              sim1Name = sim['sim_name'] ?? "SIM 1";
              sim1DailyLimit = sim['daily_limit'] ?? 100;
            });
            _loadTodaySentCount(0);
          } else if (sim['sim_slot'] == 1) {
            setState(() {
              sim2Name = sim['sim_name'] ?? "SIM 2";
              sim2DailyLimit = sim['daily_limit'] ?? 100;
            });
            _loadTodaySentCount(1);
          }
        }
      }
    } catch (e) {
      print("Error loading SIM settings: $e");
    }
  }

  Future<void> _loadTodaySentCount(int simSlot) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      
      final data = await supabase
          .from('sms_tasks')
          .select('id')
          .eq('assigned_to', user.id)
          .eq('sim_slot', simSlot)
          .eq('status', 'sent')
          .gte('created_at', startOfDay.toIso8601String())
          .lte('created_at', today.toIso8601String());

      if (simSlot == 0) {
        setState(() => sim1SentToday = data.length);
      } else {
        setState(() => sim2SentToday = data.length);
      }
    } catch (e) {
      print("Error loading sent count: $e");
    }
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

  Future<void> _toggleMining(int simSlot) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        statusLog = "Error: User not authenticated";
      });
      return;
    }

    // Check daily limit
    final sentToday = simSlot == 0 ? sim1SentToday : sim2SentToday;
    final dailyLimit = simSlot == 0 ? sim1DailyLimit : sim2DailyLimit;
    
    if (sentToday >= dailyLimit) {
      setState(() {
        statusLog = "SIM ${simSlot + 1}: Daily limit reached ($sentToday/$dailyLimit)";
      });
      return;
    }

    try {
      if (simSlot == 0 ? !isMiningSim1 : !isMiningSim2) {
        final String result = await platform.invokeMethod('START_MINING', {
          'userId': user.id,
          'simSlot': simSlot,
        });

        setState(() {
          if (simSlot == 0) {
            isMiningSim1 = true;
          } else {
            isMiningSim2 = true;
          }
          statusLog = "SIM ${simSlot + 1} Started: $result";
        });
      } else {
        final String result = await platform.invokeMethod('STOP_MINING', {
          'simSlot': simSlot,
        });
        
        setState(() {
          if (simSlot == 0) {
            isMiningSim1 = false;
          } else {
            isMiningSim2 = false;
          }
          statusLog = "SIM ${simSlot + 1} Stopped: $result";
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        statusLog = "SIM ${simSlot + 1} Error: '${e.message}'.";
        if (simSlot == 0) {
          isMiningSim1 = false;
        } else {
          isMiningSim2 = false;
        }
      });
    }
  }

  Future<void> _updateSimSettings(int simSlot, String name, int limit) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('sim_settings').upsert({
        'user_id': user.id,
        'sim_slot': simSlot,
        'sim_name': name,
        'daily_limit': limit,
        'updated_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        if (simSlot == 0) {
          sim1Name = name;
          sim1DailyLimit = limit;
        } else {
          sim2Name = name;
          sim2DailyLimit = limit;
        }
      });

      setState(() {
        statusLog = "SIM ${simSlot + 1} settings updated successfully!";
      });
    } catch (e) {
      setState(() {
        statusLog = "Error updating SIM ${simSlot + 1} settings";
      });
    }
  }

  Future<void> _resetDailyCounter(int simSlot) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Reset in database (optional - for tracking)
      await supabase.from('sim_settings').update({
        'last_reset': DateTime.now().toIso8601String(),
      }).eq('user_id', user.id).eq('sim_slot', simSlot);

      setState(() {
        if (simSlot == 0) {
          sim1SentToday = 0;
        } else {
          sim2SentToday = 0;
        }
      });

      setState(() {
        statusLog = "SIM ${simSlot + 1} counter reset to 0";
      });
    } catch (e) {
      setState(() {
        statusLog = "Error resetting SIM ${simSlot + 1} counter";
      });
    }
  }

  void _resetDailyCounters() {
    setState(() {
      sim1SentToday = 0;
      sim2SentToday = 0;
      statusLog = "Daily counters reset at midnight";
    });
  }

  void _showSimSettingsDialog(int simSlot) {
    final currentName = simSlot == 0 ? sim1Name : sim2Name;
    final currentLimit = simSlot == 0 ? sim1DailyLimit : sim2DailyLimit;
    
    TextEditingController nameController = TextEditingController(text: currentName);
    TextEditingController limitController = TextEditingController(text: currentLimit.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: build3DText(
          "Configure SIM ${simSlot + 1}",
          fontSize: 20,
          mainColor: const Color(0xFF00C853),
          shadowColor: Colors.black54,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'SIM Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: limitController,
              decoration: const InputDecoration(
                labelText: 'Daily Limit (0-1000)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              final newLimit = int.tryParse(limitController.text) ?? 100;
              
              if (newName.isNotEmpty && newLimit >= 0 && newLimit <= 1000) {
                _updateSimSettings(simSlot, newName, newLimit);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF00C853),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              build3DText(
                'Loading mining data...',
                fontSize: 16,
                mainColor: Colors.white,
                shadowColor: Colors.black54,
              ),
            ],
          ),
        ),
      );
    }

    final totalSentToday = sim1SentToday + sim2SentToday;
    final totalDailyLimit = sim1DailyLimit + sim2DailyLimit;

    return Scaffold(
      backgroundColor: const Color(0xFF00C853),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: build3DText(
          "Dual SIM SMS Node",
          fontSize: 24,
          mainColor: Colors.white,
          shadowColor: Colors.black54,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: build3DIcon(
              Icons.refresh,
              size: 24,
              mainColor: Colors.white,
              shadowColor: Colors.black54,
            ),
            onPressed: () => _loadInitialData(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF00E676),
                  Color(0xFF00C853),
                  Color(0xFF00BFA5),
                ],
              ),
            ),
          ),
          
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
                // DAILY LIMIT SUMMARY
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      build3DText(
                        "Today's Progress",
                        fontSize: 16,
                        mainColor: const Color(0xFF666666),
                        shadowColor: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: totalDailyLimit > 0 ? (totalSentToday / totalDailyLimit).toDouble() : 0.0,
                        backgroundColor: Colors.grey[300],
                        color: const Color(0xFF00C853),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          build3DText(
                            "Sent: $totalSentToday",
                            fontSize: 14,
                            mainColor: const Color(0xFF00C853),
                            shadowColor: Colors.black54,
                          ),
                          build3DText(
                            "Limit: $totalDailyLimit",
                            fontSize: 14,
                            mainColor: const Color(0xFF666666),
                            shadowColor: Colors.black54,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),

                // SIM 1 CARD
                _buildSimCard(
                  simSlot: 0,
                  simName: sim1Name,
                  isMining: isMiningSim1,
                  sentToday: sim1SentToday,
                  dailyLimit: sim1DailyLimit,
                ),
                
                const SizedBox(height: 20),

                // SIM 2 CARD
                _buildSimCard(
                  simSlot: 1,
                  simName: sim2Name,
                  isMining: isMiningSim2,
                  sentToday: sim2SentToday,
                  dailyLimit: sim2DailyLimit,
                ),
                
                const SizedBox(height: 30),

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
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      build3DText(
                        "Wallet Balance",
                        fontSize: 16,
                        mainColor: const Color(0xFF666666),
                        shadowColor: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                      const SizedBox(height: 10),
                      build3DText(
                        "₹${balance.toStringAsFixed(2)}",
                        fontSize: 48,
                        mainColor: const Color(0xFF00C853),
                        shadowColor: Colors.black,
                        fontWeight: FontWeight.bold,
                        depth: 3,
                      ),
                      if (_errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: build3DText(
                            _errorMessage,
                            fontSize: 12,
                            mainColor: Colors.red,
                            shadowColor: Colors.black54,
                          ),
                        ),
                    ],
                  ),
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
                  child: build3DText(
                    statusLog,
                    fontSize: 14,
                    mainColor: Colors.white,
                    shadowColor: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimCard({
    required int simSlot,
    required String simName,
    required bool isMining,
    required int sentToday,
    required int dailyLimit,
  }) {
    final isLimitReached = sentToday >= dailyLimit;
    final progress = dailyLimit > 0 ? sentToday / dailyLimit.toDouble() : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isMining ? const Color(0xFF00C853) : Colors.grey).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isMining ? const Color(0xFF00C853) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // SIM Header with Settings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        build3DIcon(
                          Icons.sim_card,
                          size: 24,
                          mainColor: const Color(0xFF00C853),
                          shadowColor: Colors.black54,
                        ),
                        const SizedBox(width: 10),
                        build3DText(
                          "SIM ${simSlot + 1}: $simName",
                          fontSize: 18,
                          mainColor: const Color(0xFF00C853),
                          shadowColor: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    build3DText(
                      isMining ? "● ACTIVE" : "● OFFLINE",
                      fontSize: 14,
                      mainColor: isMining ? Colors.green : Colors.red,
                      shadowColor: Colors.black54,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: build3DIcon(
                  Icons.settings,
                  size: 22,
                  mainColor: const Color(0xFF666666),
                  shadowColor: Colors.black54,
                ),
                onPressed: () => _showSimSettingsDialog(simSlot),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Daily Limit Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  build3DText(
                    "Daily Limit",
                    fontSize: 14,
                    mainColor: const Color(0xFF666666),
                    shadowColor: Colors.black54,
                  ),
                  build3DText(
                    "$sentToday/$dailyLimit",
                    fontSize: 16,
                    mainColor: isLimitReached ? Colors.red : const Color(0xFF00C853),
                    shadowColor: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                color: isLimitReached ? Colors.red : const Color(0xFF00C853),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Action Buttons Row
          Row(
            children: [
              // Reset Button
              Expanded(
                child: ElevatedButton(
                  onPressed: sentToday > 0 ? () => _resetDailyCounter(simSlot) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      build3DIcon(
                        Icons.refresh,
                        size: 18,
                        mainColor: Colors.white,
                        shadowColor: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      build3DText(
                        "Reset Counter",
                        fontSize: 14,
                        mainColor: Colors.white,
                        shadowColor: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 10),
              
              // Start/Stop Button
              Expanded(
                child: ElevatedButton(
                  onPressed: isLimitReached ? null : () => _toggleMining(simSlot),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isMining ? Colors.red : const Color(0xFF00C853),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      build3DIcon(
                        isMining ? Icons.stop_circle : Icons.play_circle_fill,
                        size: 20,
                        mainColor: Colors.white,
                        shadowColor: Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      build3DText(
                        isMining ? "STOP" : "START",
                        fontSize: 16,
                        mainColor: Colors.white,
                        shadowColor: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 3D Text Widget ---
  Widget build3DText(
    String text, {
    double fontSize = 18,
    Color mainColor = Colors.white,
    Color shadowColor = const Color(0xFF004D40),
    double depth = 2,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return Stack(
      children: [
        // Shadow text
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: shadowColor,
          ),
        ),
        // Front text
        Transform.translate(
          offset: Offset(0, -depth),
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: mainColor,
              shadows: const [
                Shadow(color: Colors.black26, blurRadius: 2),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 3D Icon Widget ---
  Widget build3DIcon(
    IconData icon, {
    double size = 24,
    Color mainColor = Colors.white,
    Color shadowColor = Colors.black54,
    double depth = 1,
  }) {
    return Stack(
      children: [
        // Shadow icon
        Icon(
          icon,
          size: size,
          color: shadowColor,
        ),
        // Front icon
        Transform.translate(
          offset: Offset(0, -depth),
          child: Icon(
            icon,
            size: size,
            color: mainColor,
          ),
        ),
      ],
    );
  }
}
