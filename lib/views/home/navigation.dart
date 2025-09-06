import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/home/share_dialog.dart';

final List<dynamic> destinations = [
  {
    "icon": Icons.category_outlined,
    "selectedIcon": Icons.category,
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
                      onPressed: () => e['onPressed'](context),
                      icon: Icon(e['icon']),
                    ),
                  )
                  .toList(),
        ),
  },
  {
    "icon": Icons.person_outline,
    "selectedIcon": Icons.person,
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
                      onPressed: () => e['onPressed'](context),
                      icon: Icon(e['icon']),
                    ),
                  )
                  .toList(),
        ),
  },
];

final List<dynamic> actions = [
  {
    "icon": Icons.search,
    "label": '搜索',
    "onPressed": (BuildContext context) {
      context.push('/search');
    },
  },
  {
    "icon": Icons.content_paste_go,
    "label": '漫画ID搜索',
    "onPressed": (BuildContext context) {
      showDialog(context: context, builder: (context) => const ShareDialog());
    },
  },
  {
    "icon": Icons.notifications,
    "label": '通知',
    "onPressed": (BuildContext context) {
      context.push('/notifications');
    },
  },
  {
    "icon": Icons.settings,
    "label": '设置',
    "onPressed": (BuildContext context) {
      context.push('/settings');
    },
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
                  icon: Icon(e['icon']),
                  label: e['label'],
                  selectedIcon: Icon(e['selectedIcon']),
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
      labelType: NavigationRailLabelType.none,
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
                        icon: Icon(e['icon']),
                        onPressed: () => e['onPressed'](context),
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
                  icon: Icon(e['icon']),
                  selectedIcon: Icon(e['selectedIcon']),
                  label: Text(e['label']),
                ),
              )
              .toList(),
    );
  }
}
