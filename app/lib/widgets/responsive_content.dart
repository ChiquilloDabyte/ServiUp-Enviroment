import 'package:flutter/material.dart';

import '../core/theme/app_dimensions.dart';

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth = AppBreakpoints.maxContentWidth,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding =
        width >= AppBreakpoints.tablet
            ? AppSpacing.md
            : AppSpacing.mobileMargin;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: AppSpacing.md,
              ),
          child: child,
        ),
      ),
    );
  }
}
