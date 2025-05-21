import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pay_pos/theme/colors.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

//widgets
import 'package:pay_pos/widgets/short_button.dart';
import 'package:pay_pos/widgets/wide_button.dart';
import 'package:pay_pos/widgets/qr/qr.dart';
import 'package:pay_pos/widgets/toast/toast.dart';

//states
import 'package:pay_pos/state/onboarding.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  late OnboardingState _onboardingState;
  Timer? _activationCheckTimer;

  final String _activationBaseUrl = dotenv.env['ACTIVATION_BASE_URL'] ?? '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onboardingState = context.read<OnboardingState>();
      onLoad();
    });
  }

  void onLoad() async {
    final placeId = await _onboardingState.loadPosId();
    if (placeId != null) {
      if (!mounted) return;

      final navigator = GoRouter.of(context);

      navigator.replace('/$placeId');
      return;
    }

    _activationCheckTimer = Timer.periodic(
      const Duration(seconds: 2),
      (timer) async {
        final placeId = await _onboardingState.checkActivation();
        if (placeId != null) {
          if (!mounted) return;

          final navigator = GoRouter.of(context);

          navigator.replace('/$placeId');
        }
      },
    );
  }

  @override
  void dispose() {
    _activationCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        // Restart the scanner when the app is resumed.
        // Don't forget to resume listening to the barcode events.
        onLoad();
      case AppLifecycleState.inactive:
        // Stop the scanner when the app is paused.
        // Also stop the barcode events subscription.
        _activationCheckTimer?.cancel();
    }
  }

  void handleShare(String? posId) {
    Clipboard.setData(
      ClipboardData(
        text: "$_activationBaseUrl/pos/activate/$posId",
      ),
    );

    HapticFeedback.heavyImpact();

    toastification.showCustom(
      context: context,
      autoCloseDuration: const Duration(seconds: 5),
      alignment: Alignment.bottomCenter,
      builder: (context, toast) => Toast(
        icon: const Icon(
          CupertinoIcons.checkmark_circle_fill,
          color: successColor,
        ),
        title: const Text('Activation link copied'),
      ),
    );
  }

  void handleActivateInDashboard(String? posId) async {
    final Uri url = Uri.parse("$_activationBaseUrl/pos/activate/$posId");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      toastification.showCustom(
        context: context,
        autoCloseDuration: const Duration(seconds: 5),
        alignment: Alignment.bottomCenter,
        builder: (context, toast) => Toast(
          icon: const Icon(
            CupertinoIcons.xmark_circle_fill,
            color: errorColor,
          ),
          title: const Text('Could not open browser'),
        ),
      );
    }
  }

  void handleDemoMode() {
    print("Demo Mode Attempted!");
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final size = screenWidth > screenHeight ? screenHeight : screenWidth;

    final posId =
        context.select<OnboardingState, String?>((state) => state.posId);

    return CupertinoPageScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    QR(
                      data: posId != null
                          ? "$_activationBaseUrl/pos/activate/$posId"
                          : "",
                      logo: 'assets/logo.png',
                      size: size * 0.8,
                      padding: const EdgeInsets.all(20),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Scan to activate',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "or",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ShortButton(
                      onPressed: () => handleShare(posId),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Share activation link',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: CupertinoColors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            CupertinoIcons.share,
                            color: CupertinoColors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Business Dashboard Button
                  WideButton(
                    onPressed: () => handleActivateInDashboard(posId),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Activate through Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: whiteColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          CupertinoIcons.arrow_up_right_square,
                          color: whiteColor,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () => handleDemoMode(),
                    child: Text(
                      'Demo Mode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.systemBlue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showOverlayMessage(
    BuildContext context,
    String message,
    double width,
    double height,
  ) {
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: height * 0.25,
        left: width * 0.25,
        width: width * 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            message,
            style: const TextStyle(color: whiteColor),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }
}
