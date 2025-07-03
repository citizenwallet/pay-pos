import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

//models
import 'package:pay_pos/models/checkout.dart';

//screens
import 'package:pay_pos/screens/interactions/menu/selected_item_list.dart';
import 'package:pay_pos/services/config/config.dart';
import 'package:pay_pos/state/wallet.dart';

//widgets
import 'package:pay_pos/widgets/qr/qr.dart';
import 'package:pay_pos/widgets/coin_logo.dart';

//state
import 'package:provider/provider.dart';

class QRCodeContent extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final double amount;
  final String description;
  final String checkoutUrl;
  final Checkout checkout;
  final double width;
  final double height;
  final bool showSuccess;
  final bool isLoading;

  const QRCodeContent({
    super.key,
    required this.items,
    required this.amount,
    required this.description,
    required this.checkoutUrl,
    required this.checkout,
    required this.width,
    required this.height,
    this.showSuccess = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    final selectedToken = context
        .select<WalletState, TokenConfig?>((state) => state.selectedToken);

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
                  "Paid",
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
              Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: QR(
                      data: checkoutUrl,
                      logo: selectedToken?.logo ?? 'assets/logo.png',
                      size: (width * 0.75),
                      padding: const EdgeInsets.all(20),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    child: Container(
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
              logo: selectedToken?.logo,
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
                          child: SelectedItemsList(),
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
  final String? logo;

  const Balance({
    super.key,
    required this.balance,
    required this.fontSize,
    required this.logoSize,
    this.logo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CoinLogo(size: logoSize, logo: logo),
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
