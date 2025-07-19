import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const CustomAppBar({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final logoPath = brightness == Brightness.dark
        ? 'assets/img/white_logo.png'
        : 'assets/img/black_logo.png';

    return AppBar(
      title: Text(title),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(logoPath),
      ),
      actions: actions,
    );
  }
}
