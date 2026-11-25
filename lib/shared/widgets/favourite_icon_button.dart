import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Shared AppBar heart button for toggling favourites on Anime, Manga,
/// Character, and Staff detail screens cleanly with a consistent animation.
class FavouriteIconButton extends StatelessWidget {
  final bool isFavourite;
  final bool isToggling;
  final VoidCallback onPressed;
  final bool useDarkBackdrop;

  const FavouriteIconButton({
    super.key,
    required this.isFavourite,
    required this.onPressed,
    this.isToggling = false,
    this.useDarkBackdrop = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = AnimatedScale(
      scale: isFavourite ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      child: Icon(
        isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFavourite
            ? AppColors.favoritePink
            : (useDarkBackdrop ? Colors.white : null),
        size: useDarkBackdrop ? 20 : 22,
      ),
    );

    return IconButton(
      tooltip: isFavourite ? 'Remove from Favorites' : 'Add to Favorites',
      onPressed: isToggling ? null : onPressed,
      icon: useDarkBackdrop
          ? Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: iconWidget,
            )
          : iconWidget,
    );
  }
}
