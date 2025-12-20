import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SimSelector extends StatelessWidget {
  final int selectedSlot;
  final Function(int) onSimChanged;
  final bool isMining; // Disable selection if mining is running

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
