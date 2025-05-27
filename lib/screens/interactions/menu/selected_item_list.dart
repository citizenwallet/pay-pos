import 'package:flutter/cupertino.dart';
import 'package:pay_pos/theme/colors.dart';

//models
import 'package:pay_pos/models/checkout_item.dart';

//states
import 'package:pay_pos/state/checkout.dart';

//widgets
import 'package:pay_pos/widgets/coin_logo.dart';
import 'package:provider/provider.dart';

class SelectedItemsList extends StatelessWidget {
  const SelectedItemsList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final items = context.watch<CheckoutState>().checkout.items;

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: whiteColor,
            width: 1,
          ),
        ),
        color: whiteColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Items',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => SelectedItemTile(
              item: item,
            ),
          ),
        ],
      ),
    );
  }
}

class SelectedItemTile extends StatelessWidget {
  final CheckoutItem item;

  const SelectedItemTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.menuItem.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    CoinLogo(size: 14),
                    const SizedBox(width: 4),
                    Text(
                      item.menuItem.priceString,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textMutedColor,
                      ),
                    ),
                    Text(
                      ' × ${item.quantity}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textMutedColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '= ${(item.menuItem.formattedPrice * item.quantity).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textMutedColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Color(0xFFD9D9D9),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.quantity.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF171717),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ],
      ),
    );
  }
}
