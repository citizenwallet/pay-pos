import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:pay_pos/services/config/config.dart';
import 'package:pay_pos/state/orders.dart';
import 'package:pay_pos/theme/colors.dart';
import 'package:provider/provider.dart';

//models
import 'package:pay_pos/models/place.dart';

//states
import 'package:pay_pos/state/wallet.dart';
import 'package:pay_pos/state/pin.dart';

//widgets
import 'package:pay_pos/widgets/coin_logo.dart';
import 'package:pay_pos/widgets/profile_circle.dart';
import 'package:pay_pos/widgets/pin_entry_dialog.dart';

class ProfileBar extends StatefulWidget {
  final Place place;
  final VoidCallback? onTapLeading;

  const ProfileBar({
    super.key,
    required this.place,
    this.onTapLeading,
  });

  @override
  State<ProfileBar> createState() => _ProfileBarState();
}

class _ProfileBarState extends State<ProfileBar> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    CupertinoTheme.of(context);

    final balance = context.watch<OrdersState>().posTotal.totalNet / 100;

    final place = widget.place;

    final selectedToken = context.select<WalletState, TokenConfig?>(
      (state) => state.selectedToken,
    );

    return Container(
      height: 95,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFD9D9D9),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              ProfileCircle(
                imageUrl: place.imageUrl,
                size: 70,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Name(
                    name: place.name,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Balance(
                        balance: balance.toStringAsFixed(2),
                        logo: selectedToken?.logo,
                      ),
                      const SizedBox(width: 16),
                    ],
                  )
                ],
              )
            ],
          ),
          SettingsIcon(placeId: place.id.toString()),
        ],
      ),
    );
  }
}

class Name extends StatelessWidget {
  final String name;

  const Name({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: Color(0xFF14023F),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class Balance extends StatelessWidget {
  final String balance;
  final String? logo;

  const Balance({super.key, required this.balance, this.logo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CoinLogo(size: 33, logo: logo),
        SizedBox(width: 4),
        Text(
          balance,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 2,
          ),
          child: Text(
            'today',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: textMutedColor,
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsIcon extends StatelessWidget {
  final String placeId;

  const SettingsIcon({
    super.key,
    required this.placeId,
  });

  Future<void> _handleSettingsTap(BuildContext context) async {
    final pinState = context.read<PinState>();
    final hasPin = await pinState.hasPin();

    if (!context.mounted) return;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => PinEntryDialog(
        isCreating: !hasPin,
        onSuccess: () {
          // Navigate to settings after pin is verified/created
          context.push('/$placeId/settings');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return GestureDetector(
      onTap: () => _handleSettingsTap(context),
      child: Icon(
        CupertinoIcons.settings,
        color: theme.primaryColor,
        size: 22,
      ),
    );
  }
}
