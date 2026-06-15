import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color color;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  const GlassmorphicPanel({
    Key? key,
    required this.child,
    this.borderRadius = 16.0,
    this.blur = 24.0,
    this.color = const Color(0x1AFFFFFF), // Highly translucent white
    this.borderColor = const Color(0x1FFFFFFF), // Soft frosted border
    this.padding = const EdgeInsets.all(16.0),
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor,
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
