// beforePayment.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pay_pos/screens/interactions/menu/selected_item_list.dart';
import 'package:pay_pos/widgets/qr/qr.dart';
import 'package:qr_flutter/qr_flutter.dart';

//models
import 'package:pay_pos/models/checkout.dart';

//widgets
import 'package:pay_pos/widgets/coin_logo.dart';

//state
import 'package:pay_pos/state/checkout.dart';

//screens
import 'package:pay_pos/screens/interactions/menu/selected_items.dart';

class QRCodeContent extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final double amount;
  final String description;
  final Checkout checkout;
  final CheckoutState checkoutState;
  final String orderId;
  final String slug;
  final double width;
  final double height;
  final bool showSuccess;
  final bool isLoading;

  const QRCodeContent({
    super.key,
    required this.items,
    required this.amount,
    required this.description,
    required this.checkout,
    required this.checkoutState,
    required this.orderId,
    required this.slug,
    required this.width,
    required this.height,
    this.showSuccess = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return Column(
      children: [
        if (showSuccess)
          Container(
            width: (width * 0.75),
            height: (width * 0.75),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  size: (width * 0.75) * 0.6,
                  color: CupertinoColors.activeGreen,
                ),
                Text(
                  "Payment Received!",
                  style: TextStyle(
                    fontSize: (width * 0.75) * 0.1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else if (isLoading)
          Container(
            width: (width * 0.75) * 0.5,
            height: (width * 0.75) * 0.5,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.primaryColor,
              ),
              backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
            ),
          )
        else
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Scan to pay",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    SizedBox(
                      width: (width * 0.75) * 0.05,
                      height: (width * 0.75) * 0.06,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  QR(
                    data:
                        "${dotenv.env['CHECKOUT_BASE_URL']}/$slug?orderId=$orderId",
                    logo: 'assets/logo.png',
                    size: (width * 0.75),
                    padding: const EdgeInsets.all(14),
                  ),
                  Positioned(
                    child: Container(
                      width: (width * 0.15),
                      height: (width * 0.15),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(
                          (width * 0.15) / 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: CoinLogo(
                        size: (width * 0.1),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        SizedBox(height: height * 0.03),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Balance(
              balance: items.isEmpty
                  ? amount.toStringAsFixed(2)
                  : checkout.total.toStringAsFixed(2),
              fontSize: (width * 0.065),
              logoSize: (width * 0.15),
            ),
          ],
        ),
        SizedBox(height: height * 0.03),
        items.isEmpty
            ? Text(
                description,
                style: TextStyle(
                  fontSize: (width * 0.04),
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              )
            : Container(
                height: height * 0.30,
                padding: EdgeInsets.all(8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: SelectedItemsList(
                            checkoutState: checkoutState,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }
}

class Balance extends StatelessWidget {
  final String balance;
  final double fontSize;
  final double logoSize;

  const Balance({
    super.key,
    required this.balance,
    required this.fontSize,
    required this.logoSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CoinLogo(size: logoSize),
        SizedBox(width: 4),
        Text(
          balance,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
