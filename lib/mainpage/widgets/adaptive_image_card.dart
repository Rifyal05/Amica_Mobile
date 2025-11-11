import 'package:flutter/material.dart';

class AdaptiveImageCard extends StatefulWidget {
  final String imageUrl;
  const AdaptiveImageCard({super.key, required this.imageUrl});

  @override
  State<AdaptiveImageCard> createState() => _AdaptiveImageCardState();
}

class _AdaptiveImageCardState extends State<AdaptiveImageCard> {
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;
  double? _aspectRatio;

  @override
  void initState() {
    super.initState();
    _fetchImageInfo();
  }

  void _fetchImageInfo() {
    final image = NetworkImage(widget.imageUrl);
    _imageStream = image.resolve(const ImageConfiguration());
    final listener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
      if (mounted) {
        setState(() {
          _imageInfo = info;
          _aspectRatio = _imageInfo!.image.width / _imageInfo!.image.height;
        });
      }
    });
    _imageStream!.addListener(listener);
  }

  @override
  void dispose() {
    _imageStream?.removeListener(ImageStreamListener((_, __) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double maxImageHeight = 380.0;

    if (_aspectRatio == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width - 48;
    final displayHeight = screenWidth / _aspectRatio!;

    if (displayHeight <= maxImageHeight) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: AspectRatio(
          aspectRatio: _aspectRatio!,
          child: Container(
            color: theme.brightness == Brightness.dark ? Colors.black : theme.colorScheme.surfaceContainer,
            child: Image.network(
              widget.imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: SizedBox(
          height: maxImageHeight,
          width: double.infinity,
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
  }
}