import 'package:flutter/cupertino.dart';

class RefundConfirmationDialog extends StatelessWidget {
  final Function() onConfirm;

  const RefundConfirmationDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Confirm Refund',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF14023F),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Are you sure you want to refund this order?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  color: CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(8),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF14023F),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  color: CupertinoColors.systemRed,
                  borderRadius: BorderRadius.circular(8),
                  child: const Text(
                    'Refund',
                    style: TextStyle(
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }
}
