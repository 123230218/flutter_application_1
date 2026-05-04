import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../widgets/smart_image.dart';

class PartCard extends StatelessWidget {
  const PartCard({
    super.key,
    required this.name,
    required this.brand,
    required this.price,
    required this.imageUrl,
    required this.onTap,
  });

  final String name;
  final String brand;
  final String price;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SmartImage(
                url: imageUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(brand, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  Text(price, style: const TextStyle(color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
