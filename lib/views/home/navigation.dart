import 'package:flutter/material.dart';
import 'package:haka_comic/utils/ui.dart';

const List<dynamic> destinations = [
  {
    "icon": Icon(Icons.category_outlined),
    "selectedIcon": Icon(Icons.category),
    "label": '分类',
  },
  {
    "icon": Icon(Icons.person_outline),
    "selectedIcon": Icon(Icons.person),
    "label": '我的',
  },
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
      leading:
          UiMode.notM1(context)
              ? Text(title, style: Theme.of(context).textTheme.titleLarge)
              : null,
      selectedIndex: widget.selectedIndex,
      onDestinationSelected: widget.onDestinationSelected,
      labelType: NavigationRailLabelType.selected,
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
