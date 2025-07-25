import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pay_pos/state/onboarding.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:pay_pos/theme/colors.dart';

//states
import 'package:pay_pos/state/orders.dart';
import 'package:pay_pos/state/place_order.dart';
import 'package:pay_pos/state/pos.dart';

//screens
import 'package:pay_pos/screens/settings/settings_profile_bar.dart';

//widgets
import 'package:pay_pos/widgets/settings_row.dart';
import 'package:pay_pos/widgets/wide_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
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
  late OnboardingState _onboardingState;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _placeOrderState = context.read<PlaceOrderState>();
      _ordersState = context.read<OrdersState>();
      _posState = context.read<POSState>();
      _onboardingState = context.read<OnboardingState>();

      onLoad();
    });
  }

  void onLoad() {
    _ordersState.isPollingEnabled = false;
  }

  void goBack(String placeId) {
    context.go('/$placeId');
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _ordersState.enablePolling();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onDeactivatePressed() async {
    final posId = await _onboardingState.getPosId();
    if (posId != null) {
      await _posState.updatePOS(posId: posId);
      if (mounted) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final place = context.select((PlaceOrderState state) => state.place);

    final posState = context.watch<POSState>();

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
              SettingsRow(
                label: "Languages",
                icon: 'assets/icons/language-svgrepo-com.svg',
                iconColor: CupertinoColors.systemGrey,
                onTap: () {},
              ),
              SettingsRow(
                label: "Theme",
                icon: 'assets/icons/',
                iconColor: CupertinoColors.systemGrey,
                onTap: () {},
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
                      onPressed:
                          posState.isLoading ? null : _onDeactivatePressed,
                      color: surfaceDarkColor.withValues(alpha: 1),
                      child: posState.isLoading
                          ? const CupertinoActivityIndicator()
                          : Text(
                              'Deactivate Terminal',
                              style: TextStyle(
                                fontSize: screenWidth * 0.045,
                                fontWeight: FontWeight.w700,
                                color: CupertinoColors.white,
                              ),
                            ),
                    ),
                    if (posState.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        posState.errorMessage!,
                        style: const TextStyle(
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                    ],
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
