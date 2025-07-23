import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:pay_pos/services/config/config.dart';
import 'package:pay_pos/state/wallet.dart';
import 'package:pay_pos/widgets/toast/toast.dart';
import 'package:provider/provider.dart';

//models
import 'package:pay_pos/models/place.dart';

//state
import 'package:pay_pos/state/place_order.dart';

//widgets
import 'package:pay_pos/widgets/transaction_input_row.dart';
import 'package:pay_pos/widgets/wide_button.dart';
import 'package:toastification/toastification.dart';

class Footer extends StatefulWidget {
  final String placeId;
  final Function(double, String?, String, {String? tokenAddress}) onPay;
  final Function(double) onPayClient;
  final Function(TokenConfig) onTokenChange;
  final FocusNode amountFocusNode;
  final FocusNode messageFocusNode;
  final Place? place;
  final Display? display;
  final VoidCallback? onClear;

  static final List<TextEditingController> _amountControllers = [];
  static final List<TextEditingController> _messageControllers = [];

  const Footer({
    super.key,
    required this.placeId,
    required this.onPay,
    required this.onPayClient,
    required this.onTokenChange,
    required this.amountFocusNode,
    required this.messageFocusNode,
    this.place,
    this.display,
    this.onClear,
  });

  static void clearControllers() {
    for (var controller in _amountControllers) {
      controller.clear();
    }
    for (var controller in _messageControllers) {
      controller.clear();
    }
  }

  @override
  State<Footer> createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _showAmountField = true;
  double? _amount;

  @override
  void initState() {
    super.initState();
    Footer._amountControllers.add(_amountController);
    Footer._messageControllers.add(_messageController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // widget.amountFocusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(Footer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onClear != oldWidget.onClear) {
      widget.onClear?.call();
    }
  }

  void clearControllers() {
    _amountController.clear();
    _messageController.clear();
  }

  void _toggleField() {
    setState(() {
      _showAmountField = !_showAmountField;
      if (_showAmountField) {
        widget.amountFocusNode.requestFocus();
      } else {
        widget.messageFocusNode.requestFocus();
      }
    });
  }

  void handleAmountChange(double amount) {
    setState(() {
      _amount = amount == 0 ? null : amount;
    });
  }

  void handlePay({String? tokenAddress}) {
    if (_amount == null) {
      toastification.showCustom(
        context: context,
        autoCloseDuration: const Duration(seconds: 5),
        alignment: Alignment.bottomCenter,
        builder: (context, toast) => Toast(
          icon: const Icon(
            CupertinoIcons.xmark_circle_fill,
            color: errorColor,
          ),
          title: const Text('No amount entered'),
        ),
      );
      return;
    }

    _showAmountField = true;
    widget.amountFocusNode.unfocus();
    widget.messageFocusNode.unfocus();

    widget.onPay(
      _amount!,
      _messageController.text,
      widget.place!.account,
      tokenAddress: tokenAddress,
    );

    _amount = null;
    _amountController.clear();
    _messageController.clear();
  }

  void handlePayClient() {
    if (_amount == null) {
      toastification.showCustom(
        context: context,
        autoCloseDuration: const Duration(seconds: 5),
        alignment: Alignment.bottomCenter,
        builder: (context, toast) => Toast(
          icon: const Icon(
            CupertinoIcons.xmark_circle_fill,
            color: errorColor,
          ),
          title: const Text('No amount entered'),
        ),
      );
      return;
    }

    _showAmountField = true;
    widget.amountFocusNode.unfocus();
    widget.messageFocusNode.unfocus();

    widget.onPayClient(_amount!);

    _amount = null;
    _amountController.clear();
    _messageController.clear();
  }

  void handleTokenChange(TokenConfig token) {
    widget.onTokenChange(token);
  }

  void handleMenuPress() {
    _showAmountField = true;

    context.go('/${widget.placeId}/menu');
  }

  @override
  Widget build(BuildContext context) {
    final placeMenu = context.watch<PlaceOrderState>().placeMenu;

    final tokens =
        context.select<WalletState, List<TokenConfig>>((state) => state.tokens);
    final selectedToken = context
        .select<WalletState, TokenConfig?>((state) => state.selectedToken);

    final supportsPayment = context.select<WalletState, bool>((state) =>
        state.primaryToken != null &&
        state.primaryToken!.address == selectedToken?.address);

    final hasMenu = (widget.display == Display.menu ||
            widget.display == Display.amountAndMenu) &&
        placeMenu != null &&
        placeMenu.menuItems.isNotEmpty;

    final displayAmount = widget.display == Display.amount ||
        widget.display == Display.amountAndMenu ||
        (widget.display == Display.menu &&
            (placeMenu == null || placeMenu.menuItems.isEmpty));

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFD9D9D9),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          if (widget.display == null)
            SizedBox(
              height: 50,
              child: Center(
                child: CupertinoActivityIndicator(),
              ),
            ),
          if (hasMenu && _amount == null)
            WideButton(
              onPressed: handleMenuPress,
              disabled: false,
              child: Text(
                'Menu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          if (_amount != null)
            WideButton(
              onPressed: () => handlePay(tokenAddress: selectedToken?.address),
              disabled: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'QR Code / Card',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Image.asset(
                    'assets/icons/nfc.png',
                    width: 20,
                    height: 20,
                  ),
                ],
              ),
            ),
          if (_amount != null && supportsPayment) SizedBox(height: 10),
          if (_amount != null && supportsPayment)
            WideButton(
              onPressed: handlePayClient,
              disabled: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Debit / Credit Card',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.creditcard,
                    color: CupertinoColors.white,
                  ),
                ],
              ),
            ),
          SizedBox(height: 10),
          if (displayAmount && widget.place != null)
            TransactionInputRow(
              showAmountField: _showAmountField,
              amountController: _amountController,
              messageController: _messageController,
              amountFocusNode: widget.amountFocusNode,
              messageFocusNode: widget.messageFocusNode,
              onAmountChange: handleAmountChange,
              onToggleField: _toggleField,
              selectedToken: selectedToken,
              tokens: tokens,
              onTokenChange: handleTokenChange,
              // loading: paying,
              disabled: _amount == null,
              // error: error,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    Footer._amountControllers.remove(_amountController);
    Footer._messageControllers.remove(_messageController);
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
