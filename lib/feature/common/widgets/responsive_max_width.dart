import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Centers content and limits width on web/large screens, keeps native layout on mobile.
class ResponsiveMaxWidth extends StatelessWidget {
  const ResponsiveMaxWidth({
    super.key,
    required this.child,
    this.maxWidth = 1080,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldConstrain = kIsWeb || constraints.maxWidth > maxWidth;
        final content = padding != null ? Padding(padding: padding!, child: child) : child;
        if (!shouldConstrain) return content;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: content,
          ),
        );
      },
    );
  }
}
