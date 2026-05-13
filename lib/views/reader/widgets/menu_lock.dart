import 'package:flutter/material.dart';
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
    final left = lockMenu && !expanded ? context.left - 18 : context.left + 8;

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
              ? _MenuLockButton(
                  key: const ValueKey('menu_lock_button'),
                  lockMenu: lockMenu,
                  collapsed: lockMenu && !expanded,
                  onTap: () => _toggleLockMenu(context),
                )
              : const SizedBox.shrink(key: ValueKey('menu_lock_hidden')),
        ),
      ),
    );
  }
}

class _MenuLockButton extends StatelessWidget {
  const _MenuLockButton({
    super.key,
    required this.lockMenu,
    required this.collapsed,
    required this.onTap,
  });

  final bool lockMenu;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final tooltip = lockMenu ? (collapsed ? '展开菜单锁' : '解锁菜单') : '锁定菜单';
    final foreground = lockMenu
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
      value: lockMenu ? '已锁定' : '未锁定',
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
                collapsed ? 'menu_lock_collapsed' : 'menu_lock_expanded',
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
                  lockMenu
                      ? (collapsed ? Icons.arrow_right : Icons.lock_rounded)
                      : Icons.lock_open_rounded,
                  key: ValueKey(lockMenu),
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
