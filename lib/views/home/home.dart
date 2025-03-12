import 'package:flutter/material.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/categories/categories.dart';
import 'package:haka_comic/views/home/navigation.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

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
    return Scaffold(
      appBar:
          UiMode.m1(context)
              ? AppBar(title: Text(destinations[_selectedIndex]['label']))
              : null,
      body: Row(
        children: [
          if (UiMode.notM1(context)) buildAppNavigationBar(),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [Categories(), Text('Categories')],
            ),
          ),
        ],
      ),
      bottomNavigationBar: UiMode.m1(context) ? buildAppNavigationBar() : null,
    );
  }
}
