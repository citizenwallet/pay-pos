import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
import 'package:pay_pos/screens/orders/footer.dart';

//widgets
import 'package:pay_pos/widgets/wide_button.dart';

class OrderPayScreen extends StatefulWidget {
  final String placeId;
  final List<Map<String, dynamic>> items;
  final double amount;
  final String description;

  const OrderPayScreen({
    super.key,
    required this.placeId,
    required this.items,
    required this.amount,
    required this.description,
  });

  @override
  State<OrderPayScreen> createState() => _OrderPayScreenState();
}

class _OrderPayScreenState extends State<OrderPayScreen> {
  final checkoutBaseurl = dotenv.env['CHECKOUT_BASE_URL'];

  late OrdersState _ordersState;
  Timer? _statusCheckTimer;
  Timer? _delayedCloseFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ordersState = context.read<OrdersState>();
      _ordersState.isPollingEnabled = false;
      onLoad();
    });
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _ordersState.isPollingEnabled = true;
    _ordersState.clearOrder();
    super.dispose();
  }

  void onLoad() {
    _ordersState.checkOrderStatus(onSuccess: handleSuccess);

    _statusCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _ordersState.checkOrderStatus(onSuccess: handleSuccess);
    });
  }

  void handleSuccess() {
    _statusCheckTimer?.cancel();

    _delayedCloseFuture = Timer(const Duration(seconds: 10), () {
      clearCheckout();

      if (mounted) {
        context.go('/${widget.placeId}');
      }
    });
  }

  void clearCheckout() {
    final checkoutState = context.read<CheckoutState>();
    checkoutState.checkout = Checkout(
      items: [],
    );

    Footer.clearControllers();
  }

  Future<void> _handleCancel(String orderId, {bool cancel = false}) async {
    _statusCheckTimer?.cancel();
    _delayedCloseFuture?.cancel();

    if (cancel) {
      await _ordersState.deleteOrder(
        orderId: orderId,
      );
    }

    clearCheckout();

    context.go('/${widget.placeId}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    final loading = context.select<OrdersState, bool>((state) => state.loading);

    final orderId = context.select<OrdersState, int?>((state) => state.orderId);
    final orderStatus =
        context.select<OrdersState, String>((state) => state.orderStatus);

    final slug = context.select<PlaceOrderState, String>((state) => state.slug);

    final checkout =
        context.select<CheckoutState, Checkout>((state) => state.checkout);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (orderId == null) {
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CupertinoActivityIndicator(),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WideButton(
                      onPressed: () {
                        _handleCancel(
                          orderId.toString(),
                          cancel: orderStatus == 'pending',
                        );
                      },
                      color: surfaceDarkColor.withValues(alpha: 0.8),
                      child: Text(
                        'Cancel',
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
                      items: widget.items,
                      amount: widget.amount,
                      description: widget.description,
                      checkoutUrl: '$checkoutBaseurl/$slug?orderId=$orderId',
                      checkout: checkout,
                      width: screenWidth,
                      height: screenHeight,
                      showSuccess: orderStatus == 'paid' && !loading,
                      isLoading: orderStatus == 'pending' && !loading,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WideButton(
                    onPressed: () {
                      if (orderStatus == 'paid') {
                        clearCheckout();

                        context.go('/${widget.placeId}');
                      } else {
                        _handleCancel(
                          orderId.toString(),
                          cancel: orderStatus == 'pending',
                        );
                      }
                    },
                    color: surfaceDarkColor.withValues(alpha: 0.8),
                    child: Text(
                      orderStatus == 'paid' ? 'Back to Orders' : 'Cancel',
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
