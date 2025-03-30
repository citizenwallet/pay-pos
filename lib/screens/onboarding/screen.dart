import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pay_pos/theme/colors.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';

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

class _OnboardingScreenState extends State<OnboardingScreen> {
  OnboardingState? _onboardingState;
  Timer? _activationCheckTimer;
  bool _isDialogShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_onboardingState == null) {
      _onboardingState = context.read<OnboardingState>();
      onLoad();
    }
  }

  void onLoad() async {
    await _onboardingState?.fetchPosId();
    if (mounted) {
      setState(() {});
    }
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
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer<OnboardingState>(
      builder: (context, onboardingState, _) {
        final isActivated = onboardingState.isActivated;
        final posId = onboardingState.posId;

        if (isActivated && posId != null && !_isDialogShown) {
          _isDialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final placeId = onboardingState.placeId;
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
            child: SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top,
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
                                QrImageView(
                                  data: posId != null
                                      ? "${dotenv.env['BASE_URL']}/pos/activate/$posId"
                                      : "",
                                  version: QrVersions.auto,
                                  size: 250,
                                  gapless: false,
                                  errorCorrectionLevel: QrErrorCorrectLevel.H,
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
                              'Save to activate',
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
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text:
                                        "${dotenv.env['BASE_URL']}/pos/activate/$posId",
                                  ),
                                ).then((_) {
                                  showOverlayMessage(
                                    context,
                                    "Copied to clipboard",
                                    screenWidth,
                                    screenHeight,
                                  );
                                });
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Share terminal id',
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
                            const SizedBox(height: 150),
                          ],
                        ),
                      ),

                      // Bottom content
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Business Dashboard Button
                          WideButton(
                            onPressed: () async {
                              final Uri url = Uri.parse(
                                  "${dotenv.env['BASE_URL']}/pos/activate/$posId");

                              if (await canLaunchUrl(url)) {
                                await launchUrl(url,
                                    mode: LaunchMode.externalApplication);
                              } else {
                                showOverlayMessage(
                                  context,
                                  "Could not launch URL!",
                                  screenWidth,
                                  screenHeight,
                                );
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Business Dashboard',
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
                            onTap: () {
                              print("Demo Mode Attempted!");
                            },
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

                          const SizedBox(height: 40),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
