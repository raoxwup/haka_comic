import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/comics/list_item.dart';
import 'package:haka_comic/widgets/base_page.dart';

class Comics extends StatefulWidget {
  const Comics({super.key, this.t, this.c, this.a, this.ct, this.ca});

  // Tag
  final String? t;

  // 分类
  final String? c;

  // 作者
  final String? a;

  // 汉化组
  final String? ct;

  // 上传者
  final String? ca;

  @override
  State<Comics> createState() => _ComicsState();
}

class _ComicsState extends State<Comics> {
  ComicSortType sortType = ComicSortType.dd;
  int page = 1;

  final handler = fetchComics.useRequest(
    onSuccess: (data, _) {
      Log.info("Fetch comics success", data.toString());
    },
    onError: (e, _) {
      Log.error('Fetch comics failed', e);
    },
  );

  void _update() => setState(() {});

  @override
  void initState() {
    handler.run(ComicsPayload(c: widget.c, s: sortType, page: page));
    handler.addListener(_update);
    super.initState();
  }

  @override
  void dispose() {
    handler.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Doc>? comics = handler.data?.comics.docs;
    final int pages = handler.data?.comics.pages ?? 0;
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.c ?? widget.t ?? widget.a ?? widget.ct ?? widget.ca ?? '漫画',
        ),
      ),
      body: BasePage(
        isLoading: handler.isLoading,
        onRetry: handler.refresh,
        error: handler.error,
        child: CustomScrollView(
          slivers: [
            _buildSliverToBoxAdapter(pages),
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
                childAspectRatio: 2.8,
              ),
              itemBuilder: (context, index) {
                return ListItem(doc: comics![index]);
              },
              itemCount: comics?.length,
            ),
            _buildSliverToBoxAdapter(pages),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverToBoxAdapter(int pages) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
        child: Row(
          children: [
            FilledButton.tonal(
              onPressed:
                  page <= 1
                      ? null
                      : () {
                        setState(() {
                          page--;
                          handler.run(
                            ComicsPayload(c: widget.c, s: sortType, page: page),
                          );
                        });
                      },
              child: const Text('上一页'),
            ),
            const Spacer(),
            ActionChip(
              label: Text('页面: $page / $pages'),
              onPressed: () {
                selectPage(pages);
              },
              side: BorderSide.none,
            ),
            const Spacer(),
            FilledButton.tonal(
              onPressed:
                  page >= pages
                      ? null
                      : () {
                        setState(() {
                          page++;
                          handler.run(
                            ComicsPayload(c: widget.c, s: sortType, page: page),
                          );
                        });
                      },
              child: const Text('下一页'),
            ),
          ],
        ),
      ),
    );
  }

  void selectPage(int pages) async {
    String res = "";
    await showDialog(
      context: context,
      builder: (dialogContext) {
        var controller = TextEditingController();
        return SimpleDialog(
          title: const Text("页面跳转"),
          children: [
            const SizedBox(width: 300),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              child: TextField(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: "页码",
                  suffixText: "${"输入范围: "}1-${pages.toString()}",
                ),
                controller: controller,
                onSubmitted: (s) {
                  res = s;
                  context.pop();
                },
              ),
            ),
            Center(
              child: FilledButton(
                child: const Text("提交"),
                onPressed: () {
                  res = controller.text;
                  context.pop();
                },
              ),
            ),
          ],
        );
      },
    );
    if (int.tryParse(res) != null) {
      int i = int.parse(res);
      if (i > 0 && i <= pages) {
        setState(() {
          page = i;
          handler.run(ComicsPayload(c: widget.c, s: sortType, page: page));
        });
        return;
      }
    }
    if (res != "") {
      Future.delayed(const Duration(milliseconds: 500), () {
        showSnackBar('跳转页码不正确');
      });
    }
  }
}
