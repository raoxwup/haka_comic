import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:sidebarx/sidebarx.dart';

const _tabs = [
  _NavigationTab(
    title: '分类',
    icon: Icons.category_outlined,
    selectedIcon: Icons.category,
  ),
  _NavigationTab(
    title: '我的',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

const _sideActions = [
  _SideAction(route: '/search', title: '搜索', icon: Icons.search),
  _SideAction(route: '/settings', title: '设置', icon: Icons.settings),
  _SideAction(route: '/notifications', title: '通知', icon: Icons.notifications),
];

class AppNavigationBar extends StatefulWidget {
  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  State<AppNavigationBar> createState() => _AppNavigationBarState();
}

class _AppNavigationBarState extends State<AppNavigationBar> {
  late final SidebarXController _sidebarController;

  @override
  void initState() {
    super.initState();
    _sidebarController = SidebarXController(
      selectedIndex: widget.selectedIndex,
      extended: true,
    );
  }

  @override
  void didUpdateWidget(covariant AppNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sidebarController.selectedIndex != widget.selectedIndex) {
      _sidebarController.selectIndex(widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    super.dispose();
  }

  List<SidebarXItem> _buildSidebarItems() {
    return List.generate(_tabs.length, (index) {
      final tab = _tabs[index];
      return SidebarXItem(
        label: tab.title,
        iconBuilder: (selected, hovered) =>
            Icon(selected ? tab.selectedIcon : tab.icon),
        onTap: () => widget.onDestinationSelected(index),
      );
    });
  }

  List<SidebarXItem> _buildSidebarActions(BuildContext context) {
    return _sideActions
        .map(
          (item) => SidebarXItem(
            label: item.title,
            icon: item.icon,
            selectable: false,
            onTap: () => context.push(item.route),
          ),
        )
        .toList();
  }

  Widget _buildMobileNavigationBar() {
    return NavigationBar(
      selectedIndex: widget.selectedIndex,
      onDestinationSelected: widget.onDestinationSelected,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      destinations: _tabs
          .map(
            (tab) => NavigationDestination(
              icon: Icon(tab.icon),
              label: tab.title,
              selectedIcon: Icon(tab.selectedIcon),
            ),
          )
          .toList(),
    );
  }

  Widget _buildDesktopSidebar(BuildContext context) {
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;

    return SidebarX(
      controller: _sidebarController,
      items: _buildSidebarItems(),
      footerItems: _buildSidebarActions(context),
      animationDuration: const Duration(milliseconds: 240),
      collapseIcon: Icons.keyboard_double_arrow_left_rounded,
      extendIcon: Icons.keyboard_double_arrow_right_rounded,
      theme: SidebarXTheme(
        width: 84,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          border: Border(
            right: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 22),
        selectedIconTheme: IconThemeData(
          color: scheme.onSecondaryContainer,
          size: 22,
        ),
        textStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        selectedTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
        hoverColor: scheme.surfaceContainerHighest,
        hoverTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
        hoverIconTheme: IconThemeData(color: scheme.onSurface),
        itemPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        selectedItemPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        itemTextPadding: const EdgeInsets.only(left: 12),
        selectedItemTextPadding: const EdgeInsets.only(left: 12),
        itemDecoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        selectedItemDecoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      extendedTheme: const SidebarXTheme(width: 160, padding: .all(8.0)),
      headerBuilder: (context, extended) {
        return Padding(
          padding: const .symmetric(vertical: 10),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: extended
                  ? const Text(
                      'HaKa Comic',
                      key: ValueKey('header_title_HaKaComic'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const Text(
                      'HaKa',
                      key: ValueKey('header_title_HaKa'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        );
      },
      headerDivider: Divider(
        height: 1,
        thickness: 1,
        color: scheme.outlineVariant.withValues(alpha: 0.5),
      ),
      footerDivider: Divider(
        height: 1,
        thickness: 1,
        color: scheme.outlineVariant.withValues(alpha: 0.35),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return UiMode.m1(context)
        ? _buildMobileNavigationBar()
        : _buildDesktopSidebar(context);
  }
}

class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  const AppHeaderBar({super.key, required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final title = _tabs[selectedIndex].title;
    final isCategory = title == '分类';
    final systemUiOverlayStyle =
        Theme.of(context).brightness == Brightness.light
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

class _NavigationTab {
  const _NavigationTab({
    required this.title,
    required this.icon,
    required this.selectedIcon,
  });

  final String title;
  final IconData icon;
  final IconData selectedIcon;
}

class _SideAction {
  const _SideAction({
    required this.route,
    required this.title,
    required this.icon,
  });

  final String route;
  final String title;
  final IconData icon;
}
