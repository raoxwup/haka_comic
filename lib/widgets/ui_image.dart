import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:haka_comic/utils/extension.dart';

class UiImage extends StatelessWidget {
  const UiImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth = 300,
    this.cacheHeight,
    this.shape,
    this.border,
    this.borderRadius,
    this.clipBehavior = Clip.antiAlias,
    this.filterQuality = FilterQuality.low,
  });

  final String url;

  final BoxFit fit;

  final double? width;

  final double? height;

  final int cacheWidth;

  final int? cacheHeight;

  final BoxShape? shape;

  final BoxBorder? border;

  final BorderRadius? borderRadius;

  final Clip clipBehavior;

  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    return ExtendedImage.network(
      url,
      cache: true,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: ((width ?? cacheWidth) * devicePixelRatio).round(),
      cacheHeight: cacheHeight,
      shape: shape,
      border: border,
      borderRadius: borderRadius,
      clipBehavior: clipBehavior,
      timeRetry: const Duration(microseconds: 300),
      filterQuality: filterQuality,
      loadStateChanged: (state) {
        if (state.extendedImageLoadState != LoadState.failed) {
          return Stack(
            fit: .passthrough,
            children: [
              AnimatedOpacity(
                opacity: state.extendedImageLoadState == LoadState.completed
                    ? 1
                    : 0,
                duration: const Duration(milliseconds: 300),
                child: state.completedWidget,
              ),
              if (state.extendedImageLoadState == LoadState.loading)
                Container(color: context.colorScheme.secondaryContainer),
            ],
          );
        }

        if (state.extendedImageLoadState == LoadState.failed) {
          return Container(
            color: context.colorScheme.secondaryContainer,
            child: Center(
              child: IconButton(
                onPressed: state.reLoadImage,
                icon: const Icon(Icons.refresh),
              ),
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
          return Container(color: context.colorScheme.secondaryContainer);
        }

        return null;
      },
    );
  }
}
