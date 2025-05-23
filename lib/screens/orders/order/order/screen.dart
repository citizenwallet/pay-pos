import 'package:flutter/cupertino.dart';

//models
import 'package:pay_pos/models/order.dart';

//widgets
import 'package:pay_pos/widgets/coin_logo.dart';
import 'package:pay_pos/widgets/wide_button.dart';
import 'package:pay_pos/widgets/refund_confirmation_dialog.dart';

class OrderScreen extends StatefulWidget {
  final Order order;

  const OrderScreen({super.key, required this.order});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  void _handleRefund() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => RefundConfirmationDialog(
        onConfirm: _confirmRefund,
      ),
    );
  }

  void _confirmRefund() {
    print('Refund confirmed');
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Order #${order.id}'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order ID in big font
                    Center(
                      child: Text(
                        '#${order.id}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Order amount using the Amount widget from order_list_item.dart
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount:',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Amount(amount: order.total),
                        ],
                      ),
                    ),

                    if (order.fees > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Fees:',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Amount(amount: order.fees),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Order status
                    _buildInfoRow(
                      'Status:',
                      order.status.name.toUpperCase(),
                      valueColor: _getStatusColor(order.status),
                    ),

                    // Order description
                    if (order.description != null &&
                        order.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description:',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(order.description ?? ''),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),
                    const Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Created:', _formatDate(order.createdAt)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: order.type != OrderType.app &&
                      order.status == OrderStatus.paid &&
                      order.txHash != null
                  ? WideButton(
                      color: CupertinoColors.systemRed,
                      onPressed: () => _handleRefund(),
                      child: const Text(
                        'Refund',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: valueColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.paid:
        return CupertinoColors.systemGreen;
      case OrderStatus.cancelled:
        return CupertinoColors.systemRed;
      case OrderStatus.pending:
      default:
        return CupertinoColors.systemOrange;
    }
  }
}

class Amount extends StatelessWidget {
  final double amount;

  const Amount({
    super.key,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Row(
      children: [
        CoinLogo(
          size: 24,
        ),
        const SizedBox(width: 4),
        Text(
          '${amount >= 0 ? '+' : '-'}${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: theme.primaryColor,
          ),
        ),
      ],
    );
  }
}
