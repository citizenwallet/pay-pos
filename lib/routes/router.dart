import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:pay_pos/screens/order_pay/screen.dart';
import 'package:provider/provider.dart';

// screens
import 'package:pay_pos/screens/onboarding/screen.dart';
import 'package:pay_pos/screens/interactions/menu/screen.dart';
import 'package:pay_pos/screens/order/screen.dart';

// state
import 'package:pay_pos/state/onboarding.dart';
import 'package:pay_pos/state/state.dart';

GoRouter createRouter(
  GlobalKey<NavigatorState> rootNavigatorKey,
  GlobalKey<NavigatorState> shellNavigatorKey,
  List<NavigatorObserver> observers, {
  String? account,
  String? slug,
  String? placeId = "2",
}) =>
    GoRouter(
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
          builder: (context, state, child) =>
              provideState(context, state, child),
          routes: [
            GoRoute(
              name: 'Order',
              path: '/:placeId',
              builder: (context, state) {
                return OrderScreen(
                  placeId: state.pathParameters['placeId']!,
                );
              },
            ),
            GoRoute(
              name: 'InteractionWithPlace',
              path: '/:placeId/menu',
              builder: (context, state) {
                return PlaceMenuScreen(
                  placeId: state.pathParameters['placeId']!,
                );
              },
            ),
            GoRoute(
              name: 'OrderPay',
              path: '/:placeId/:type/pay',
              builder: (context, state) {
                final type = state.pathParameters['type'];
                return OrderPayScreen(
                  isMenu: type == 'menu',
                );
              },
            ),
          ],
        ),
      ],
    );
