import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/history_helper.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/base_image.dart';
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

  final HistoryHelper _helper = HistoryHelper();
  List<HistoryDoc> _comics = [];

  void _update() => setState(() {});

  void _getHistory() {
    final comics = _helper.query(1);
    setState(() {
      _comics = comics;
    });
  }

  @override
  void initState() {
    _profileHandler
      ..addListener(_update)
      ..run();

    _getHistory();

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
    final user = _profileHandler.data?.user;
    return BasePage(
      isLoading: _profileHandler.isLoading,
      onRetry: _profileHandler.refresh,
      error: _profileHandler.error,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 15),
            child: Row(
              spacing: 15,
              children: [
                BaseImage(
                  url: user?.avatar.url ?? '',
                  width: 64,
                  height: 64,
                  shape: const CircleBorder(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 5,
                    children: [
                      Text(
                        user?.name ?? '',
                        style: context.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'level: ${user?.level}  exp: ${user?.exp}',
                        style: context.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.slogan ?? '',
                        style: context.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                  label: const Text('编辑'),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('已下载'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/downloads'),
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('收藏漫画'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/favorites'),
          ),
          ListTile(
            leading: const Icon(Icons.comment),
            title: const Text('我的评论'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/comments'),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('浏览历史'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/history'),
          ),
          InkWell(
            onTap: () => context.push('/history'),
            child: Card.outlined(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('浏览历史'),
                    trailing: const Icon(Icons.chevron_right),
                    // onTap: () => context.push('/history'),
                  ),
                  SizedBox(
                    height: 140,
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final item = _comics[index];
                        return InkWell(
                          onTap: () => context.push('/details/${item.id}'),
                          child: SizedBox(
                            width: 100,
                            child: BaseImage(
                              url: item.thumb.url,
                              width: 100,
                              height: 130,
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => SizedBox(width: 5),
                      itemCount: _comics.length,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
