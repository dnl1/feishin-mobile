import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../library_providers.dart';

/// Album/artist/playlist artwork with caching and a graceful fallback.
class CoverArt extends ConsumerWidget {
  const CoverArt({
    super.key,
    required this.imageId,
    this.size = 300,
    this.borderRadius = 8,
    this.fallbackIcon = Icons.album,
  });

  final double borderRadius;
  final IconData fallbackIcon;
  final String? imageId;

  /// Requested server-side image size (also used as the cache key).
  final int size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(imageUrlProvider((imageId: imageId, size: size)));

    final fallback = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(fallbackIcon, color: Theme.of(context).colorScheme.outline),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AspectRatio(
        aspectRatio: 1,
        child: url == null
            ? fallback
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) => fallback,
                errorWidget: (context, url, error) => fallback,
              ),
      ),
    );
  }
}
