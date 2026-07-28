import 'package:flutter/material.dart';

import '../theme.dart';

/// Chunky button with a hard pixel border and press feedback.
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = PixelColors.surfaceLight,
    this.textColor = PixelColors.text,
    this.fontSize = 10,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color textColor;
  final double fontSize;
  final bool enabled;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.enabled ? widget.color : PixelColors.surface;
    final textColor =
        widget.enabled ? widget.textColor : PixelColors.textDim;
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _down = false);
              widget.onPressed();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        transform: Matrix4.translationValues(0, _down ? 2 : 0, 0),
        decoration: BoxDecoration(
          color: color,
          border: const Border(
            left: BorderSide(color: PixelColors.border, width: 3),
            top: BorderSide(color: PixelColors.border, width: 3),
            right: BorderSide(color: PixelColors.borderDark, width: 3),
            bottom: BorderSide(color: PixelColors.borderDark, width: 3),
          ),
          boxShadow: _down
              ? null
              : const [
                  BoxShadow(color: Color(0xAA000000), offset: Offset(0, 3)),
                ],
        ),
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: pixelFont,
            fontSize: widget.fontSize,
            color: textColor,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

/// Dark panel with the double pixel border used across menus.
class PixelPanel extends StatelessWidget {
  const PixelPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = PixelColors.surface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: PixelColors.borderDark,
        border: Border.fromBorderSide(
          BorderSide(color: PixelColors.border, width: 2),
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        color: color,
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Row of 5 pips used for hero stats.
class StatPips extends StatelessWidget {
  const StatPips({
    super.key,
    required this.label,
    required this.value,
    this.color = PixelColors.gold,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: pixelFont,
              fontSize: 7,
              color: PixelColors.textDim,
            ),
          ),
        ),
        const SizedBox(width: 4),
        for (var i = 0; i < 5; i++)
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: i < value ? color : PixelColors.bg,
              border: Border.all(color: PixelColors.borderDark, width: 1.5),
            ),
          ),
      ],
    );
  }
}
