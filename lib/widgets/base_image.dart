import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class BaseImage extends StatefulWidget {
  const BaseImage({
    super.key,
    required this.url,
    this.aspectRatio,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.progressIndicatorBuilder,
    this.errorBuilder,
    this.shape,
    this.imageBuilder,
  });

  final String url;

  final double? aspectRatio;

  final BoxFit fit;

  final double? width;

  final double? height;

  final ShapeBorder? shape;

  final Widget Function(BuildContext, String, DownloadProgress)?
  progressIndicatorBuilder;

  final Widget Function(BuildContext, String, Object)? errorBuilder;

  final Widget Function(BuildContext, ImageProvider)? imageBuilder;

  @override
  State<BaseImage> createState() => _BaseImageState();
}

class _BaseImageState extends State<BaseImage> {
  final ValueNotifier<UniqueKey> keyNotifier = ValueNotifier<UniqueKey>(
    UniqueKey(),
  );

  @override
  Widget build(BuildContext context) {
    return widget.aspectRatio == null ? _buildImage() : _buildAspectRatio();
  }

  Widget _buildAspectRatio() {
    return AspectRatio(aspectRatio: widget.aspectRatio!, child: _buildImage());
  }

  Widget _buildImage() {
    return Card(
      clipBehavior: Clip.hardEdge,
      shape: widget.shape,
      elevation: 0,
      child: ValueListenableBuilder(
        valueListenable: keyNotifier,
        builder:
            (context, value, child) => CachedNetworkImage(
              key: value,
              imageUrl: widget.url,
              fit: widget.fit,
              width: widget.width ?? double.infinity,
              height: widget.height ?? double.infinity,
              progressIndicatorBuilder: widget.progressIndicatorBuilder,
              errorWidget:
                  widget.errorBuilder ??
                  (context, url, error) => Center(
                    child: IconButton(
                      onPressed: () {
                        keyNotifier.value = UniqueKey();
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
              imageBuilder: widget.imageBuilder,
            ),
      ),
    );
  }
}
