import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

//models
import 'package:pay_pos/models/user.dart';

//state
import 'package:pay_pos/state/wallet.dart';

//widgets
import 'package:pay_pos/widgets/coin_logo.dart';
import 'package:pay_pos/widgets/profile_circle.dart';


class ProfileBar extends StatefulWidget {
  final User userProfile;
  final VoidCallback? onTapLeading;

  const ProfileBar({
    super.key,
    required this.userProfile,
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

    final walletState = context.watch<WalletState>();
    final balance = walletState.wallet?.formattedBalance.toStringAsFixed(2);

    final userProfile = widget.userProfile;

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
                imageUrl: userProfile.imageUrl,
                size: 70,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Name(
                    name: userProfile.name,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Balance(balance: balance ?? '0.00'),
                      const SizedBox(width: 16),
                    ],
                  )
                ],
              )
            ],
          ),
          RightChevron(),
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
        fontSize: 16,
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

  const Balance({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CoinLogo(size: 33),
        SizedBox(width: 4),
        Text(
          balance,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class RightChevron extends StatelessWidget {
  const RightChevron({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return Icon(
      CupertinoIcons.chevron_right,
      color: theme.primaryColor,
      size: 16,
    );
  }
}
