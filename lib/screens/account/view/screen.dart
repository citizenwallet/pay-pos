import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:pay_pos/widgets/wide_button.dart';

import 'notifications.dart';
import 'about.dart';
import 'flip_card_animation/flip_card.dart';

class MyAccount extends StatefulWidget {
  const MyAccount({super.key});

  @override
  State<MyAccount> createState() => _MyAccountState();
}

class _MyAccountState extends State<MyAccount> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void goBack() {
    Navigator.pop(context);
  }

  void handleLogout() {
    debugPrint('log out');
  }

  void handleDeleteAccount() {
    debugPrint('delete account');
  }

  @override
  Widget build(BuildContext context) {
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: goBack,
          child: Icon(
            CupertinoIcons.back,
            color: Color(0xFF09090B),
            size: 20,
          ),
        ),
      ),
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            ListView(
              scrollDirection: Axis.vertical,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                Center(
                  child: FlipCard(),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    color: Color(0xFFD9D9D9),
                    thickness: 1,
                  ),
                ),
                const SizedBox(height: 20),
                Notifications(),
                const SizedBox(height: 20),
                About(),
                const SizedBox(height: 60),
                WideButton(
                  color: const Color(0xFF4D4D4D),
                  onPressed: handleLogout,
                  child: Text(
                    'Log out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    color: Color(0xFFD9D9D9),
                    thickness: 1,
                  ),
                ),
                WideButton(
                  color: const Color(0xFFFC4343),
                  onPressed: handleDeleteAccount,
                  child: Text(
                    'Delete account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
                SizedBox(height: safeAreaBottom),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
