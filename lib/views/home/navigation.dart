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

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final title = ['分类', '我的'][selectedIndex];
    return UiMode.m1(context)
        ? NavigationBar(
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
          )
        : NavigationRail(
            leading: Text(title, style: context.textTheme.titleLarge),
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.none,
            elevation: 1,
            trailing: Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: [
                    IconButton(
                      onPressed: () => context.push('/search'),
                      icon: const Icon(Icons.search),
                      tooltip: '搜索',
                    ),
                    IconButton(
                      onPressed: () => context.push('/settings'),
                      icon: const Icon(Icons.settings),
                      tooltip: '设置',
                    ),
                    IconButton(
                      onPressed: () => context.push('/notifications'),
                      icon: const Icon(Icons.notifications),
                      tooltip: '通知',
                    ),
                  ],
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category),
                label: Text('分类'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('我的'),
              ),
            ],
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
        MenuAnchor(
          menuChildren: [
            MenuItemButton(
              style: MenuItemButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              leadingIcon: const Icon(Icons.settings, size: 17.0),
              onPressed: () => context.push('/settings'),
              child: const Text('设置'),
            ),
            MenuItemButton(
              style: MenuItemButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              leadingIcon: const Icon(Icons.notifications, size: 17.0),
              onPressed: () => context.push('/notifications'),
              child: const Text('通知'),
            ),
          ],
          builder: (context, controller, child) {
            return IconButton(
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              icon: const Icon(Icons.more_horiz),
              tooltip: '更多',
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
