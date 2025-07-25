import 'package:flutter/cupertino.dart';
import 'package:pay_pos/services/config/config.dart';
import 'package:pay_pos/theme/colors.dart';
import 'package:pay_pos/utils/formatters.dart';
import 'package:pay_pos/widgets/coin_logo.dart';
import 'package:pay_pos/widgets/text_field.dart';

class TransactionInputRow extends StatelessWidget {
  final bool showAmountField;
  final TextEditingController amountController;
  final TextEditingController messageController;
  final FocusNode amountFocusNode;
  final FocusNode messageFocusNode;
  final Function(double)? onAmountChange;
  final Function(String)? onMessageChange;
  final VoidCallback onToggleField;
  final TokenConfig? selectedToken;
  final List<TokenConfig> tokens;
  final Function(TokenConfig) onTokenChange;
  final bool loading;
  final bool disabled;
  final bool error;
  final Function()? onTopUpPressed;

  const TransactionInputRow({
    super.key,
    required this.showAmountField,
    required this.amountController,
    required this.messageController,
    required this.amountFocusNode,
    required this.messageFocusNode,
    this.onAmountChange,
    this.onMessageChange,
    required this.onToggleField,
    required this.selectedToken,
    required this.tokens,
    required this.onTokenChange,
    this.loading = false,
    this.disabled = false,
    this.error = false,
    this.onTopUpPressed,
  });

  void handleShowTokenSelector(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Container(
                height: 50,
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Select Token',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(
                      width: 44,
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: tokens.length,
                  itemBuilder: (context, index) {
                    final token = tokens[index];
                    final isSelected = selectedToken?.symbol == token.symbol;

                    return GestureDetector(
                      onTap: () {
                        onTokenChange(token);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? CupertinoColors.systemBlue.withOpacity(0.1)
                              : null,
                          border: Border(
                            bottom: BorderSide(
                              color: CupertinoColors.systemGrey5,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            CoinLogo(size: 22, logo: token.logo),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                token.symbol,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? CupertinoColors.systemBlue
                                      : null,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                CupertinoIcons.check_mark,
                                color: CupertinoColors.systemBlue,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!showAmountField)
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: disabled ? null : onToggleField,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  CupertinoIcons.back,
                  color: disabled ? mutedColor : primaryColor,
                  size: 35,
                ),
              ),
            ),
          ),
        Expanded(
          child: showAmountField
              ? AmountFieldWithMessageToggle(
                  disabled: disabled || loading,
                  error: error,
                  amountController: amountController,
                  focusNode: amountFocusNode,
                  onChange: onAmountChange ?? (_) {},
                  onTopUpPressed: onTopUpPressed ?? () {},
                  selectedToken: selectedToken,
                  tokens: tokens,
                  handleShowTokenSelector: handleShowTokenSelector,
                )
              : MessageFieldWithAmountToggle(
                  messageController: messageController,
                  focusNode: messageFocusNode,
                  onChange: onMessageChange ?? (_) {},
                  isSending: loading,
                ),
        ),
        SizedBox(width: 10),
        ToggleButton(
          loading: loading,
          disabled: disabled,
          showingAmountField: showAmountField,
          onToggle: onToggleField,
        ),
      ],
    );
  }
}

class ToggleButton extends StatelessWidget {
  final VoidCallback onToggle;
  final bool showingAmountField;
  final bool loading;
  final bool disabled;

  const ToggleButton({
    super.key,
    required this.onToggle,
    this.disabled = false,
    this.showingAmountField = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (disabled) {
      return SizedBox.shrink();
    }

    if (loading) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: disabled ? mutedColor : primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: CupertinoActivityIndicator(
            color: whiteColor,
          ),
        ),
      );
    }

    if (showingAmountField) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: disabled ? null : onToggle,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              CupertinoIcons.forward,
              color: disabled ? mutedColor : primaryColor,
              size: 35,
            ),
          ),
        ),
      );
    }

    return SizedBox.shrink();
  }
}

class AmountFieldWithMessageToggle extends StatelessWidget {
  final TextEditingController amountController;
  final FocusNode focusNode;
  final AmountFormatter amountFormatter = AmountFormatter();
  final Function(double) onChange;
  final Function()? onTopUpPressed;
  final bool isSending;
  final bool disabled;
  final bool error;
  final TokenConfig? selectedToken;
  final List<TokenConfig> tokens;
  final Function(BuildContext) handleShowTokenSelector;

  AmountFieldWithMessageToggle({
    super.key,
    required this.amountController,
    required this.focusNode,
    required this.onChange,
    this.isSending = false,
    this.disabled = false,
    this.error = false,
    this.onTopUpPressed,
    required this.selectedToken,
    required this.tokens,
    required this.handleShowTokenSelector,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              CustomTextField(
                controller: amountController,
                enabled: !isSending,
                isError: error,
                placeholder: 'Enter amount',
                placeholderStyle: TextStyle(
                  color: Color(0xFFB7ADC4),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                style: TextStyle(
                  fontSize: 24,
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
                  child: tokens.length > 1
                      ? CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => handleShowTokenSelector(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CoinLogo(size: 33, logo: selectedToken?.logo),
                              SizedBox(width: 4),
                              Icon(
                                CupertinoIcons.chevron_down,
                                size: 16,
                                color: disabled ? mutedColor : primaryColor,
                              ),
                            ],
                          ),
                        )
                      : CoinLogo(size: 33, logo: selectedToken?.logo),
                ),
                onChanged: (value) {
                  if (value.isEmpty) {
                    onChange(0);
                    return;
                  }
                  onChange(double.tryParse(value.replaceAll(',', '.')) ?? 0);
                },
              ),
              if (error && onTopUpPressed != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: onTopUpPressed,
                      child: Text(
                        '+ top up',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
      ],
    );
  }
}

class MessageFieldWithAmountToggle extends StatelessWidget {
  final TextEditingController messageController;
  final FocusNode focusNode;
  final Function(String) onChange;
  final bool isSending;

  const MessageFieldWithAmountToggle({
    super.key,
    required this.messageController,
    required this.focusNode,
    required this.onChange,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
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
            onChanged: onChange,
          ),
        ),
      ],
    );
  }
}
