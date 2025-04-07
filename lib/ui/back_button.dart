// import 'dart:html' hide VoidCallback;

import 'package:brick_collector/common_libs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MyBackButton extends StatelessWidget {
  const MyBackButton({
    super.key,
    this.color,
    this.onPressed,
  });

  final Color? color;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);

    assert(debugCheckHasMaterialLocalizations(context));

    return IconButton(
      icon: const BackButtonIcon(),
      color: color,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        } else {
          // if (kIsWeb) {
          //   window.history.back();
          // } else {
          router.pop();
          // }
        }
      },
    );
  }
}
