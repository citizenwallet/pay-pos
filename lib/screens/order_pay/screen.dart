import 'package:flutter/cupertino.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pay_pos/theme/colors.dart';
import 'package:pay_pos/widgets/coin_logo.dart';
import 'package:pay_pos/widgets/wide_button.dart';
import 'package:provider/provider.dart';
import 'package:pay_pos/state/checkout.dart';
import 'package:pay_pos/screens/interactions/menu/selected_items.dart';

class OrderPayScreen extends StatefulWidget {
  bool isMenu = false;

  OrderPayScreen({
    super.key,
    required this.isMenu,
  });

  @override
  State<OrderPayScreen> createState() => _OrderPayScreenState();
}

class _OrderPayScreenState extends State<OrderPayScreen> {

  void goBack() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    final checkoutState = context.watch<CheckoutState>();

    final checkout = checkoutState.checkout;

    return CupertinoPageScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Top content in an Expanded to push it to the center
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // QR Code
                        QrImageView(
                          data: "QR CODE",
                          version: QrVersions.auto,
                          size: 350,
                          gapless: false,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                        ),

                        // Logo on top of QR
                        Positioned(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                            ),
                            alignment: Alignment.center,
                            child: CoinLogo(size: 40),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Balance(
                          balance: checkout.total.toStringAsFixed(2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    !widget.isMenu
                        ? Text(
                            "This is a description of the order.",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : Container(
                            height: 280,
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: IntrinsicHeight(
                                      child: SelectedItems(
                                        checkoutState: checkoutState,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                    // const SizedBox(height: 20),

                    const SizedBox(height: 100),
                  ],
                ),
              ),

              // Bottom content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cancel Button
                  WideButton(
                    onPressed: goBack,
                    color: surfaceDarkColor.withValues(alpha: 0.8),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Balance extends StatelessWidget {
  final String balance;

  const Balance({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CoinLogo(size: 33),
        SizedBox(width: 4),
        Text(
          balance,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
