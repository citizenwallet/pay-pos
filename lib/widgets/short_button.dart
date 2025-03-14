import 'package:flutter/cupertino.dart';
import 'package:pay_pos/theme/colors.dart';

class ShortButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;
  final bool disabled;

  const ShortButton({
    super.key,
    required this.child,
    this.onPressed,
    this.color,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: CupertinoButton(
        color: disabled
            ? (color ?? surfaceDarkColor).withValues(alpha: 0.5)
            : color ?? surfaceDarkColor,
        borderRadius: BorderRadius.circular(100),
        padding: const EdgeInsets.symmetric(vertical: 16),
        onPressed: disabled ? null : onPressed,
        child: child,
      ),
    );
  }
}
