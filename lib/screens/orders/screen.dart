import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

//models
import 'package:pay_pos/models/place.dart';
import 'package:pay_pos/models/order.dart';

//screens
import 'package:pay_pos/screens/orders/footer.dart';
import 'package:pay_pos/screens/orders/order_list_item.dart';
import 'package:pay_pos/screens/orders/profile_bar.dart';
import 'package:pay_pos/services/config/config.dart';

//state
import 'package:pay_pos/state/orders.dart';
import 'package:pay_pos/state/place_order.dart';
import 'package:pay_pos/state/wallet.dart';
import 'package:pay_pos/utils/delay.dart';
import 'package:pay_pos/widgets/toast/toast.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

class OrdersScreen extends StatefulWidget {
  final String placeId;

  const OrdersScreen({
    super.key,
    required this.placeId,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ScrollController _scrollController = ScrollController();
  FocusNode amountFocusNode = FocusNode();
  FocusNode messageFocusNode = FocusNode();
  Timer? _pollingTimer;
  Timer? _backTimer;

  bool isKeyboardVisible = false;

  late WalletState _walletState;
  late OrdersState _ordersState;
  late PlaceOrderState _placeOrderState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _walletState = context.read<WalletState>();
      _ordersState = context.read<OrdersState>();
      _placeOrderState = context.read<PlaceOrderState>();
      onLoad();
    });
  }

  Future<void> onLoad() async {
    await _placeOrderState.fetchPlaceandMenu();

    startPolling();
  }

  void startPolling({String? tokenAddress}) async {
    await delay(const Duration(milliseconds: 300));

    final token = tokenAddress ?? _walletState.selectedToken?.address;
    if (token != null) {
      _ordersState.startPosTotalPolling(token);
    }

    _ordersState.fetchOrders();

    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _ordersState.fetchOrders();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _ordersState.stopPosTotalPolling();
  }

  void goBack() {
    GoRouter.of(context).pop();
  }

  @override
  void dispose() {
    stopPolling();

    amountFocusNode.dispose();
    messageFocusNode.dispose();
    _scrollController.dispose();

    _backTimer?.cancel();
    super.dispose();
  }

  void handlePayError(Exception e) {
    if (e is InsufficientBalanceException) {
      toastification.showCustom(
        context: context,
        autoCloseDuration: const Duration(seconds: 5),
        alignment: Alignment.bottomCenter,
        builder: (context, toast) => Toast(
          icon: const Icon(
            CupertinoIcons.xmark_circle_fill,
            color: errorColor,
          ),
          title: const Text('Insufficient balance'),
        ),
      );

      _backTimer = Timer(const Duration(seconds: 5), () {
        goBack();
      });
    }
  }

  void handlePay(double total, String? description, String account,
      {String? tokenAddress}) async {
    stopPolling();

    _ordersState.createOrder(
      items: [],
      description: description ?? '',
      total: total,
      tokenAddress: tokenAddress,
      onError: handlePayError,
    );

    if (!mounted) {
      startPolling();
      return;
    }

    final navigator = GoRouter.of(context);

    amountFocusNode.unfocus();
    messageFocusNode.unfocus();

    await navigator.push('/${widget.placeId}/order/pay', extra: {
      'amount': total,
      'description': description,
    });

    startPolling();
  }

  void handlePayClient(double total) async {
    _ordersState.openPayClient(widget.placeId, total);
  }

  void handleOrderPressed(Order order) async {
    final navigator = GoRouter.of(context);

    stopPolling();

    await navigator.push('/${widget.placeId}/order/${order.id}', extra: {
      'order': order,
    });

    startPolling();
  }

  void handleTokenChange(TokenConfig token) {
    _walletState.setSelectedToken(token);
    startPolling(tokenAddress: token.address);
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final place = context.select((PlaceOrderState state) => state.place);

    final tokenConfigs =
        context.select((WalletState state) => state.tokenConfigs);

    final orders = context.select((OrdersState state) => state.orders);

    if (place == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: GestureDetector(
        onTap: _dismissKeyboard,
        child: SafeArea(
          child: Column(
            children: [
              ProfileBar(
                place: place.place,
              ),
              Expanded(
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return OrderListItem(
                      key: Key('order-${order.id}'),
                      order: order,
                      mappedItems: place.mappedItems,
                      tokenConfigs: tokenConfigs,
                      onPressed: handleOrderPressed,
                    );
                  },
                ),
              ),
              Footer(
                placeId: widget.placeId,
                onPay: handlePay,
                onPayClient: handlePayClient,
                amountFocusNode: amountFocusNode,
                messageFocusNode: messageFocusNode,
                display: Display.amountAndMenu,
                place: place.place,
                onTokenChange: handleTokenChange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
