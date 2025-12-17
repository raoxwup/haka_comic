import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

class BaseImage extends StatelessWidget {
  const BaseImage({
    super.key,
    this.url = '',
    this.aspectRatio,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.shape,
    this.filterQuality = FilterQuality.low,
  });

  final String url;

  final double? aspectRatio;

  final BoxFit fit;

  final double? width;

  final double? height;

  final ShapeBorder? shape;

  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    return aspectRatio == null ? _buildImage() : _buildAspectRatio();
  }

  Widget _buildAspectRatio() {
    return AspectRatio(aspectRatio: aspectRatio!, child: _buildImage());
  }

  Widget _buildImage() {
    return Card(
      clipBehavior: Clip.hardEdge,
      shape: shape,
      elevation: 0,
      child: url.isEmpty
          ? Image.asset(
              'assets/images/login.png',
              fit: fit,
              width: width,
              height: height,
            )
          : ExtendedImage.network(
              url,
              fit: fit,
              width: width,
              height: height,
              enableLoadState: true,
              timeRetry: const Duration(microseconds: 300),
              filterQuality: filterQuality,
              loadStateChanged: (state) {
                if (state.extendedImageLoadState == LoadState.failed) {
                  return Center(
                    child: IconButton(
                      onPressed: state.reLoadImage,
                      icon: const Icon(Icons.refresh),
                    ),
                  );
                }

                if (state.extendedImageLoadState == LoadState.completed) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(opacity: value, child: child);
                    },
                    child: state.completedWidget,
                  );
                }

                if (state.extendedImageLoadState == LoadState.loading) {
                  return const Card(elevation: 0);
                }

                return null;
              },
            ),
    );
  }
}
