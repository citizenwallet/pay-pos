import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

//models
import 'package:pay_pos/screens/settings/settings_profile_bar.dart';
import 'package:pay_pos/services/pay/localstorage.dart';
import 'package:pay_pos/state/orders.dart';

//state
import 'package:pay_pos/state/place_order.dart';
import 'package:pay_pos/state/pos.dart';
import 'package:pay_pos/theme/colors.dart';
import 'package:pay_pos/widgets/settings_row.dart';
import 'package:pay_pos/widgets/wide_button.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/credentials.dart';

class SettingsScreen extends StatefulWidget {
  // final String posId;

  const SettingsScreen({
    super.key,
    // required this.posId,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;

  late PlaceOrderState _placeOrderState;
  late OrdersState _ordersState;
  late POSState _posState;
  final localStorage = LocalStorageService();
  // late NotificationsLogic _notificationsLogic;

  @override
  void initState() {
    super.initState();

    _placeOrderState = context.read<PlaceOrderState>();
    _ordersState = context.read<OrdersState>();
    _ordersState.isPollingEnabled = false;
    _posState = context.read<POSState>();

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _placeOrderState = context.read<PlaceOrderState>();
    //   _ordersState = context.read<OrdersState>();
    //   _ordersState.isPollingEnabled = false;
    //   _posState = context.read<POSState>();
    //   // _notificationsLogic = NotificationsLogic(context);
    //   // onLoad();
    // });
  }

  // Future<void> onLoad() async {
  //   await _placeOrderState.fetchPlaceandMenu();
  // }

  void goBack(String placeId) {
    context.go('/$placeId');
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _ordersState.isPollingEnabled = true;
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onDeactivatePressed() async {
    final pk = await localStorage.getPvtKey();
    if (pk != null) {
      final posId = EthPrivateKey.fromHex(pk).address.hexEip55;

      await _posState.updatePOS(posId: posId);
    }

    await localStorage.clearPosId();
    await localStorage.clearPin();
    await localStorage.clearPvtKey();

    context.go('/');
  }

  void sendMessage(double amount, String? message) {
    // final account = _placeOrderState.place?.profile.account;

    // _onPayPressed(message!, amount, account!);
  }

  void handleTogglePushNotifications(bool enabled) {
    // _notificationsLogic.togglePushNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final place = context.select((PlaceOrderState state) => state.place);

    // final push = context.select((NotificationsState state) => state.push);

    if (place == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Column(
            children: [
              SettingsProfileBar(
                userProfile: place.place,
                height: screenHeight * 0.25,
                onTapLeading: () => goBack(place.place.id.toString()),
              ),
              SizedBox(height: screenHeight * 0.05),
              // Container(
              //   color: CupertinoColors.systemGrey,
              //   height: screenHeight * 0.45,
              // ),
              SettingsRow(
                label: "Languages",
                icon: 'assets/icons/language-svgrepo-com.svg',
                iconColor: CupertinoColors.systemGrey,
                onTap: () {},
                // => {handleLanguage(selectedLanguage)},
                // trailing: Row(
                //   children: [
                //     Text(
                //       languageOptions[selectedLanguage].name,
                //       style: TextStyle(
                //         color: Theme.of(context)
                //             .colors
                //             .subtleSolidEmphasis
                //             .resolveFrom(context),
                //       ),
                //     ),
                //     const SizedBox(
                //       width: 10,
                //     )
                //   ],
                // ),
              ),
              SettingsRow(
                label: "Theme",
                icon: 'assets/icons/',
                iconColor: CupertinoColors.systemGrey,
                onTap: () {},
                // => {handleLanguage(selectedLanguage)},
                // trailing: Row(
                //   children: [
                //     Text(
                //       languageOptions[selectedLanguage].name,
                //       style: TextStyle(
                //         color: Theme.of(context)
                //             .colors
                //             .subtleSolidEmphasis
                //             .resolveFrom(context),
                //       ),
                //     ),
                //     const SizedBox(
                //       width: 10,
                //     )
                //   ],
                // ),
              ),
              SizedBox(height: screenHeight * 0.05),
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.02,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Color(0xFFD9D9D9),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WideButton(
                      onPressed: _onDeactivatePressed,
                      color: surfaceDarkColor.withValues(alpha: 1),
                      child: Text(
                        'Deactivate Terminal',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w700,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class ProfileBarDelegate extends SliverPersistentHeaderDelegate {
//   final User user;

//   ProfileBarDelegate({required this.user});

//   @override
//   Widget build(
//       BuildContext context, double shrinkOffset, bool overlapsContent) {
//     return SettingsProfileBar(
//       userProfile: user,
//       height: screenHeight * 0.3,
//     );
//   }

//   @override
//   double get maxExtent => 95.0; // Maximum height of header

//   @override
//   double get minExtent => 95.0; // Minimum height of header

//   @override
//   bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
//       true;
// }
