import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

/// Animated Progress Bar Widget for gamified UI
class AnimatedProgressBar extends StatelessWidget {
  final double value;
  final String label;
  final Color? color;
  final double height;
  
  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.label,
    this.color,
    this.height = 30,
  });
  
  @override
  Widget build(BuildContext context) {
    final progressColor = color ?? AppTheme.accentOrange;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.white,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppTheme.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              tween: Tween<double>(
                begin: 0,
                end: value.clamp(0.0, 1.0),
              ),
              builder: (context, value, child) {
                return FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          progressColor,
                          progressColor.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Badge Widget for achievements and milestones
class AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isUnlocked;
  
  const AchievementBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.isUnlocked = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isUnlocked
                ? LinearGradient(
                    colors: [
                      color,
                      color.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isUnlocked ? null : AppTheme.grey.withOpacity(0.3),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
            border: Border.all(
              color: isUnlocked ? AppTheme.white.withOpacity(0.5) : AppTheme.grey,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isUnlocked ? AppTheme.white : AppTheme.grey,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isUnlocked ? AppTheme.white : AppTheme.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Stat Card Widget for displaying statistics
class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  
  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppTheme.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: AppTheme.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: AppTheme.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Action Button Widget
class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  
  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 28,
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppTheme.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
