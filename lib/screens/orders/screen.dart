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

//state
import 'package:pay_pos/state/orders.dart';
import 'package:pay_pos/state/place_order.dart';
import 'package:pay_pos/state/wallet.dart';
import 'package:provider/provider.dart';

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
    final account = await _placeOrderState.fetchPlaceandMenu();
    if (account != null) {
      _walletState.startBalancePolling(account);
    }

    _ordersState.fetchOrders();

    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _ordersState.fetchOrders();
    });
  }

  void goBack() {
    GoRouter.of(context).pop();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _walletState.stopBalancePolling();

    amountFocusNode.dispose();
    messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onPayPressed(
      String description, double total, String account) async {
    final orderId = await _ordersState.createOrder(
      items: [],
      description: description,
      total: total,
    );

    if (orderId == null) {
      return;
    }

    if (!mounted) return;

    final navigator = GoRouter.of(context);

    navigator.push('/${widget.placeId}/order/$orderId/pay', extra: {
      'amount': total,
      'description': description,
    });
  }

  void handleOrderPressed(Order order) {
    final navigator = GoRouter.of(context);

    navigator.push('/${widget.placeId}/order/${order.id}', extra: {
      'order': order,
    });
  }

  void sendMessage(double amount, String? message, String account) {
    _onPayPressed(message!, amount, account);
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final place = context.select((PlaceOrderState state) => state.place);

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
                      onPressed: handleOrderPressed,
                    );
                  },
                ),
              ),
              Footer(
                placeId: widget.placeId,
                onSend: sendMessage,
                amountFocusNode: amountFocusNode,
                messageFocusNode: messageFocusNode,
                display: Display.amountAndMenu,
                place: place.place,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
