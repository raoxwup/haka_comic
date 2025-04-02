import 'package:flutter/material.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/base_page.dart';

class Mine extends StatefulWidget {
  const Mine({super.key});

  @override
  State<Mine> createState() => _MineState();
}

class _MineState extends State<Mine> {
  final _profileHandler = fetchUserProfile.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch user profile success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch user profile error', e);
    },
  );

  void _update() => setState(() {});

  @override
  void initState() {
    _profileHandler
      ..addListener(_update)
      ..run();
    super.initState();
  }

  @override
  void dispose() {
    _profileHandler
      ..removeListener(_update)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _profileHandler.data;
    return BasePage(
      isLoading: _profileHandler.isLoading,
      onRetry: _profileHandler.refresh,
      error: _profileHandler.error,
      child: Column(children: []),
    );
  }
}

// return DefaultTabController(
//       length: 3,
//       initialIndex: 0,
//       child: Column(
//         children: [
//           TabBar(tabs: [Tab(text: '我的收藏'), Tab(text: '浏览历史'), Tab(text: '评论')]),
//           Expanded(
//             child: TabBarView(
//               children: [const Favorites(), const History(), const Comments()],
//             ),
//           ),
//         ],
//       ),
//     );
