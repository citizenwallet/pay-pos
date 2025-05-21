import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:pay_pos/state/pin.dart';
import 'package:provider/provider.dart';

class PinEntryDialog extends StatefulWidget {
  final bool isCreating;
  final Function()? onSuccess;

  const PinEntryDialog({
    super.key,
    this.isCreating = false,
    this.onSuccess,
  });

  @override
  State<PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<PinEntryDialog> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_onPinChanged);
    _confirmPinController.addListener(_onPinChanged);
  }

  void _onPinChanged() {
    final pinState = context.read<PinState>();
    pinState.clearError();
  }

  @override
  void dispose() {
    _pinController.removeListener(_onPinChanged);
    _confirmPinController.removeListener(_onPinChanged);
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleCreatePin() async {
    final pinState = context.read<PinState>();
    final success = await pinState.createPin(
      _pinController.text,
      _confirmPinController.text,
    );

    if (success && mounted) {
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      }
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleVerifyPin() async {
    final pinState = context.read<PinState>();
    final success = await pinState.verifyPin(_pinController.text);

    if (success && mounted) {
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PinState>(
      builder: (context, pinState, child) {
        return Container(
          padding: const EdgeInsets.only(top: 6.0),
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Text(
                      widget.isCreating ? 'Create PIN' : 'Enter PIN',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CupertinoTextField(
                      controller: _pinController,
                      placeholder: 'Enter 4-digit PIN',
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      enabled: !pinState.isLoading,
                      padding: const EdgeInsets.all(12),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: BoxDecoration(
                        border: Border.all(color: CupertinoColors.systemGrey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    if (widget.isCreating) ...[
                      const SizedBox(height: 16),
                      CupertinoTextField(
                        controller: _confirmPinController,
                        placeholder: 'Confirm 4-digit PIN',
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        enabled: !pinState.isLoading,
                        padding: const EdgeInsets.all(12),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: BoxDecoration(
                          border: Border.all(color: CupertinoColors.systemGrey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                    if (pinState.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        pinState.errorMessage!,
                        style: const TextStyle(color: CupertinoColors.systemRed),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            onPressed: pinState.isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        Expanded(
                          child: CupertinoButton.filled(
                            onPressed: pinState.isLoading
                                ? null
                                : (widget.isCreating
                                    ? _handleCreatePin
                                    : _handleVerifyPin),
                            child: pinState.isLoading
                                ? const CupertinoActivityIndicator()
                                : Text(widget.isCreating ? 'Create' : 'Verify'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
