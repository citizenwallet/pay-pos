import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:pay_pos/state/place_order.dart';

//models
import 'package:pay_pos/models/place.dart';

//widgets
import 'package:pay_pos/widgets/transaction_input_row.dart';
import 'package:pay_pos/widgets/wide_button.dart';
import 'package:provider/provider.dart';

class Footer extends StatefulWidget {
  final String placeId;
  final Function(double, String?, String) onSend;
  final FocusNode amountFocusNode;
  final FocusNode messageFocusNode;
  final Place? place;
  final Display? display;

  const Footer({
    super.key,
    required this.placeId,
    required this.onSend,
    required this.amountFocusNode,
    required this.messageFocusNode,
    this.place,
    this.display,
  });

  @override
  State<Footer> createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _showAmountField = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // widget.amountFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
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

  void _onMenuPressed() {
    context.go('/${widget.placeId}/menu');
  }

  @override
  Widget build(BuildContext context) {
    final placeMenu = context.watch<PlaceOrderState>().placeMenu;

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
          if (hasMenu)
            WideButton(
              onPressed: _onMenuPressed,
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
          if (widget.display == Display.amountAndMenu) SizedBox(height: 10),
          if (displayAmount && widget.place != null)
            TransactionInputRow(
              showAmountField: _showAmountField,
              amountController: _amountController,
              messageController: _messageController,
              amountFocusNode: widget.amountFocusNode,
              messageFocusNode: widget.messageFocusNode,
              onToggleField: _toggleField,
              onSend: () => widget.onSend(
                double.parse(_amountController.text),
                _messageController.text,
                widget.place!.account,
              ),
              // loading: paying,
              // disabled: disabled,
              // error: error,
            ),
        ],
      ),
    );
  }
}
