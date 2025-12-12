import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/views/reader/providers/comic_state_provider.dart';
import 'package:haka_comic/views/reader/providers/read_mode_provider.dart';
import 'package:haka_comic/views/reader/providers/toolbar_provider.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/reader/state/read_mode.dart';
import 'package:haka_comic/widgets/with_blur.dart';

/// 顶部工具栏
class ReaderAppBar extends ConsumerWidget {
  const ReaderAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showToolbar = ref.watch(toolbarProvider);

    final readMode = ref.watch(readModeProvider);

    final title = ref.watch(
      comicReaderStateProvider(routerPayloadCache).select((p) => p.title),
    );

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
              menuChildren: ReadMode.values.map((mode) {
                return MenuItemButton(
                  onPressed: () {
                    ref.read(readModeProvider.notifier).readMode = mode;
                    ref.read(toolbarProvider.notifier).openOrCloseToolbar();
                  },
                  child: Row(
                    spacing: 5,
                    children: [
                      Text(mode.displayName),
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
          title: Text(title),
          backgroundColor: context.colorScheme.secondaryContainer.withValues(
            alpha: 0.6,
          ),
        ),
      ),
    );
  }
}
