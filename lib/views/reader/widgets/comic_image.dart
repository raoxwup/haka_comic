// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:haka_comic/database/images_helper.dart';
// import 'package:haka_comic/utils/extension.dart';

// class ComicImage extends StatefulWidget {
//   const ComicImage({
//     super.key,
//     required this.url,
//     required this.onImageSizeChanged,
//     this.imageSize,
//     this.fit = BoxFit.fitWidth,
//   }) : useCacheSize = true;

//   const ComicImage.noUseCache({
//     super.key,
//     required this.url,
//     required this.onImageSizeChanged,
//     this.fit = BoxFit.contain,
//   }) : useCacheSize = false,
//        imageSize = null;

//   /// 图片 url
//   final String url;

//   /// 图片尺寸回调
//   final void Function(int width, int height) onImageSizeChanged;

//   /// 缓存的图片尺寸（用于条漫预占位）
//   final ImageSize? imageSize;

//   /// 是否使用缓存尺寸（条漫模式）
//   final bool useCacheSize;

//   /// 图片 fit
//   final BoxFit fit;

//   @override
//   State<ComicImage> createState() => _ComicImageState();
// }

// class _ComicImageState extends State<ComicImage> {
//   static const double _fallbackAspectRatio = 3 / 4;

//   int _version = 0;
//   ImageStream? _imageStream;
//   ImageStreamListener? _listener;
//   Size? _reportedSize;

//   Future<void> _refreshImage() async {
//     await CachedNetworkImage.evictFromCache(widget.url);
//     if (mounted) {
//       setState(() => _version++);
//     }
//   }

//   void _removeListener() {
//     if (_imageStream != null && _listener != null) {
//       _imageStream!.removeListener(_listener!);
//     }
//     _imageStream = null;
//     _listener = null;
//   }

//   @override
//   void dispose() {
//     _removeListener();
//     super.dispose();
//   }

//   Widget _buildPlaceholder(Widget child) {
//     if (!widget.useCacheSize) {
//       return Center(child: child);
//     }

//     final aspectRatio = widget.imageSize != null
//         ? widget.imageSize!.width / widget.imageSize!.height
//         : _fallbackAspectRatio;

//     return AspectRatio(
//       aspectRatio: aspectRatio,
//       child: Center(child: child),
//     );
//   }

//   void _listenImageSize(ImageProvider provider) {
//     final stream = provider.resolve(createLocalImageConfiguration(context));

//     if (stream == _imageStream) return;

//     _removeListener();
//     _imageStream = stream;

//     _listener = ImageStreamListener((info, _) {
//       final size = Size(
//         info.image.width.toDouble(),
//         info.image.height.toDouble(),
//       );

//       if (_reportedSize == size) return;
//       _reportedSize = size;

//       widget.onImageSizeChanged(info.image.width, info.image.height);

//       _removeListener();
//     });

//     stream.addListener(_listener!);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return CachedNetworkImage(
//       key: ValueKey('${widget.url}_$_version'),
//       imageUrl: widget.url,
//       fit: widget.fit,
//       fadeOutDuration: Duration.zero,
//       progressIndicatorBuilder: (_, _, progress) {
//         return _buildPlaceholder(
//           CircularProgressIndicator(
//             value: progress.progress ?? 0,
//             strokeWidth: 3,
//             constraints: BoxConstraints.tight(const Size(28, 28)),
//             backgroundColor: Colors.grey.shade300,
//             color: context.colorScheme.primary,
//             strokeCap: StrokeCap.round,
//           ),
//         );
//       },
//       errorWidget: (_, _, _) {
//         return _buildPlaceholder(
//           IconButton(onPressed: _refreshImage, icon: const Icon(Icons.refresh)),
//         );
//       },
//       imageBuilder: (_, provider) {
//         _listenImageSize(provider);
//         return Image(image: provider, fit: widget.fit);
//       },
//     );
//   }
// }
