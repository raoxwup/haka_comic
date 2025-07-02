import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/model/reader_provider.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/reader/reader.dart';
import 'package:haka_comic/widgets/with_blur.dart';

/// 顶部工具栏
class ReaderAppBar extends StatelessWidget {
  const ReaderAppBar({
    super.key,
    required this.showToolbar,
    required this.readMode,
    required this.onReadModeChanged,
  });

  final bool showToolbar;

  final ReadMode readMode;

  final ValueChanged<ReadMode> onReadModeChanged;

  @override
  Widget build(BuildContext context) {
    final top = context.top;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      top: showToolbar ? 0 : -(kToolbarHeight + top),
      left: 0,
      right: 0,
      height: kToolbarHeight + top,
      child: WithBlur(
        child: AppBar(
          leading: IconButton(
            icon: Icon(
              (isIos || isMacOS) ? Icons.arrow_back_ios_new : Icons.arrow_back,
            ),
            onPressed: () => context.pop(),
          ),
          actions: [
            MenuAnchor(
              menuChildren:
                  ReadMode.values.map((mode) {
                    return MenuItemButton(
                      onPressed: () => onReadModeChanged(mode),
                      child: Row(
                        spacing: 5,
                        children: [
                          Text(readModeToString(mode)),
                          if (mode == readMode)
                            Icon(
                              Icons.done,
                              size: 16,
                              color: context.colorScheme.primary,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
              builder: (context, controller, child) {
                return IconButton(
                  icon: const Icon(Icons.chrome_reader_mode_outlined),
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                );
              },
            ),
          ],
          title: Text(context.reader.title),
          backgroundColor: context.colorScheme.surface.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}
