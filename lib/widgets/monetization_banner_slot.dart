import 'package:flutter/material.dart';

import '../monetization/monetization_controller.dart';

/// A stable shell-owned banner boundary. It occupies no space until a reviewed,
/// configured provider has actually cleared every runtime gate.
class MonetizationBannerSlot extends StatelessWidget {
  const MonetizationBannerSlot({
    super.key,
    required this.controller,
    required this.placementAllowed,
  });

  final MonetizationController controller;
  final bool placementAllowed;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!placementAllowed || !controller.mayDisplayBanner) {
          return const SizedBox.shrink();
        }
        return LayoutBuilder(
          builder: (context, constraints) =>
              controller.buildBanner(availableWidth: constraints.maxWidth),
        );
      },
    );
  }
}
