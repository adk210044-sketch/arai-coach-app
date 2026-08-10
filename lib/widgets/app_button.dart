import 'package:flutter/material.dart';
import '../theme/tokens.dart';

enum AppButtonVariant { primary, primaryLarge, secondary, ghost }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool disabled;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.disabled = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) {
    if (widget.disabled || widget.onPressed == null) return;
    setState(() => _scale = 0.97);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.disabled || widget.onPressed == null;

    Color bg;
    Color fg;
    double height;
    double radius;
    BoxBorder? border;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bg = AppColors.primary;
        fg = Colors.white;
        height = 52;
        radius = AppRadius.pill;
        break;
      case AppButtonVariant.primaryLarge:
        bg = AppColors.primary;
        fg = Colors.white;
        height = 56;
        radius = AppRadius.lg;
        break;
      case AppButtonVariant.secondary:
        bg = AppColors.primarySoft;
        fg = AppColors.primary;
        height = 52;
        radius = AppRadius.md;
        break;
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.primary;
        height = 52;
        radius = AppRadius.md;
        border = Border.all(color: AppColors.primary, width: 1);
        break;
    }

    if (isDisabled) {
      bg = AppColors.border;
      fg = AppColors.textMute;
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Semantics(
          button: true,
          label: widget.label,
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(radius),
              border: border,
              boxShadow:
                  (!isDisabled && widget.variant != AppButtonVariant.ghost)
                  ? AppShadow.button
                  : null,
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  widget.icon!,
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: fg,
                    fontSize: AppFontSize.xl,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
