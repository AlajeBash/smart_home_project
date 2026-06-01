import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.borderOpacity = 0.1,
    this.bgOpacity = 0.05,
    this.glowColor,
    this.glowBlurRadius = 12.0,
    this.height,
    this.width,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double borderOpacity;
  final double bgOpacity;
  final Color? glowColor;
  final double glowBlurRadius;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor!.withOpacity(0.12),
                  blurRadius: glowBlurRadius,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(bgOpacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withOpacity(borderOpacity),
                width: 1.2,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(bgOpacity * 1.5),
                  Colors.white.withOpacity(bgOpacity * 0.5),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
