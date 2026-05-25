import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AnimatedFavoriteButton extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onTap;

  const AnimatedFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: isFavorite ? 1.25 : 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double scale, Widget? child) {
        return Transform.scale(
          scale: scale,
          child: IconButton(
            onPressed: onTap,
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite
                  ? Theme.of(context).colorScheme.secondary
                  : AppColors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}
