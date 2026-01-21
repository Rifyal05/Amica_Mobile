import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdaptiveImageCard extends StatefulWidget {
  final String imageUrl;
  const AdaptiveImageCard({super.key, required this.imageUrl});

  @override
  State<AdaptiveImageCard> createState() => _AdaptiveImageCardState();
}

class _AdaptiveImageCardState extends State<AdaptiveImageCard> {
  double? _aspectRatio;
  bool _isValidUrl = false;

  @override
  void initState() {
    super.initState();
    _checkAndFetch();
  }

  void _checkAndFetch() {
    if (widget.imageUrl.isEmpty) {
      _isValidUrl = false;
      return;
    }
    _isValidUrl = true;

    final image = CachedNetworkImageProvider(
      widget.imageUrl,
      cacheKey: widget.imageUrl,
    );

    image
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener((ImageInfo info, bool synchronousCall) {
            if (mounted) {
              setState(() {
                _aspectRatio = info.image.width / info.image.height;
              });
            }
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double maxImageHeight = 380.0;

    if (!_isValidUrl) {
      return const SizedBox.shrink();
    }

    if (_aspectRatio == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width - 32;
    final displayHeight = screenWidth / _aspectRatio!;
    final borderRadius = BorderRadius.circular(12.0);

    if (displayHeight <= maxImageHeight) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: AspectRatio(
          aspectRatio: _aspectRatio!,
          child: Container(
            color: theme.brightness == Brightness.dark
                ? Colors.black
                : theme.colorScheme.surfaceContainer,
            child: CachedNetworkImage(
              imageUrl: widget.imageUrl,
              cacheKey: widget.imageUrl,
              fit: BoxFit.contain,
              fadeInDuration: const Duration(milliseconds: 200),
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image),
            ),
          ),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(
          height: maxImageHeight,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: widget.imageUrl,
            cacheKey: widget.imageUrl,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            errorWidget: (context, url, error) =>
                const Icon(Icons.broken_image),
          ),
        ),
      );
    }
  }
}
