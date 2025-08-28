import 'package:flutter/material.dart';
import 'package:haka_comic/mixin/auto_register_handler.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/base_image.dart';
import 'package:haka_comic/widgets/base_page.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications>
    with AutoRegisterHandlerMixin {
  late final _handler = fetchNotifications.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch notifications success', data.toString());
      if (!mounted) return;
      setState(() {
        _notifications.addAll(data.notifications.docs);
        _hasMore = data.notifications.pages > _page;
      });
    },
    onError: (e, _) {
      Log.error('Fetch notifications error', e);
    },
  );

  int _page = 1;
  bool _hasMore = true;
  final List<NotificationDoc> _notifications = [];
  final ScrollController _scrollController = ScrollController();

  void _onScroll() {
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels >= position.maxScrollExtent * 0.9 &&
        _hasMore &&
        !_handler.isLoading) {
      _handler.run(++_page);
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _handler.run(_page);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _notifications.clear();
      _hasMore = true;
      _page = 1;
    });
    _handler.run(_page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通知')),
      body: BasePage(
        isLoading: false,
        onRetry: _refresh,
        error: _handler.error,
        child: ListView.builder(
          controller: _scrollController,
          itemBuilder: (context, index) {
            if (index == _notifications.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child:
                      _handler.isLoading
                          ? CircularProgressIndicator(
                            constraints: BoxConstraints.tight(
                              const Size(28, 28),
                            ),
                            strokeWidth: 3,
                          )
                          : Text('没有更多数据了', style: context.textTheme.bodySmall),
                ),
              );
            }
            final item = _notifications[index];
            final key = ValueKey(item.uid);
            return Container(
              key: key,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                spacing: 8,
                children: [
                  BaseImage(
                    url: item.sender.avatar!.url,
                    width: 48,
                    height: 48,
                    shape: const CircleBorder(),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 5,
                      children: [
                        Text(item.content, style: context.textTheme.labelLarge),
                        Text(
                          getFormattedTime(item.updatedAt),
                          style: context.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          itemCount: _notifications.length + 1,
        ),
      ),
    );
  }

  @override
  List<AsyncRequestHandler> registerHandler() => [_handler];
}
