import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/reader/providers/list_state_provider.dart';
import 'package:haka_comic/views/reader/providers/reader_provider.dart';

class MenuLock extends StatelessWidget {
  const MenuLock({super.key});

  static const _duration = Duration(milliseconds: 220);

  void _toggleLockMenu(BuildContext context) {
    final lockMenu = context.stateReader.lockMenu;
    final menuLockExpanded = context.reader.menuLockExpanded;

    if (lockMenu && !menuLockExpanded) {
      context.reader.expandMenuLock();
      return;
    }

    context.stateReader.toggleLockMenu();
    if (lockMenu) {
      context.reader.collapseMenuLock();
      return;
    }

    context.reader.hideToolbar();
    context.reader.hideMenuLock();
  }

  @override
  Widget build(BuildContext context) {
    final showMenuLock = context.selector((p) => p.showMenuLock);
    final menuLockExpanded = context.selector((p) => p.menuLockExpanded);
    final lockMenu = context.stateSelector((p) => p.lockMenu);
    final visible = lockMenu || showMenuLock;
    final expanded = !lockMenu || menuLockExpanded;
    final collapsed = lockMenu && !expanded;
    final showBack = lockMenu && expanded;
    final left = collapsed ? context.left - 18 : context.left + 8;

    return AnimatedPositioned(
      duration: _duration,
      curve: Curves.easeOutCubic,
      left: left,
      top: 0,
      bottom: 0,
      child: Center(
        child: AnimatedSwitcher(
          duration: _duration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(-0.35, 0),
              end: Offset.zero,
            ).animate(animation);

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offsetAnimation, child: child),
            );
          },
          child: visible
              ? Column(
                  key: const ValueKey('menu_lock_group'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: _duration,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            alignment: const AlignmentDirectional(-1.0, -1.0),
                            child: child,
                          ),
                        );
                      },
                      child: showBack
                          ? Padding(
                              key: const ValueKey('menu_lock_back'),
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _EdgeCircleButton(
                                icon: (isIOS || isMacOS)
                                    ? Icons.arrow_back_ios_new
                                    : Icons.arrow_back,
                                tooltip: '返回',
                                collapsed: false,
                                onTap: () => context.pop(),
                              ),
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('menu_lock_back_hidden'),
                            ),
                    ),
                    _EdgeCircleButton(
                      key: const ValueKey('menu_lock_button'),
                      icon: lockMenu
                          ? (collapsed ? Icons.arrow_right : Icons.lock_rounded)
                          : Icons.lock_open_rounded,
                      iconKey: ValueKey(lockMenu),
                      tooltip: lockMenu
                          ? (collapsed ? '展开菜单锁' : '解锁菜单')
                          : '锁定菜单',
                      collapsed: collapsed,
                      accent: lockMenu,
                      semanticsValue: lockMenu ? '已锁定' : '未锁定',
                      onTap: () => _toggleLockMenu(context),
                    ),
                  ],
                )
              : const SizedBox.shrink(key: ValueKey('menu_lock_hidden')),
        ),
      ),
    );
  }
}

class _EdgeCircleButton extends StatelessWidget {
  const _EdgeCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.collapsed,
    required this.onTap,
    this.accent = false,
    this.iconKey,
    this.semanticsValue,
  });

  final IconData icon;
  final String tooltip;
  final bool collapsed;
  final VoidCallback onTap;
  final bool accent;
  final Key? iconKey;
  final String? semanticsValue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final foreground = accent
        ? (collapsed
              ? colorScheme.primary.withValues(alpha: 0.72)
              : colorScheme.primary)
        : colorScheme.onSurfaceVariant;
    final surfaceAlpha = collapsed ? 0.42 : 0.66;
    final outlineAlpha = collapsed ? 0.28 : 0.45;
    final shadowAlpha = collapsed ? 0.08 : 0.14;
    final borderRadius = collapsed
        ? const BorderRadius.horizontal(right: Radius.circular(22))
        : BorderRadius.circular(22);
    final shape = RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: outlineAlpha),
      ),
    );

    return Semantics(
      button: true,
      label: tooltip,
      value: semanticsValue,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: colorScheme.surfaceContainerHighest.withValues(
            alpha: surfaceAlpha,
          ),
          shape: shape,
          clipBehavior: Clip.antiAlias,
          elevation: 1,
          shadowColor: colorScheme.shadow.withValues(alpha: shadowAlpha),
          child: InkWell(
            onTap: onTap,
            customBorder: shape,
            child: AnimatedContainer(
              key: ValueKey(
                collapsed ? 'edge_button_collapsed' : 'edge_button_expanded',
              ),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 42,
              height: 42,
              padding: collapsed ? const EdgeInsets.only(left: 18) : null,
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  icon,
                  key: iconKey ?? ValueKey(icon),
                  color: foreground,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
