import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../widgets/common_widgets.dart';

/// Achievements Screen showcasing gamification enhancements
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: Stack(
        children: [
          Container(decoration: AppTheme.gradientBackground()),
          AppTheme.patternOverlay(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon3D(Icons.arrow_back, size: 28),
                      ),
                      const Expanded(
                        child: Text3D("Achievements", fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: AppTheme.cardDecoration(solidColor: AppTheme.white),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Overall Progress', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkGrey)),
                              const SizedBox(height: 20),
                              const AnimatedProgressBar(value: 0.65, label: 'SMS Miner', color: AppTheme.primaryGreen),
                              const SizedBox(height: 15),
                              const AnimatedProgressBar(value: 0.40, label: 'Referral Master', color: AppTheme.accentOrange),
                              const SizedBox(height: 15),
                              const AnimatedProgressBar(value: 0.85, label: 'Lucky Spinner', color: AppTheme.accentPurple),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text3D("Mining Achievements", fontSize: 18, fontWeight: FontWeight.bold),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: AppTheme.cardDecoration(solidColor: AppTheme.white),
                          child: const Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            children: [
                              AchievementBadge(icon: Icons.send, label: 'First SMS', color: AppTheme.primaryGreen, isUnlocked: true),
                              AchievementBadge(icon: Icons.flash_on, label: '100 SMS', color: AppTheme.accentOrange, isUnlocked: true),
                              AchievementBadge(icon: Icons.star, label: '500 SMS', color: AppTheme.accentYellow, isUnlocked: true),
                              AchievementBadge(icon: Icons.workspace_premium, label: '1000 SMS', color: AppTheme.accentPurple, isUnlocked: false),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
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
