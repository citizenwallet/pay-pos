import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:pay_pos/screens/order_pay/screen.dart';
import 'package:pay_pos/screens/settings/screen.dart';
import 'package:provider/provider.dart';
import 'package:pay_pos/services/pay/localstorage.dart';
import 'package:pay_pos/services/pay/pos.dart';

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
  String? placeId,
  String? storedPosId,
}) {
  final localStorage = LocalStorageService();

  // localStorage.clearPosId();
  // localStorage.clearPvtKey();
  // localStorage.clearPin();
  // localStorage.getPvtKey();

  return GoRouter(
    initialLocation: placeId != null ? '/$placeId' : '/',
    debugLogDiagnostics: kDebugMode,
    navigatorKey: rootNavigatorKey,
    observers: observers,
    redirect: (context, state) async {
      if (state.fullPath != '/') {
        return null;
      }

      final currentStoredPosId = await localStorage.getPosId();
      storedPosId = currentStoredPosId ?? storedPosId;

      if (storedPosId == "posId") {
        return '/';
      }

      try {
        final posService = POSService(posId: storedPosId!);

        const maxRetries = 15;
        for (int i = 0; i < maxRetries; i++) {
          final currentPosId = await localStorage.getPosId() ?? storedPosId;

          final activatedPlaceId =
              await posService.checkIdActivation(currentPosId ?? '');

          if (activatedPlaceId.isNotEmpty) {
            placeId = activatedPlaceId;
            return '/$activatedPlaceId';
          }

          await Future.delayed(
            const Duration(seconds: 2),
          );
        }
      } catch (e) {
        debugPrint('Error checking POS activation: $e');
      }

      return '/';
    },
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
            name: 'Order',
            path: '/:placeId',
            builder: (context, state) {
              final id = placeId ?? state.pathParameters['placeId']!;
              return OrderScreen(
                placeId: id,
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
            path: '/:placeId/:type/pay',
            builder: (context, state) {
              final type = state.pathParameters['type'];
              final extra = state.extra as Map<String, dynamic>?;
              final amount = extra?['amount'] as double?;
              final description = extra?['description'] as String?;

              return OrderPayScreen(
                isMenu: type == 'menu',
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
