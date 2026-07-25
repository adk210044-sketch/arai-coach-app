import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class AppChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const AppChip({
    super.key,
    required this.label,
    this.bg = AppColors.primarySoft,
    this.fg = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: AppFontSize.sm,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
