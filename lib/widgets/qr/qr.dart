import 'package:pay_pos/theme/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QR extends StatelessWidget {
  final String data;
  final double size;
  final EdgeInsets padding;
  final String? logo;

  const QR({
    super.key,
    required this.data,
    this.size = 200,
    this.padding = const EdgeInsets.all(10),
    this.logo,
  });

  @override
  Widget build(BuildContext context) {
    final imageSize = size * 0.2;

    ImageProvider<Object>? embeddedImage;

    if (logo != null && logo!.startsWith('https')) {
      embeddedImage = NetworkImage(logo!);
    } else if (logo != null && logo!.startsWith('assets')) {
      embeddedImage = AssetImage(logo!);
    }

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: primaryColor,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: QrImageView(
          data: data,
          size: size,
          gapless: false,
          version: QrVersions.auto,
          backgroundColor: whiteColor,
          padding: padding,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.circle,
            color: primaryColor,
          ),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.circle,
            color: blackColor,
          ),
          embeddedImage: embeddedImage,
          embeddedImageStyle: QrEmbeddedImageStyle(
            size: Size(imageSize, imageSize),
          ),
        ),
      ),
    );
  }
}
