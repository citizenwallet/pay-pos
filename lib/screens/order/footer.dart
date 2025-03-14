import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:pay_pos/models/place.dart';
import 'package:pay_pos/state/wallet.dart';
import 'package:pay_pos/utils/formatters.dart';
import 'package:pay_pos/widgets/coin_logo.dart';
import 'package:pay_pos/widgets/text_field.dart';
import 'package:pay_pos/widgets/wide_button.dart';
import 'package:provider/provider.dart';

class Footer extends StatefulWidget {
  final String placeId;
  final Function(double, String?) onSend;
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
      widget.amountFocusNode.requestFocus();
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
    final navigator = GoRouter.of(context);

    navigator.push('/${widget.placeId}/menu');
  }

  @override
  Widget build(BuildContext context) {
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
          if (widget.display == Display.menu ||
              widget.display == Display.amountAndMenu)
            WideButton(
              onPressed: _onMenuPressed,
              child: Text(
                'Menu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          SizedBox(height: 15),
          if (widget.display == Display.amount ||
              widget.display == Display.amountAndMenu)
            Row(
              children: [
                Expanded(
                  child: _showAmountField
                      ? AmountFieldWithMessageToggle(
                          onToggle: _toggleField,
                          amountController: _amountController,
                          focusNode: widget.amountFocusNode,
                        )
                      : MessageFieldWithAmountToggle(
                          onToggle: _toggleField,
                          messageController: _messageController,
                          focusNode: widget.messageFocusNode,
                        ),
                ),
                SizedBox(width: 10),
                SendButton(
                  amountController: _amountController,
                  messageController: _messageController,
                  onTap: () => widget.onSend(
                    double.parse(_amountController.text),
                    _messageController.text,
                  ),
                ),
              ],
            ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}

class SendButton extends StatelessWidget {
  final VoidCallback onTap;
  final TextEditingController amountController;
  final TextEditingController messageController;

  const SendButton({
    super.key,
    required this.onTap,
    required this.amountController,
    required this.messageController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        onTap();
        amountController.clear();
        messageController.clear();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            CupertinoIcons.arrow_down,
            color: CupertinoColors.white,
            size: 35,
          ),
        ),
      ),
    );
  }
}

class AmountFieldWithMessageToggle extends StatelessWidget {
  final TextEditingController amountController;
  final FocusNode focusNode;
  final VoidCallback onToggle;
  final AmountFormatter amountFormatter = AmountFormatter();
  final bool isSending;

  AmountFieldWithMessageToggle({
    super.key,
    required this.onToggle,
    required this.amountController,
    required this.focusNode,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: CustomTextField(
            controller: amountController,
            enabled: !isSending,
            placeholder: 'Enter amount',
            placeholderStyle: TextStyle(
              color: Color(0xFFB7ADC4),
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
            padding: EdgeInsets.symmetric(horizontal: 11.0, vertical: 12.0),
            maxLines: 1,
            maxLength: 25,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.numberWithOptions(
              decimal: true,
              signed: false,
            ),
            inputFormatters: [amountFormatter],
            focusNode: focusNode,
            textInputAction: TextInputAction.done,
            prefix: Padding(
              padding: EdgeInsets.only(left: 11.0),
              child: CoinLogo(size: 33),
            ),
          ),
        ),
        SizedBox(width: 10),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onToggle,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                CupertinoIcons.text_bubble,
                color: theme.primaryColor,
                size: 35,
              ),
            ),
          ),
        )
      ],
    );
  }
}

class MessageFieldWithAmountToggle extends StatelessWidget {
  final VoidCallback onToggle;
  final TextEditingController messageController;
  final FocusNode focusNode;
  final bool isSending;

  const MessageFieldWithAmountToggle({
    super.key,
    required this.onToggle,
    required this.messageController,
    required this.focusNode,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: CustomTextField(
            controller: messageController,
            enabled: !isSending,
            placeholder: 'Add a message',
            placeholderStyle: TextStyle(
              color: Color(0xFFB7ADC4),
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
            textAlignVertical: TextAlignVertical.top,
            focusNode: focusNode,
            autocorrect: true,
            enableSuggestions: true,
            keyboardType: TextInputType.multiline,
          ),
        ),
        SizedBox(width: 10),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onToggle,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                CupertinoIcons.back,
                color: theme.primaryColor,
              ),
            ),
          ),
        )
      ],
    );
  }
}
