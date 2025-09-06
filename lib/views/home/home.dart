import 'package:flutter/material.dart';
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

  Widget _buildAppNavigationBar() => AppNavigationBar(
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
      builder: (context, isRouteAnimationCompleted) {
        return Scaffold(
          extendBodyBehindAppBar:
              destinations[_selectedIndex]['extendBodyBehindAppBar'],
          appBar:
              UiMode.m1(context)
                  ? destinations[_selectedIndex]['buildAppBar'](context)
                  : null,
          body: Row(
            children: [
              if (!UiMode.m1(context)) _buildAppNavigationBar(),
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
              UiMode.m1(context) ? _buildAppNavigationBar() : null,
        );
      },
    );
  }
}
