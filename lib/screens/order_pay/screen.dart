import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pay_pos/theme/colors.dart';
import 'dart:async';

//models
import 'package:pay_pos/models/checkout.dart';

//state
import 'package:pay_pos/state/orders.dart';
import 'package:pay_pos/state/place_order.dart';
import 'package:pay_pos/state/checkout.dart';

//screens
import 'package:pay_pos/screens/order_pay/qrcode.dart';

//widgets
import 'package:pay_pos/widgets/wide_button.dart';

class OrderPayScreen extends StatefulWidget {
  final bool isMenu;
  final double amount;
  final String description;

  const OrderPayScreen({
    super.key,
    required this.isMenu,
    required this.amount,
    required this.description,
  });

  @override
  State<OrderPayScreen> createState() => _OrderPayScreenState();
}

class _OrderPayScreenState extends State<OrderPayScreen> {
  late OrdersState _ordersState;
  Timer? _statusCheckTimer;
  String _orderStatus = 'pending';
  bool _isLoading = false;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ordersState = context.read<OrdersState>();
      _ordersState.isPollingEnabled = false;
      checkStatusofOrder();
    });
  }

  void checkStatusofOrder() {
    checkOrderStatus();

    _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      checkOrderStatus();
    });
  }

  void clearCheckout() {
    final checkoutState = context.read<CheckoutState>();
    checkoutState.checkout = Checkout(items: []);
  }

  Future<void> checkOrderStatus() async {
    try {
      await _ordersState.checkOrderStatus(
        orderId: _ordersState.orderId.toString(),
      );

      if (mounted) {
        setState(() {
          _orderStatus = _ordersState.orderStatus;
        });

        if (_ordersState.orderStatus == 'paid') {
          _statusCheckTimer?.cancel();
          setState(() {
            _isLoading = true;
          });

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _showSuccess = true;
              });
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking order status: $e');
    }
  }

  Future<void> goBack(String orderId, String account, String placeId) async {
    _statusCheckTimer?.cancel();
    await _ordersState.deleteOrder(
      orderId: orderId,
      account: account,
    );

    clearCheckout();

    context.go('/$placeId');
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _ordersState.isPollingEnabled = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    final checkoutState = context.watch<CheckoutState>();

    final order = context.watch<OrdersState>();

    final place = context.watch<PlaceOrderState>();

    final checkout = checkoutState.checkout;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return CupertinoPageScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    QRCodeContent(
                      isMenu: widget.isMenu,
                      amount: widget.amount,
                      description: widget.description,
                      checkout: checkout,
                      orderId: order.orderId.toString(),
                      slug: place.slug,
                      width: screenWidth,
                      height: screenHeight,
                      checkoutState: checkoutState,
                      showSuccess: _showSuccess,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WideButton(
                    onPressed: () {
                      if (_orderStatus == 'paid') {
                        clearCheckout();

                        context.go('/${place.placeId}');
                      } else {
                        goBack(
                          order.orderId.toString(),
                          place.place!.place.account[0],
                          place.placeId,
                        );
                      }
                    },
                    color: surfaceDarkColor.withValues(alpha: 0.8),
                    child: Text(
                      _orderStatus == 'paid' ? 'Back to Orders' : 'Cancel',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
