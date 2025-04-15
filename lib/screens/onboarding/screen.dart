import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pay_pos/theme/colors.dart';
import 'package:pay_pos/widgets/qr/qr.dart';
import 'package:pay_pos/widgets/toast/toast.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

//services
import 'package:pay_pos/services/pay/localstorage.dart';

//widgets
import 'package:pay_pos/widgets/short_button.dart';
import 'package:pay_pos/widgets/coin_logo.dart';
import 'package:pay_pos/widgets/wide_button.dart';

//states
import 'package:pay_pos/state/onboarding.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  OnboardingState? _onboardingState;
  Timer? _activationCheckTimer;
  bool _isDialogShown = false;

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
    await _onboardingState?.fetchPosId();

    _activationCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _onboardingState?.checkActivation();
    });
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

    final isActivated =
        context.select<OnboardingState, bool>((state) => state.isActivated);
    final posId =
        context.select<OnboardingState, String?>((state) => state.posId);
    final placeId =
        context.select<OnboardingState, String?>((state) => state.placeId);

    if (isActivated && posId != null && !_isDialogShown) {
      _isDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (placeId != null && placeId.isNotEmpty) {
          showPinEntryDialog(
            context,
            placeId,
            screenHeight * 0.02,
          ).then((_) {
            _isDialogShown = false;
          });
        }
      });
    }

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
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // QR Code
                        QR(
                          data: posId != null
                              ? "$_activationBaseUrl/pos/activate/$posId"
                              : "",
                          logo: 'assets/logo.png',
                          size: 240,
                          padding: const EdgeInsets.all(14),
                        ),

                        // Logo on top of QR
                        Positioned(
                          child: Container(
                            width: 85,
                            height: 85,
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor,
                            ),
                            alignment: Alignment.center,
                            child: CoinLogo(size: 70),
                          ),
                        ),
                      ],
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

  Future<void> showPinEntryDialog(
    BuildContext context,
    String placeId,
    double height,
  ) async {
    List<TextEditingController> controllers = List.generate(
      4,
      (index) => TextEditingController(),
    );
    List<FocusNode> focusNodes = List.generate(
      4,
      (index) => FocusNode(),
    );

    await showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text("Set Up PIN"),
          content: Column(
            children: [
              SizedBox(height: height),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    width: 40,
                    margin: EdgeInsets.symmetric(horizontal: 5),
                    child: CupertinoTextField(
                      controller: controllers[index],
                      focusNode: focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: CupertinoColors.systemGrey,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          focusNodes[index + 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () async {
                String enteredPin =
                    controllers.map((controller) => controller.text).join();
                if (enteredPin.length == 4) {
                  await LocalStorageService().savePin(enteredPin);
                  Navigator.pop(context);

                  context.go('/$placeId');
                } else {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: Text("Invalid PIN"),
                      content: Text("Enter a valid 4-digit PIN"),
                      actions: [
                        CupertinoDialogAction(
                          child: Text("OK"),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
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
