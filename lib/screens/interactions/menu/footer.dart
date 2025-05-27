import 'package:flutter/cupertino.dart';
import 'package:pay_pos/theme/colors.dart';
import 'package:toastification/toastification.dart';

//widgets
import 'package:pay_pos/widgets/coin_logo.dart';
import 'package:pay_pos/widgets/wide_button.dart';
import 'package:pay_pos/widgets/toast/toast.dart';

class Footer extends StatefulWidget {
  final double checkoutTotal;
  final Function() onPay;
  final Function() onBankCard;
  final Function() onCancel;

  const Footer({
    required this.checkoutTotal,
    required this.onPay,
    required this.onBankCard,
    required this.onCancel,
    super.key,
  });

  @override
  State<Footer> createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.checkoutTotal == 0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: dividerColor,
                width: 1,
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CoinLogo(
              size: 40,
            ),
            const SizedBox(width: 4),
            Text(
              widget.checkoutTotal.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: disabled ? textMutedColor : textColor,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          child: Row(
            children: [
              Expanded(
                child: WideButton(
                  onPressed: () => {
                    if (disabled)
                      {
                        toastification.showCustom(
                          context: context,
                          autoCloseDuration: const Duration(seconds: 2),
                          alignment: Alignment.bottomCenter,
                          builder: (context, toast) => Toast(
                            icon: const Icon(
                              CupertinoIcons.exclamationmark_circle_fill,
                              color: errorColor,
                            ),
                            title: const Text('Please select items first'),
                          ),
                        ),
                      }
                    else
                      {
                        widget.onPay(),
                      }
                  },
                  color: disabled
                      ? primaryColor.withValues(alpha: 0.8)
                      : primaryColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Brussels Pay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: disabled
                              ? CupertinoColors.white.withValues(alpha: 0.7)
                              : CupertinoColors.white,
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
              ),
              SizedBox(width: 4),
              Expanded(
                child: WideButton(
                  onPressed: () => {
                    if (disabled)
                      {
                        toastification.showCustom(
                          context: context,
                          autoCloseDuration: const Duration(seconds: 2),
                          alignment: Alignment.bottomCenter,
                          builder: (context, toast) => Toast(
                            icon: const Icon(
                              CupertinoIcons.exclamationmark_circle_fill,
                              color: errorColor,
                            ),
                            title: const Text('Please select items first'),
                          ),
                        ),
                      }
                    else
                      {
                        widget.onBankCard(),
                      }
                  },
                  color: disabled
                      ? primaryColor.withValues(alpha: 0.8)
                      : primaryColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Bank Card',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: disabled
                              ? CupertinoColors.white.withValues(alpha: 0.7)
                              : CupertinoColors.white,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        CupertinoIcons.creditcard,
                        color: disabled
                            ? CupertinoColors.white.withValues(alpha: 0.7)
                            : CupertinoColors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(
            10,
            0,
            10,
            10,
          ),
          child: WideButton(
            onPressed: widget.onCancel,
            color: surfaceDarkColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
