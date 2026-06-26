import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/widgets/ui_avatar.dart';
import 'package:haka_comic/widgets/ui_image.dart';

class ProFile extends StatelessWidget {
  const ProFile({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200 + context.top,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ClipRect(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 8,
                  sigmaY: 8,
                  tileMode: TileMode.mirror,
                ),
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.transparent,
                        context.colorScheme.surface,
                        context.colorScheme.surface.withValues(alpha: 0.3),
                      ],
                      stops: [0.02, 0.5, 0.85],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: user.avatar != null
                      ? UiImage(
                          url: user.avatar!.url,
                          cacheKey: user.avatar!.cacheKey,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/images/default_avatar.jpg',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: context.top),
              UiAvatar(source: user.avatar, size: 80),
              Text(
                user.name,
                style: context.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Lv.${user.level}  Exp: ${user.exp}',
                style: context.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  user.slogan,
                  style: context.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Positioned(
            right: 10,
            top: 10 + context.top,
            child: IconButton(
              onPressed: () => context.push('/personal_editor'),
              icon: const Icon(Icons.drive_file_rename_outline),
            ),
          ),
        ],
      ),
    );
  }
}
