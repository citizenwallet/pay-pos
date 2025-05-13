import 'package:flutter/cupertino.dart';

import 'package:flutter/services.dart';
import 'package:pay_pos/models/place.dart';

import 'package:pay_pos/models/user.dart';

import 'package:pay_pos/widgets/profile_circle.dart';

class SettingsProfileBar extends StatefulWidget {
  final Place userProfile;
  final VoidCallback? onTapLeading;
  final double height;

  const SettingsProfileBar({
    super.key,
    required this.userProfile,
    required this.height,
    this.onTapLeading,
  });

  @override
  State<SettingsProfileBar> createState() => _SettingsProfileBarState();
}

class _SettingsProfileBarState extends State<SettingsProfileBar> {
  @override
  void initState() {
    super.initState();
  }

  // void _goToPlace() async {
  //   final placeId = widget.placeId;

  //   final navigator = GoRouter.of(context);

  //   navigator.push('/$placeId/');
  // }

  @override
  Widget build(BuildContext context) {
    CupertinoTheme.of(context);

    final userProfile = widget.userProfile;

    return Container(
      height: widget.height,
      // color: CupertinoColors.systemBackground,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFD9D9D9),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: widget.onTapLeading,
            child: LeftChevron(),
          ),
          Column(
            children: [
              ProfileCircle(
                imageUrl: userProfile.imageUrl,
                size: 120,
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Name(
                    name: userProfile.name,
                  ),
                  const SizedBox(height: 5),
                  TerminalId(
                    terminalId: userProfile.account,
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}

class Name extends StatelessWidget {
  final String name;

  const Name({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Color(0xFF14023F),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class TerminalId extends StatelessWidget {
  final String terminalId;

  const TerminalId({super.key, required this.terminalId});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          terminalId,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF14023F),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            Clipboard.setData(
              ClipboardData(
                text: terminalId,
              ),
            );
          },
          child: Icon(
            CupertinoIcons.doc_on_clipboard,
            color: CupertinoColors.black,
            size: 16,
          ),
        ),
      ],
    );
  }
}

class LeftChevron extends StatelessWidget {
  const LeftChevron({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return Icon(
      CupertinoIcons.chevron_left,
      color: theme.primaryColor,
      size: 16,
    );
  }
}
