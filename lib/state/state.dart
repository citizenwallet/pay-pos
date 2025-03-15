import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:pay_pos/state/app.dart';
import 'package:pay_pos/state/checkout.dart';
import 'package:pay_pos/state/orders.dart';
import 'package:pay_pos/state/place_order.dart';
import 'package:pay_pos/state/wallet.dart';
import 'package:provider/provider.dart';

Widget provideAppState(
  Widget? child, {
  Widget Function(BuildContext, Widget?)? builder,
}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppState(),
        ),
        ChangeNotifierProvider(
          create: (_) => WalletState(),
        ),
      ],
      builder: builder,
      child: child,
    );

Widget provideState(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  final placeId = state.pathParameters['placeId']!;

  return MultiProvider(
    key: Key(placeId),
    providers: [
      // ChangeNotifierProvider(
      //   key: Key('profile-$account'),
      //   create: (_) => ProfileState(account: account),
      // ),
      ChangeNotifierProvider(
        key: Key('orders-$placeId'),
        create: (_) => OrdersState(placeId: placeId),
      ),
      ChangeNotifierProvider(
        key: Key('orders-with-place-$placeId'),
        create: (_) => PlaceOrderState(
          placeId: placeId,
        ),
      ),
      ChangeNotifierProxyProvider<PlaceOrderState, CheckoutState>(
        key: Key('checkout-$placeId'),
        create: (_) => CheckoutState(account: '', slug: ''),
        update: (_, placeOrderState, previous) {
          if (previous == null) {
            return CheckoutState(
              account: placeOrderState.account,
              slug: placeOrderState.slug,
            );
          }
          // Update existing instance instead of creating new one
          previous.updateAccountAndSlug(
            placeOrderState.account,
            placeOrderState.slug,
          );
          return previous;
        },
      ),
    ],
    child: child,
  );
}
