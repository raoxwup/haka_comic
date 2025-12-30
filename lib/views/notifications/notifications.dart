import 'package:flutter/material.dart';
import 'package:haka_comic/mixin/pagination.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart' hide UseRequest1Extensions;
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/widgets/error_page.dart';
import 'package:haka_comic/widgets/ui_avatar.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications>
    with RequestMixin, PaginationMixin {
  int _page = 1;
  late final _handler = fetchNotifications.useRequest(
    defaultParams: _page,
    onSuccess: (data, _) {
      Log.info('Fetch notifications success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch notifications error', e);
    },
    reducer: (prev, current) {
      if (prev == null) return current;
      return current.copyWith.notifications(
        docs: [...prev.notifications.docs, ...current.notifications.docs],
      );
    },
  );

  @override
  Future<void> loadMore() async {
    final pages = _handler.state.data?.notifications.pages ?? 1;
    if (_page >= pages) return;
    await _handler.run(++_page);
  }

  void _refresh() {
    _handler.mutate(NotificationsResponse.empty);
    _page = 1;
    _handler.run(_page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通知')),
      body: switch (_handler.state) {
        RequestState(:final data) when data != null => SafeArea(
          child: ListView.builder(
            controller: scrollController,
            itemBuilder: (context, index) {
              if (index == data.notifications.docs.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: _handler.state.loading
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
              final item = data.notifications.docs[index];
              final key = ValueKey(item.uid);
              return Container(
                key: key,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  spacing: 8,
                  children: [
                    UiAvatar(size: 48, source: item.sender.avatar),
                    Expanded(
                      child: Column(
                        mainAxisSize: .min,
                        crossAxisAlignment: .start,
                        spacing: 5,
                        children: [
                          Text(
                            item.content,
                            style: context.textTheme.labelLarge,
                          ),
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
            itemCount: data.notifications.docs.length + 1,
          ),
        ),
        Error(:final error) => ErrorPage(
          errorMessage: error.toString(),
          onRetry: _refresh,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  @override
  List<RequestHandler> registerHandler() => [_handler];
}
