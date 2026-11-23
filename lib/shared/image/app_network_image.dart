import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppSpacing.borderRadius8;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return ClipRRect(
        borderRadius: effectiveRadius,
        child: Container(
          width: width,
          height: height,
          color: AppColors.darkCard,
          child: const Icon(Icons.image_not_supported_outlined, color: AppColors.darkTextMuted),
        ),
      );
    }

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: AppColors.shimmerBase,
          highlightColor: AppColors.shimmerHighlight,
          child: Container(
            width: width,
            height: height,
            color: AppColors.darkCard,
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: AppColors.darkCard,
          child: const Icon(Icons.broken_image_outlined, color: AppColors.darkTextMuted),
        ),
      ),
    );
  }
}
