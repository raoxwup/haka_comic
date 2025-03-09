import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class BaseImage extends StatefulWidget {
  const BaseImage({
    super.key,
    required this.url,
    this.aspectRatio = 1,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.progressIndicatorBuilder,
    this.errorBuilder,
  });

  final String url;

  final double aspectRatio;

  final BoxFit fit;

  final double? width;

  final double? height;

  final Widget Function(BuildContext, String, DownloadProgress)?
  progressIndicatorBuilder;

  final Widget Function(BuildContext, String, Object)? errorBuilder;

  @override
  State<BaseImage> createState() => _BaseImageState();
}

class _BaseImageState extends State<BaseImage> {
  UniqueKey key = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Card(
        clipBehavior: Clip.hardEdge,
        elevation: 0,
        child: CachedNetworkImage(
          key: key,
          imageUrl: widget.url,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          progressIndicatorBuilder: widget.progressIndicatorBuilder,
          errorWidget:
              widget.errorBuilder ??
              (context, url, error) => IconButton(
                onPressed: () {
                  setState(() {
                    key = UniqueKey();
                  });
                },
                icon: Icon(Icons.error),
              ),
        ),
      ),
    );
  }
}
