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
    _sortType = widget.sortType;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text('排序方式'),
      contentPadding: EdgeInsets.all(20),
      children:
          sorts
              .map(
                (e) => ListTile(
                  title: Text(e['label']),
                  leading: Radio<ComicSortType>(
                    value: e['value'],
                    groupValue: _sortType,
                    onChanged: (ComicSortType? value) {
                      setState(() {
                        _sortType = value!;
                      });
                      widget.onSortTypeChange(value!);
                      context.pop();
                    },
                  ),
                  onTap: () {
                    setState(() {
                      _sortType = e['value'];
                    });
                    widget.onSortTypeChange(e['value']);
                    context.pop();
                  },
                ),
              )
              .toList(),
    );
  }
}
