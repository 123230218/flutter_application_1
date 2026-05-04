import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: isPrimary
          ? [AppColors.primary, AppColors.secondary]
          : [AppColors.surface, AppColors.surface],
    );

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
