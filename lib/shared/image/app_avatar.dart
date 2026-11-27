import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    required this.imageUrl,
    this.size = 40.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round().clamp(32, 512);

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.appCard,
        border: Border.all(color: context.appBorder, width: 1.5),
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                memCacheWidth: cacheSize,
                memCacheHeight: cacheSize,
                fadeInDuration: const Duration(milliseconds: 140),
                placeholder: (context, url) => ColoredBox(color: context.appInputSurface),
                errorWidget: (context, url, error) =>
                    Icon(Icons.person, color: context.appTextMuted),
              )
            : Icon(Icons.person, color: context.appTextMuted),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }
    return avatar;
  }
}
