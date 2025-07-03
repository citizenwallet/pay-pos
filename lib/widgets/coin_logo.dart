// import 'package:pay_pos/theme/provider.dart';  // TODO: set up theme provider
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CoinLogo extends StatelessWidget {
  final double size;
  final String? logo;

  const CoinLogo({
    super.key,
    required this.size,
    this.logo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    Widget? logoWidget;

    if (logo == null) {
      logoWidget = SvgPicture.asset('assets/logo.svg');
    } else {
      final isSvg = logo!.endsWith('.svg');

      logoWidget = isSvg
          ? SvgPicture.network(
              logo!,
              semanticsLabel: 'coin logo',
              height: size,
              width: size,
              placeholderBuilder: (context) => SvgPicture.asset(
                'assets/logo.svg',
                semanticsLabel: 'coin logo',
                height: size,
                width: size,
              ),
            )
          : CachedNetworkImage(
              imageUrl: logo!,
              height: size,
              width: size,
              fit: BoxFit.cover,
              placeholder: (context, url) => SvgPicture.asset(
                'assets/logo.svg',
                semanticsLabel: 'coin logo',
                height: size,
                width: size,
              ),
            );
    }

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        color: theme.scaffoldBackgroundColor,
        border: Border.all(
          width: 1,
          color: theme.primaryColor.withAlpha((0.2 * 255).round()),
        ),
      ),
      child: logoWidget,
    );
  }
}
