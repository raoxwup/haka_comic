import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/network/models.dart';

class SortTypeSelector extends StatefulWidget {
  const SortTypeSelector({
    super.key,
    required this.sortType,
    required this.onSortTypeChange,
  });

  final ComicSortType sortType;

  final ValueChanged<ComicSortType> onSortTypeChange;

  @override
  State<SortTypeSelector> createState() => _SortTypeSelectorState();
}

class _SortTypeSelectorState extends State<SortTypeSelector> {
  late ComicSortType _sortType;

  final List<Map<String, dynamic>> sorts = [
    {"label": '新到旧', "value": ComicSortType.dd},
    {"label": "旧到新", "value": ComicSortType.da},
    {"label": "最多喜欢", "value": ComicSortType.ld},
    {"label": "最多观看", "value": ComicSortType.vd},
  ];

  @override
  void initState() {
    super.initState();
    _sortType = widget.sortType;
  }

  void handleChange(ComicSortType type) {
    if (type == _sortType) return;
    setState(() {
      _sortType = type;
    });
    widget.onSortTypeChange(type);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('排序方式'),
      contentPadding: const EdgeInsets.all(20),
      content: SingleChildScrollView(
        child: RadioGroup<ComicSortType>(
          groupValue: _sortType,
          onChanged: (ComicSortType? value) {
            handleChange(value!);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: sorts
                .map(
                  (e) => ListTile(
                    title: Text(e['label']),
                    leading: Radio<ComicSortType>(value: e['value']),
                    onTap: () => handleChange(e['value']),
                  ),
                )
                .toList(),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => context.pop(), child: const Text('关闭')),
      ],
    );
  }
}
