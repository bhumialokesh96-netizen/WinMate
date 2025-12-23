import 'package:flutter/services.dart';

class NativeBridge {
  static const platform = MethodChannel('com.smsindia.app/mining');

  // 1. Start the Java Service
  static Future<void> startMiningService(String userId, int simSlot) async {
    try {
      await platform.invokeMethod('START_MINING', {
        'userId': userId,
        'simSlot': simSlot, // 0 for SIM 1, 1 for SIM 2
      });
    } on PlatformException catch (e) {
      print("Failed to start mining: '${e.message}'.");
    }
  }

  // 2. Stop the Java Service
  static Future<void> stopMiningService() async {
    try {
      await platform.invokeMethod('STOP_MINING');
    } on PlatformException catch (e) {
      print("Failed to stop mining: '${e.message}'.");
    }
  }
}
