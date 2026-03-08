import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/reader/providers/list_state_provider.dart';
import 'package:haka_comic/views/reader/providers/reader_provider.dart';
import 'package:haka_comic/views/reader/state/read_mode.dart';
import 'package:haka_comic/views/reader/widgets/reader_settings.dart';
import 'package:haka_comic/widgets/with_blur.dart';
import 'package:provider/provider.dart';

/// 顶部工具栏
class ReaderAppBar extends StatelessWidget {
  const ReaderAppBar({super.key});

  void _openSettings(BuildContext cx) {
    showDialog(
      useSafeArea: false,
      context: cx,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: cx.reader),
          ChangeNotifierProvider.value(value: cx.stateReader),
        ],
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Dialog(
              insetPadding: UiMode.m1(context)
                  ? .zero
                  : const .symmetric(horizontal: 40, vertical: 24),
              child: SizedBox(
                width: UiMode.m1(context) ? constraints.maxWidth : 400,
                height: UiMode.m1(context) ? constraints.maxHeight : null,
                child: const ReaderSettings(),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showToolbar = context.selector((p) => p.showToolbar);

    final readMode = context.selector((p) => p.readMode);

    final title = context.selector((p) => p.title);

    final top = context.top;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      top: showToolbar ? 0 : -(kToolbarHeight + top),
      left: 0,
      right: 0,
      height: kToolbarHeight + top,
      child: RepaintBoundary(
        child: WithBlur(
          child: AppBar(
            leading: IconButton(
              icon: Icon(
                (isIOS || isMacOS)
                    ? Icons.arrow_back_ios_new
                    : Icons.arrow_back,
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.tune),
                    tooltip: '设置',
                    onPressed: () => _openSettings(context),
                  );
                },
              ),
              MenuAnchor(
                menuChildren: ReadMode.values.map((mode) {
                  return MenuItemButton(
                    onPressed: () {
                      context.reader.readMode = mode;
                      context.reader.openOrCloseToolbar();
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
      ),
    );
  }
}
