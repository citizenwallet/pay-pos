import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pay_pos/widgets/short_button.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pay_pos/state/onboarding.dart';
import 'package:pay_pos/theme/colors.dart';
import 'package:pay_pos/widgets/coin_logo.dart';
import 'package:pay_pos/widgets/wide_button.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  OnboardingState? _onboardingState;

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
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Top content in an Expanded to push it to the center
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // QR Code
                        QrImageView(
                          data: _onboardingState?.posId != null
                              ? "${dotenv.env['BASE_URL']}/dashboard/pos/activate/${_onboardingState!.posId}"
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

                    // Title
                    Text(
                      'Save to activate',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Subtitle
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
                      onPressed: () =>
                          "${dotenv.env['BASE_URL']}/dashboard/pos/activate/${_onboardingState?.posId}",
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
                    onPressed: () =>
                        "${dotenv.env['BASE_URL']}/dashboard/pos/activate/${_onboardingState?.posId}",
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Business Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: CupertinoColors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          CupertinoIcons.arrow_up_right_square,
                          color: CupertinoColors.white,
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
    );
  }
}
