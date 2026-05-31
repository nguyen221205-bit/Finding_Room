import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/image_utils.dart';

class AppImage extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final IconData placeholderIcon;

  const AppImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderIcon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    if (!ImageUtils.isUsablePath(imagePath)) {
      return _Placeholder(icon: placeholderIcon);
    }

    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final double? w = width;
    final double? h = height;
    final int? targetCacheWidth = w != null && w.isFinite
        ? (w * devicePixelRatio).round()
        : null;
    final int? targetCacheHeight = h != null && h.isFinite
        ? (h * devicePixelRatio).round()
        : null;

    if (ImageUtils.isNetworkImage(imagePath)) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: fit,
        width: width,
        height: height,
        memCacheWidth: targetCacheWidth,
        memCacheHeight: targetCacheHeight,
        placeholder: (_, _) => _Placeholder(icon: placeholderIcon),
        errorWidget: (_, _, _) =>
            const _Placeholder(icon: Icons.image_not_supported_outlined),
      );
    }

    if (kIsWeb) {
      if (imagePath.startsWith('assets/')) {
        return Image.asset(
          imagePath,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, _, _) =>
              const _Placeholder(icon: Icons.image_not_supported_outlined),
        );
      }
      return const _Placeholder(icon: Icons.image_not_supported_outlined);
    }

    final File file = File(imagePath);
    if (!file.existsSync()) {
      return const _Placeholder(icon: Icons.image_not_supported_outlined);
    }

    return Image.file(
      file,
      fit: fit,
      width: width,
      height: height,
      cacheWidth:
          targetCacheWidth ??
          600, // Safe default to prevent decoding massive photos at full resolution
      cacheHeight: targetCacheHeight,
      errorBuilder: (_, _, _) =>
          const _Placeholder(icon: Icons.image_not_supported_outlined),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final IconData icon;

  const _Placeholder({required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: AppColors.shimmer,
        child: Center(child: Icon(icon, color: AppColors.textHint)),
      ),
    );
  }
}
