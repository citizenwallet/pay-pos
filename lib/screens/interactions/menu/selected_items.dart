import 'package:flutter/cupertino.dart';
import 'package:pay_pos/models/checkout_item.dart';
import 'package:pay_pos/state/checkout.dart';
import 'package:pay_pos/theme/colors.dart';
import 'package:pay_pos/widgets/coin_logo.dart';

class SelectedItems extends StatelessWidget {
  final CheckoutState checkoutState;

  const SelectedItems({
    super.key,
    required this.checkoutState,
  });

  @override
  Widget build(BuildContext context) {
    final items = checkoutState.checkout.items;

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFD9D9D9),
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
          ...items.map((item) => SelectedItemTile(
                item: item,
                checkoutState: checkoutState,
              )),
        ],
      ),
    );
  }
}

class SelectedItemTile extends StatelessWidget {
  final CheckoutItem item;
  final CheckoutState checkoutState;

  const SelectedItemTile({
    super.key,
    required this.item,
    required this.checkoutState,
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
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: () => checkoutState.decreaseItem(item.menuItem),
                child: Container(
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
                    '-',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF171717),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                item.quantity.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF171717),
                ),
              ),
              const SizedBox(width: 10),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: () => checkoutState.increaseItem(item.menuItem),
                child: Container(
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
                    '+',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF171717),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
