import 'dart:ui' show DisplayFeature, DisplayFeatureType;

import 'package:flutter/widgets.dart';

/// Layout helpers for phones, tablets and foldables.
extension AdaptiveMediaQuery on MediaQueryData {
  /// Material "tablet" breakpoint on the shortest side.
  bool get isTablet => size.shortestSide >= 600;

  /// True when the window is taller than it is wide (folded phone, portrait
  /// tablet, etc.).
  bool get isPortrait => size.height > size.width;

  /// Display features that physically separate or crease the screen.
  Iterable<DisplayFeature> get foldingFeatures => displayFeatures.where(
        (f) =>
            f.type == DisplayFeatureType.hinge ||
            f.type == DisplayFeatureType.fold,
      );

  /// Extra padding that keeps interactive UI clear of a hinge/fold.
  EdgeInsets get hingePadding {
    var pad = EdgeInsets.zero;
    for (final feature in foldingFeatures) {
      final b = feature.bounds;
      // Vertical hinge/fold → pad left or right of the gap.
      if (b.height >= b.width) {
        final mid = size.width / 2;
        if (b.center.dx <= mid) {
          pad = pad.copyWith(left: pad.left + b.right);
        } else {
          pad = pad.copyWith(right: pad.right + (size.width - b.left));
        }
      } else {
        // Horizontal hinge (tabletop) → pad top or bottom.
        final mid = size.height / 2;
        if (b.center.dy <= mid) {
          pad = pad.copyWith(top: pad.top + b.bottom);
        } else {
          pad = pad.copyWith(bottom: pad.bottom + (size.height - b.top));
        }
      }
    }
    return pad;
  }

  /// Safe padding (system insets) combined with hinge clearance.
  EdgeInsets get adaptivePadding => padding.add(hingePadding).resolve(TextDirection.ltr);
}

/// [SafeArea] that also clears foldable hinges / folds.
class AdaptiveSafeArea extends StatelessWidget {
  const AdaptiveSafeArea({
    super.key,
    required this.child,
    this.minimum = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsets minimum;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final hinge = mq.hingePadding;
    return SafeArea(
      minimum: EdgeInsets.only(
        left: minimum.left + hinge.left,
        top: minimum.top + hinge.top,
        right: minimum.right + hinge.right,
        bottom: minimum.bottom + hinge.bottom,
      ),
      child: child,
    );
  }
}

/// Scales a base font size up a bit on tablets.
double adaptiveFont(BuildContext context, double base) {
  final shortest = MediaQuery.sizeOf(context).shortestSide;
  if (shortest >= 900) return base * 1.35;
  if (shortest >= 600) return base * 1.2;
  return base;
}
