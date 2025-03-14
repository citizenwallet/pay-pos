import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:pay_pos/models/place.dart';
import 'package:pay_pos/models/user.dart';
import 'package:pay_pos/screens/interactions/order_list_item.dart';
import 'package:pay_pos/screens/order/footer.dart';
import 'package:pay_pos/screens/order/profile_bar.dart';
import 'package:pay_pos/state/orders.dart';
import 'package:pay_pos/state/place_order.dart';
import 'package:pay_pos/state/profile.dart';
import 'package:pay_pos/state/wallet.dart';
import 'package:provider/provider.dart';

class OrderScreen extends StatefulWidget {
  final String placeId;

  const OrderScreen({
    super.key,
    required this.placeId,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final ScrollController _scrollController = ScrollController();
  FocusNode amountFocusNode = FocusNode();
  FocusNode messageFocusNode = FocusNode();

  bool isKeyboardVisible = false;

  // double _scrollOffset = 0.0;
  // final double _maxScrollOffset = 100.0;

  late WalletState _walletState;
  // late ProfileState _profileState;
  late OrdersState _ordersState;
  late PlaceOrderState _placeOrderState;

  @override
  void initState() {
    super.initState();

    // _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ordersState = context.read<OrdersState>();
      _walletState = context.read<WalletState>();
      // _profileState = context.read<ProfileState>();
      _placeOrderState = context.read<PlaceOrderState>();
      onLoad();
    });
  }

  Future<void> onLoad() async {
    print("fetching place and menu");
    await _placeOrderState.fetchPlaceandMenu();
    print("place and menu fetched");

    print("fetching orders");
    await _ordersState.fetchOrders();
    print("orders fetched");

    print("fetching balance");
    // await _walletState.updateBalance();
    print("balance fetched");

    // _interactionState.startPolling(updateBalance: _walletState.updateBalance);
  }

  // void _onAmountFocus() {
  //   if (amountFocusNode.hasFocus) {
  //     Future.delayed(
  //       const Duration(milliseconds: 500),
  //       () {
  //         scrollToTop();
  //       },
  //     );
  //   }
  // }

  // void _onMessageFocus() {
  //   if (messageFocusNode.hasFocus) {
  //     Future.delayed(
  //       const Duration(milliseconds: 500),
  //       () {
  //         // scrollToTop();
  //       },
  //     );
  //   }
  // }

  // list is shown in reverse order, so we need to scroll to the top
  // void scrollToTop() {
  //   _scrollController.animateTo(
  //     0,
  //     duration: const Duration(milliseconds: 500),
  //     curve: Curves.fastOutSlowIn,
  //   );
  // }

  void goBack() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    // _interactionState.stopPolling();

    // amountFocusNode.removeListener(_onAmountFocus);
    // messageFocusNode.removeListener(_onMessageFocus);
    amountFocusNode.dispose();
    messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
    // _scrollController.removeListener(_scrollListener);

    // super.dispose();
  }

  // void _scrollListener() {
  //   // Hide on scroll down
  //   if (_scrollController.position.userScrollDirection ==
  //       ScrollDirection.reverse) {
  //     setState(() {
  //       _scrollOffset = _scrollController.offset.clamp(0, _maxScrollOffset);
  //     });
  //   }

  //   // Show on scroll up
  //   if (_scrollController.position.userScrollDirection ==
  //       ScrollDirection.forward) {
  //     setState(() {
  //       _scrollOffset = 0;
  //     });
  //   }
  // }

  // List<Order> orders = (json['orders'] as List)
  //     .map((order) => Order.fromJson(order))
  //     .toList();

//   final List<Order> orders = [
// ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

// final List<Order> orderList = [];

  void _onPayPressed() {
    final navigator = GoRouter.of(context);

    navigator.push('/${widget.placeId}/false/pay');
  }

  void sendMessage(double amount, String? message) {
    _onPayPressed();
    // final last = orders.last;

    // setState(() {
    //   orders.add(Order(
    //     type: OrderType.app,
    //     id: last.id + 1,
    //     txHash:
    //         '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
    //     createdAt: DateTime.now(),
    //     account: EthereumAddress.fromHex('0xUserWallet123'),
    //     description: message,
    //     status: OrderStatus.success,
    //   ));
    // });

    // Future.delayed(
    //   const Duration(milliseconds: 100),
    //   () {
    //     scrollToTop();
    //   },
    // );
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final place = context.select((PlaceOrderState state) => state.place);
    
    final orders = context.select((OrdersState state) => state.orders);

    

    // final userProfile =
    //     context.select((ProfileState state) => state.userProfile);

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
                userProfile: place.profile,
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
                      mappedItems: place?.mappedItems ?? {},
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
                place: null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileBarDelegate extends SliverPersistentHeaderDelegate {
  final User user;

  ProfileBarDelegate({required this.user});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ProfileBar(
      userProfile: user,
      // place: places[0],
    );
  }

  @override
  double get maxExtent => 95.0; // Maximum height of header

  @override
  double get minExtent => 95.0; // Minimum height of header

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
