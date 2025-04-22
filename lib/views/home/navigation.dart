import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/ui.dart';

final List<dynamic> destinations = [
  {
    "icon": Icon(Icons.category_outlined),
    "selectedIcon": Icon(Icons.category),
    "label": '分类',
    "extendBodyBehindAppBar": false,
    "buildAppBar":
        (BuildContext context) => AppBar(
          title: const Text('分类'),
          actions:
              actions
                  .map(
                    (e) => IconButton(
                      tooltip: e['label'],
                      onPressed: () => context.push(e['path']),
                      icon: e['icon']!,
                    ),
                  )
                  .toList(),
        ),
  },
  {
    "icon": Icon(Icons.person_outline),
    "selectedIcon": Icon(Icons.person),
    "label": '我的',
    "extendBodyBehindAppBar": true,
    "buildAppBar":
        (BuildContext context) => AppBar(
          title: const Text('我的'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          actions:
              actions
                  .map(
                    (e) => IconButton(
                      tooltip: e['label'],
                      onPressed: () => context.push(e['path']),
                      icon: e['icon']!,
                    ),
                  )
                  .toList(),
        ),
  },
];

const List<dynamic> actions = [
  {"icon": Icon(Icons.search), "label": '搜索', "path": '/search'},
  {"icon": Icon(Icons.settings), "label": '设置', "path": '/settings'},
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
  @override
  Widget build(BuildContext context) {
    return UiMode.m1(context) ? _buildNavigationBar() : _buildNavigationRail();
  }

  Widget _buildNavigationBar() {
    return NavigationBar(
      selectedIndex: widget.selectedIndex,
      onDestinationSelected: widget.onDestinationSelected,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      destinations:
          destinations
              .map(
                (e) => NavigationDestination(
                  icon: e['icon'],
                  label: e['label'],
                  selectedIcon: e['selectedIcon'],
                ),
              )
              .toList(),
    );
  }

  Widget _buildNavigationRail() {
    final title = destinations[widget.selectedIndex]['label'];
    return NavigationRail(
      leading: Text(title, style: context.textTheme.titleLarge),
      selectedIndex: widget.selectedIndex,
      onDestinationSelected: widget.onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      elevation: 1,
      trailing: Expanded(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 8,
            children:
                actions
                    .map(
                      (e) => IconButton(
                        tooltip: e['label'],
                        icon: e['icon']!,
                        onPressed: () => context.push(e['path']),
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
      destinations:
          destinations
              .map(
                (e) => NavigationRailDestination(
                  icon: e['icon']!,
                  selectedIcon: e['selectedIcon']!,
                  label: Text(e['label']!),
                ),
              )
              .toList(),
    );
  }
}
