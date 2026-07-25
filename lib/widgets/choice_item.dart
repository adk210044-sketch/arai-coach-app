import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum ChoiceState { normal, selected, correct, incorrect }

class ChoiceItem extends StatefulWidget {
  final String label;
  final ChoiceState state;
  final VoidCallback? onTap;

  const ChoiceItem({
    super.key,
    required this.label,
    this.state = ChoiceState.normal,
    this.onTap,
  });

  @override
  State<ChoiceItem> createState() => _ChoiceItemState();
}

class _ChoiceItemState extends State<ChoiceItem> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    double borderWidth = 1;
    Widget? trailing;

    switch (widget.state) {
      case ChoiceState.normal:
        bg = Colors.white;
        border = AppColors.border;
        break;
      case ChoiceState.selected:
        bg = AppColors.primarySoft;
        border = AppColors.primary;
        borderWidth = 2;
        break;
      case ChoiceState.correct:
        bg = const Color(0xFFDCFCE7);
        border = AppColors.ok;
        borderWidth = 2;
        trailing = const Icon(
          Icons.check_circle,
          color: AppColors.ok,
          size: 22,
        );
        break;
      case ChoiceState.incorrect:
        bg = const Color(0xFFFEE2E2);
        border = AppColors.ng;
        borderWidth = 2;
        trailing = const Icon(Icons.cancel, color: AppColors.ng, size: 22);
        break;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Semantics(
          button: true,
          label: widget.label,
          selected: widget.state == ChoiceState.selected,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 10),
            constraints: const BoxConstraints(minHeight: 44),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: border, width: borderWidth),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: AppFontSize.lg,
                      color: AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
