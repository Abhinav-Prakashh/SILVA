// lib/widgets/vital_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

class VitalCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const VitalCard({super.key, required this.title, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 30, height: 30,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16)),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 10),
        Text(value, style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ]),
    );
  }
}
