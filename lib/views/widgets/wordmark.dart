import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class Wordmark extends StatelessWidget {
  final double size;

  const Wordmark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: size,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          height: 1,
        ),
        children: const [
          TextSpan(text: 'CHOW', style: TextStyle(color: AppColors.accent)),
          TextSpan(text: 'SCAN', style: TextStyle(color: AppColors.brand)),
        ],
      ),
    );
  }
}
