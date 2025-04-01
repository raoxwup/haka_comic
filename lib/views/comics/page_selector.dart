import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/utils/common.dart';

class PageSelector extends StatelessWidget {
  const PageSelector({
    super.key,
    required this.currentPage,
    required this.pages,
    required this.onPageChange,
    this.isSliver,
  });

  final int currentPage;

  final int pages;

  final ValueChanged<int> onPageChange;

  final bool? isSliver;

  @override
  Widget build(BuildContext context) {
    final Widget child = Row(
      children: [
        FilledButton.tonal(
          onPressed:
              currentPage <= 1 ? null : () => onPageChange(currentPage - 1),
          child: const Text('上一页'),
        ),
        const Spacer(),
        ActionChip(
          label: Text('页面: $currentPage / $pages'),
          onPressed: () {
            showPageSelector(context, pages, onPageChange);
          },
          side: BorderSide.none,
        ),
        const Spacer(),
        FilledButton.tonal(
          onPressed:
              currentPage >= pages ? null : () => onPageChange(currentPage + 1),
          child: const Text('下一页'),
        ),
      ],
    );

    return isSliver ?? true
        ? SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            child: child,
          ),
        )
        : child;
  }

  void showPageSelector(
    BuildContext context,
    int pages,
    Function(int page) onSubmit,
  ) async {
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
        onSubmit(i);
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
