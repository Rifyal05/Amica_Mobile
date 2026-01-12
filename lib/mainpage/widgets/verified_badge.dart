import 'package:flutter/material.dart';

class VerifiedBadge extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry padding;

  const VerifiedBadge({
    super.key,
    this.size = 14,
    this.padding = const EdgeInsets.only(left: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Image.asset(
        'source/images/verified.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}