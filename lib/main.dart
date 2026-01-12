import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/main_nav_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Constants.supabaseUrl,
    anonKey: Constants.supabaseAnonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WinMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(),
      home: Supabase.instance.client.auth.currentUser != null
          ? const MainNavScreen()
          : const LoginScreen(),
    );
  }
}
