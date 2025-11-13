import 'package:flutter/material.dart';

class PageTurnToolbar extends StatefulWidget {
  const PageTurnToolbar({super.key});

  @override
  State<PageTurnToolbar> createState() => _PageTurnToolbarState();
}

class _PageTurnToolbarState extends State<PageTurnToolbar> {
  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      left: 0,
      right: 0,
      bottom: 50,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          width: 200,
          height: 50,
          color: Colors.blue,
          child: const Center(child: Text('横向居中')),
        ),
      ),
    );
  }
}
