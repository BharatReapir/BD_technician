import 'package:flutter/material.dart';

/// A Text widget that correctly renders the ₹ (Rupee) symbol on all devices.
class RupeeText extends StatelessWidget {
  final String amount;
  final TextStyle? style;
  final TextAlign? textAlign;

  const RupeeText(this.amount, {Key? key, this.style, this.textAlign})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    return Text(
      '\u20B9$amount',
      textAlign: textAlign,
      style: base.copyWith(
        fontFamilyFallback: const ['Noto Sans', 'Roboto', 'sans-serif'],
      ),
    );
  }
}

/// Helper to build a rupee TextStyle-compatible string with proper font fallback.
TextStyle rupeeStyle(TextStyle base) => base.copyWith(
      fontFamilyFallback: const ['Noto Sans', 'Roboto', 'sans-serif'],
    );
