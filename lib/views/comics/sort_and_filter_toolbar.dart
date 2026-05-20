import 'package:flutter/material.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/views/comics/sort_type_selector.dart';
import 'package:haka_comic/views/search/category_filter_panel.dart';

/// 排序 + 分类筛选按钮组
///
/// 共用组件，用于 Comics / SearchComics 等需要排序和分类筛选的页面。
/// 父组件持有状态，本组件只负责 UI 和弹窗交互。
///
/// 使用方式：`actions: [...SortAndFilterToolbar(...).buildButtons(context)]`
class SortAndFilterToolbar extends StatelessWidget {
  const SortAndFilterToolbar({
    super.key,
    required this.sortType,
    required this.selectedCategories,
    required this.onSortTypeChange,
    required this.onCategoriesChange,
    this.routeCategories = const [],
  });

  final ComicSortType sortType;
  final List<String> selectedCategories;
  final ValueChanged<ComicSortType> onSortTypeChange;
  final ValueChanged<List<String>> onCategoriesChange;

  /// 由路由参数传入的分类（已在使用中，需从筛选面板排除）
  final List<String> routeCategories;

  /// 返回按钮列表，可直接展开到 AppBar.actions 中
  List<Widget> buildButtons(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final count = selectedCategories.length;
    return [
      IconButton(
        tooltip: '分类筛选',
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          backgroundColor: colorScheme.primary,
          textColor: colorScheme.onPrimary,
          child: Icon(
            Icons.filter_list,
            color: count > 0 ? colorScheme.primary : null,
          ),
        ),
        onPressed: () {
          CategoryFilterPanel.show(
            context,
            selectedCategories: selectedCategories,
            onConfirm: onCategoriesChange,
            excludedCategories: routeCategories,
          );
        },
      ),
      IconButton(
        tooltip: '排序',
        icon: const Icon(Icons.sort),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => SortTypeSelector(
              sortType: sortType,
              onSortTypeChange: onSortTypeChange,
            ),
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: buildButtons(context),
  );
}
