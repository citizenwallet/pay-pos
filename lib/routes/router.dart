import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

//models
import 'package:pay_pos/models/order.dart';

//screens
import 'package:pay_pos/screens/order_pay/screen.dart';
import 'package:pay_pos/screens/orders/order/order/screen.dart';
import 'package:pay_pos/screens/settings/screen.dart';
import 'package:pay_pos/screens/onboarding/screen.dart';
import 'package:pay_pos/screens/interactions/menu/screen.dart';
import 'package:pay_pos/screens/orders/screen.dart';

// state
import 'package:pay_pos/state/onboarding.dart';
import 'package:pay_pos/state/state.dart';

GoRouter createRouter(
  GlobalKey<NavigatorState> rootNavigatorKey,
  GlobalKey<NavigatorState> shellNavigatorKey,
  List<NavigatorObserver> observers, {
  String? placeId,
}) {
  return GoRouter(
    initialLocation: placeId != null ? '/$placeId' : '/',
    debugLogDiagnostics: kDebugMode,
    navigatorKey: rootNavigatorKey,
    observers: observers,
    routes: [
      GoRoute(
        name: 'Onboarding',
        path: '/',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          return ChangeNotifierProvider(
            create: (_) => OnboardingState(),
            child: const OnboardingScreen(),
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => provideState(context, state, child),
        routes: [
          GoRoute(
            name: 'Orders',
            path: '/:placeId',
            builder: (context, state) {
              final id = placeId ?? state.pathParameters['placeId']!;
              return OrdersScreen(
                placeId: id,
              );
            },
          ),
          GoRoute(
            name: 'Order',
            path: '/:placeId/order/:orderId',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              final order = extra['order'] as Order;

              return OrderScreen(
                order: order,
              );
            },
          ),
          GoRoute(
            name: 'Settings',
            path: '/:placeId/settings',
            builder: (context, state) {
              return SettingsScreen();
            },
          ),
          GoRoute(
            name: 'InteractionWithPlace',
            path: '/:placeId/menu',
            builder: (context, state) {
              final id = placeId ?? state.pathParameters['placeId']!;
              return PlaceMenuScreen(
                placeId: id,
              );
            },
          ),
          GoRoute(
            name: 'OrderPay',
            path: '/:placeId/order/:orderId/pay',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;

              final items = extra?['items'] as List<Map<String, dynamic>>?;
              final amount = extra?['amount'] as double?;
              final description = extra?['description'] as String?;

              return OrderPayScreen(
                items: items ?? [],
                amount: amount ?? 0.0,
                description: description ?? '',
              );
            },
          ),
        ],
      ),
    ],
  );
}
