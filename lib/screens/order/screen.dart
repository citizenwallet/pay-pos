import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

//models
import 'package:pay_pos/models/place.dart';
import 'package:pay_pos/models/user.dart';

//screens
import 'package:pay_pos/screens/interactions/order_list_item.dart';
import 'package:pay_pos/screens/order/footer.dart';
import 'package:pay_pos/screens/order/profile_bar.dart';
import 'package:pay_pos/services/pay/localstorage.dart';

//state
import 'package:pay_pos/state/orders.dart';
import 'package:pay_pos/state/place_order.dart';
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
  Timer? _pollingTimer;

  bool isKeyboardVisible = false;

  late WalletState _walletState;
  late OrdersState _ordersState;
  late PlaceOrderState _placeOrderState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ordersState = context.read<OrdersState>();
      _walletState = context.read<WalletState>();
      _placeOrderState = context.read<PlaceOrderState>();
      onLoad();
      startPolling();
    });
  }

  void startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _ordersState.fetchOrders();
      _walletState.updateBalance(
          addr: _placeOrderState.place?.place.account[0]);
    });
  }

  Future<void> onLoad() async {
    await _placeOrderState.fetchPlaceandMenu();
    await _ordersState.fetchOrders();
    await _walletState.openWallet();
    await _walletState.updateBalance(
        addr: _placeOrderState.place?.place.account[0]);
  }

  void goBack() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();

    amountFocusNode.dispose();
    messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onPayPressed(
      String description, double total, String account) async {
    await _ordersState.createOrder(
      items: [],
      description: description,
      total: total,
      account: account,
    );

    context.go('/${widget.placeId}/order/pay', extra: {
      'amount': total,
      'description': description,
    });
  }

  void sendMessage(double amount, String? message) {
    final account = _placeOrderState.place?.place.account[0];

    _onPayPressed(message!, amount, account!);
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.width;

    final place = context.select((PlaceOrderState state) => state.place);

    print(place);

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
              GestureDetector(
                onTap: () {
                  showPinEntryDialog(
                    context,
                    widget.placeId,
                    screenHeight * 0.02,
                  );
                },
                child: ProfileBar(
                  place: place.place,
                ),
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
                      width: screenWidth * 0.65,
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
  final Place user;

  ProfileBarDelegate({required this.user});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ProfileBar(
      place: user,
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

Future<void> showPinEntryDialog(
  BuildContext context,
  String placeId,
  double height,
) async {
  List<TextEditingController> controllers =
      List.generate(4, (index) => TextEditingController());
  List<FocusNode> focusNodes = List.generate(4, (index) => FocusNode());

  await showCupertinoDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return CupertinoAlertDialog(
        title: Text("Enter PIN"),
        content: Column(
          children: [
            SizedBox(height: height),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  width: 40,
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  child: CupertinoTextField(
                    controller: controllers[index],
                    focusNode: focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: CupertinoColors.systemGrey,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 3) {
                        focusNodes[index + 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () async {
              String enteredPin =
                  controllers.map((controller) => controller.text).join();
              if (enteredPin.length == 4) {
                bool verify = await LocalStorageService().verifyPin(enteredPin);

                if (verify) {
                  Navigator.pop(context);

                  context.go('/$placeId/settings');
                } else {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: Text("Invalid PIN"),
                      content: Text("Enter a valid 4-digit PIN"),
                      actions: [
                        CupertinoDialogAction(
                          child: Text("OK"),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                }
              } else {
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: Text("Invalid PIN"),
                    content: Text("Enter a valid 4-digit PIN"),
                    actions: [
                      CupertinoDialogAction(
                        child: Text("OK"),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              }
            },
            child: Text("Confirm"),
          ),
        ],
      );
    },
  );
}
