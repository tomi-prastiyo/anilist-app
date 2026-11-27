import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
          color: context.appCard,
          child: Icon(Icons.image_not_supported_outlined, color: context.appTextMuted),
        ),
      );
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW =
        (width != null && width!.isFinite) ? (width! * dpr).round().clamp(32, 1200) : null;
    final cacheH =
        (height != null && height!.isFinite) ? (height! * dpr).round().clamp(32, 1200) : null;

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: cacheW,
        memCacheHeight: cacheH,
        fadeInDuration: const Duration(milliseconds: 150),
        fadeOutDuration: const Duration(milliseconds: 80),
        placeholder: (context, url) => SizedBox(
          width: width,
          height: height,
          child: ColoredBox(color: context.appInputSurface),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: context.appCard,
          child: Icon(Icons.broken_image_outlined, color: context.appTextMuted),
        ),
      ),
    );
  }
}
