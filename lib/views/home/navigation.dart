import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/ui.dart';

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const double _kDesktopNavigationWidth = 200;

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  Widget _buildMobileNavigationBar() {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.category_outlined),
          label: '分类',
          selectedIcon: Icon(Icons.category),
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: '我的',
          selectedIcon: Icon(Icons.person),
        ),
      ],
    );
  }

  Widget _buildDesktopNavigationMenu(BuildContext context) {
    final scheme = context.colorScheme;
    return SizedBox(
      width: _kDesktopNavigationWidth,
      child: Material(
        color: scheme.surface,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
          child: SafeArea(
            right: false,
            left: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(
                    child: Text(
                      'Haka Comic',
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _SideMenuItem(
                  selected: selectedIndex == 0,
                  icon: selectedIndex == 0
                      ? Icons.category
                      : Icons.category_outlined,
                  label: '分类',
                  onTap: () => onDestinationSelected(0),
                ),
                _SideMenuItem(
                  selected: selectedIndex == 1,
                  icon: selectedIndex == 1
                      ? Icons.person
                      : Icons.person_outline,
                  label: '我的',
                  onTap: () => onDestinationSelected(1),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    spacing: 4,
                    children: [
                      Divider(
                        height: 16,
                        indent: 16,
                        endIndent: 16,
                        color: scheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                      _SideMenuItem(
                        selected: false,
                        icon: Icons.search,
                        label: '搜索',
                        onTap: () => context.push('/search'),
                      ),
                      _SideMenuItem(
                        selected: false,
                        icon: Icons.notifications,
                        label: '通知',
                        onTap: () => context.push('/notifications'),
                      ),
                      _SideMenuItem(
                        selected: false,
                        icon: Icons.settings,
                        label: '设置',
                        onTap: () => context.push('/settings'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return UiMode.m1(context)
        ? _buildMobileNavigationBar()
        : _buildDesktopNavigationMenu(context);
  }
}

class _SideMenuItem extends StatelessWidget {
  const _SideMenuItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final bg = selected ? scheme.secondaryContainer : Colors.transparent;
    final fg = selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: scheme.primary.withValues(alpha: 0.08),
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                const SizedBox(width: 20),
                Icon(icon, size: 20, color: fg),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: fg,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  const AppHeaderBar({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final title = ['分类', '我的'][selectedIndex];
    final isCategory = title == '分类';
    final systemUiOverlayStyle = Theme.brightnessOf(context) == Brightness.light
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light;
    return AppBar(
      title: Text(title),
      backgroundColor: isCategory ? null : Colors.transparent,
      systemOverlayStyle: isCategory ? null : systemUiOverlayStyle,
      actions: [
        IconButton(
          onPressed: () => context.push('/search'),
          icon: const Icon(Icons.search),
          tooltip: '搜索',
        ),
        IconButton(
          onPressed: () => context.push('/notifications'),
          icon: const Icon(Icons.notifications),
          tooltip: '通知',
        ),
        IconButton(
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.settings),
          tooltip: '设置',
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
