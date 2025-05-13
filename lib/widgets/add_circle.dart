import 'package:flutter/cupertino.dart';

class AddCircle extends StatelessWidget {
  final Function() handleFunction;
  final bool isDisabled;
  final double heightFactor;

  const AddCircle(
      {super.key,
      required this.handleFunction,
      this.isDisabled = false,
      this.heightFactor = 1});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return GestureDetector(
      onTap: handleFunction,
      child: Container(
        height: 90,
        width: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFFFFFFF),
          border: Border.all(
            color: theme.primaryColor,
            width: 3,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: Center(
          child: Icon(
            CupertinoIcons.add,
            size: 60 * heightFactor,
            color: theme.primaryColor,
          ),
        ),
      ),
    );
  }
}
