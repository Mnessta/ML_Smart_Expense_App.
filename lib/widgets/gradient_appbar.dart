import 'package:flutter/material.dart';
import '../utils/constants.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({super.key, required this.title, this.actions});

  final Widget title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: ShaderMask(
        shaderCallback: (Rect bounds) => AppColors.primaryGradient.createShader(bounds),
        child: DefaultTextStyle(
          style: (Theme.of(context).textTheme.titleLarge ?? const TextStyle(fontSize: 20)).copyWith(color: Colors.white),
          child: title,
        ),
      ),
      actions: actions,
      backgroundColor: Colors.transparent,
    );
  }
}













