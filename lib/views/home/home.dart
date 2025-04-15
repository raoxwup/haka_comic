import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/categories/categories.dart';
import 'package:haka_comic/views/home/navigation.dart';
import 'package:haka_comic/views/mine/mine.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  bool isRouteAnimationCompleted = false;

  Widget buildAppNavigationBar() => AppNavigationBar(
    selectedIndex: _selectedIndex,
    onDestinationSelected: (int index) {
      setState(() {
        _selectedIndex = index;
      });
    },
  );

  @override
  Widget build(BuildContext context) {
    return RouteAwarePageWrapper(
      onRouteAnimationCompleted:
          () => setState(() {
            isRouteAnimationCompleted = true;
          }),
      child: Scaffold(
        appBar:
            UiMode.m1(context)
                ? AppBar(
                  title: Text(destinations[_selectedIndex]['label']),
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
                )
                : null,
        body: Row(
          children: [
            if (UiMode.notM1(context)) buildAppNavigationBar(),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  Categories(
                    isRouteAnimationCompleted: isRouteAnimationCompleted,
                  ),
                  const Mine(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar:
            UiMode.m1(context) ? buildAppNavigationBar() : null,
      ),
    );
  }
}
