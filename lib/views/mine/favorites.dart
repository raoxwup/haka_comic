import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/comics/list_item.dart';
import 'package:haka_comic/views/comics/page_selector.dart';
import 'package:haka_comic/widgets/base_page.dart';

class Favorites extends StatefulWidget {
  const Favorites({super.key});

  @override
  State<Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  final _handler = fetchFavoriteComics.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch favorite comics success', data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch favorite comics error', e);
    },
  );

  int _page = 1;
  ComicSortType _sortType = ComicSortType.dd;

  @override
  void initState() {
    _handler.addListener(_update);
    super.initState();
  }

  @override
  void dispose() {
    _handler
      ..removeListener(_update)
      ..dispose();

    super.dispose();
  }

  void _update() => setState(() {});

  void _onPageChange(int page) {
    setState(() {
      _page = page;
    });
    _handler.run(UserFavoritePayload(page: page, sort: _sortType));
  }

  void _onSortChange(ComicSortType sortType) {
    setState(() {
      _page = 1;
      _sortType = sortType;
    });
    _handler.run(UserFavoritePayload(page: 1, sort: sortType));
  }

  @override
  Widget build(BuildContext context) {
    final width = context.width;
    final pages = _handler.data?.comics.pages ?? 1;
    final comics = _handler.data?.comics.docs ?? [];

    return RouteAwarePageWrapper(
      onRouteAnimationCompleted:
          () => _handler.run(UserFavoritePayload(page: _page, sort: _sortType)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('收藏漫画'),
          actions: [
            IconButton(
              tooltip: '刷新',
              onPressed: () => _onPageChange(1),
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: '排序',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return SortDialog(
                      sortType: _sortType,
                      onSortChanged: _onSortChange,
                    );
                  },
                );
              },
              icon: const Icon(Icons.sort),
            ),
          ],
        ),
        body: BasePage(
          isLoading: _handler.isLoading,
          onRetry: _handler.refresh,
          error: _handler.error,
          child: CustomScrollView(
            slivers: [
              PageSelector(
                pages: pages,
                onPageChange: _onPageChange,
                currentPage: _page,
              ),
              SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent:
                      UiMode.m1(context)
                          ? width
                          : UiMode.m2(context)
                          ? width / 2
                          : width / 3,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  childAspectRatio: 2.5,
                ),
                itemBuilder: (context, index) {
                  return ListItem(doc: comics[index]);
                },
                itemCount: comics.length,
              ),
              PageSelector(
                pages: pages,
                onPageChange: _onPageChange,
                currentPage: _page,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const kOptionHeight = 45.0;

class SortDialog extends StatefulWidget {
  const SortDialog({super.key, required this.sortType, this.onSortChanged});

  final ComicSortType sortType;
  final ValueChanged<ComicSortType>? onSortChanged;

  @override
  State<SortDialog> createState() => _SortDialogState();
}

class _SortDialogState extends State<SortDialog> {
  late ComicSortType _sortType = widget.sortType;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: const EdgeInsetsGeometry.all(20.0),
      title: const Text('排序'),
      children: [
        const Divider(),
        SizedBox(
          height: kOptionHeight * 2,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 150),
                top: _sortType == ComicSortType.dd ? 0 : kOptionHeight,
                height: kOptionHeight,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Positioned.fill(
                child: Column(
                  children: [
                    _buildSortOption(type: ComicSortType.dd, label: '新到旧'),
                    _buildSortOption(type: ComicSortType.da, label: '旧到新'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortOption({
    required ComicSortType type,
    required String label,
  }) {
    return InkWell(
      onTap: () async {
        setState(() => _sortType = type);
        widget.onSortChanged?.call(type);
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          context.pop();
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: kOptionHeight,
        alignment: Alignment.center,
        child: Text(
          label,
          style:
              _sortType == type
                  ? TextStyle(
                    color: context.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  )
                  : null,
        ),
      ),
    );
  }
}
