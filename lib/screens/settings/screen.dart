import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

//models
import 'package:pay_pos/screens/settings/settings_profile_bar.dart';
import 'package:pay_pos/state/orders.dart';
import 'package:pay_pos/state/place_order.dart';
import 'package:pay_pos/state/pos.dart';
import 'package:pay_pos/state/terminal.dart';
import 'package:pay_pos/theme/colors.dart';
import 'package:pay_pos/widgets/settings_row.dart';
import 'package:pay_pos/widgets/wide_button.dart';
import 'package:provider/provider.dart';

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
  late TerminalState _terminalState;

  @override
  void initState() {
    super.initState();

    _placeOrderState = context.read<PlaceOrderState>();
    _ordersState = context.read<OrdersState>();
    _ordersState.isPollingEnabled = false;
    _posState = context.read<POSState>();
    _terminalState = TerminalState(_posState);
  }

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
    final success = await _terminalState.deactivateTerminal();
    if (success && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final place = context.select((PlaceOrderState state) => state.place);

    if (place == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListenableBuilder(
      listenable: _terminalState,
      builder: (context, _) {
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
                          onPressed: _terminalState.isLoading
                              ? null
                              : _onDeactivatePressed,
                          color: surfaceDarkColor.withValues(alpha: 1),
                          child: _terminalState.isLoading
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
                        if (_terminalState.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _terminalState.errorMessage!,
                            style: const TextStyle(
                                color: CupertinoColors.systemRed),
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
      },
    );
  }
}
