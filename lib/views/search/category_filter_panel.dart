import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/cache.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';

/// 分类筛选 BottomSheet（带 Checkbox）
///
/// 弹出后异步加载所有分类，用户勾选后点"确定"回传选中的分类标题列表。
class CategoryFilterPanel extends StatefulWidget {
  const CategoryFilterPanel({
    super.key,
    required this.selectedCategories,
    required this.onConfirm,
    this.excludedCategories = const [],
  });

  /// 当前已选中的分类标题列表
  final List<String> selectedCategories;

  /// 用户点击"确定"后回调，返回选中的分类标题列表
  final ValueChanged<List<String>> onConfirm;

  /// 需要从列表中排除的分类（由路由参数传入，已在使用中）
  final List<String> excludedCategories;

  /// 显示 BottomSheet 的便捷方法
  static void show(
    BuildContext context, {
    required List<String> selectedCategories,
    required ValueChanged<List<String>> onConfirm,
    List<String> excludedCategories = const [],
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryFilterPanel(
        selectedCategories: selectedCategories,
        onConfirm: onConfirm,
        excludedCategories: excludedCategories,
      ),
    );
  }

  @override
  State<CategoryFilterPanel> createState() => _CategoryFilterPanelState();
}

class _CategoryFilterPanelState extends State<CategoryFilterPanel> {
  List<Category> _categories = [];
  bool _loading = true;
  String? _error;
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedCategories.toSet();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      // 先检查缓存
      const cacheKey = 'categories_list';
      final cached = Cache.get(cacheKey);
      CategoriesResponse response;
      if (cached != null) {
        response = CategoriesResponse.fromJson(cached);
      } else {
        response = await fetchCategories();
        // 深序列化：toJson() 浅序列化会保留 Category/ImageDetail 对象引用，
        // 导致从缓存读回时 fromJson 类型转换失败
        Cache.add(cacheKey, jsonDecode(jsonEncode(response)) as Map<String, dynamic>);
      }
      if (mounted) {
        // 排除黑名单中的分类和路由已传入的分类
        final blacklist = AppConf().blacklist;
        final excluded = widget.excludedCategories.toSet();
        final filtered = response.categories
            .where((cat) =>
                !blacklist.contains(cat.title) &&
                !excluded.contains(cat.title))
            .toList();
        setState(() {
          _categories = filtered;
          _loading = false;
        });
      }
    } catch (e) {
      Log.e('CategoryFilterPanel: load categories error', error: e);
      if (mounted) {
        setState(() {
          _error = '加载分类失败';
          _loading = false;
        });
      }
    }
  }

  void _toggle(String title) {
    setState(() {
      if (_selected.contains(title)) {
        _selected.remove(title);
      } else {
        _selected.add(title);
      }
    });
  }

  void _clearAll() {
    setState(() => _selected.clear());
  }

  void _confirm() {
    widget.onConfirm(_selected.toList());
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // 顶部拖拽指示条
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 标题栏
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '分类筛选',
                    style: context.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Visibility(
                    visible: _selected.isNotEmpty,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: TextButton(
                      onPressed: _clearAll,
                      child: const Text('清除'),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 内容区
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 12,
                            children: [
                              Text(_error!),
                              FilledButton.tonal(
                                onPressed: () {
                                  setState(() {
                                    _loading = true;
                                    _error = null;
                                  });
                                  _loadCategories();
                                },
                                child: const Text('重试'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final checked = _selected.contains(cat.title);
                            return CheckboxListTile(
                              value: checked,
                              onChanged: (_) => _toggle(cat.title),
                              title: Text(cat.title),
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          },
                        ),
            ),
            // 底部按钮
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _confirm,
                  child: Text('确定 (${_selected.length})'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
