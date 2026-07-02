import 'package:flutter/material.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/settings/blacklist.dart' as blacklist;
import 'package:go_router/go_router.dart';

final allCategories = blacklist.categories;

typedef FilterCallback =
    void Function({
      required ComicSortType type,
      required Set<String> categories,
    });

class FilterPanel extends StatefulWidget {
  const FilterPanel({
    super.key,
    required this.sortType,
    required this.categories,
    required this.onFilter,
  });

  final ComicSortType sortType;
  final Set<String> categories;
  final FilterCallback onFilter;

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late ComicSortType _sortType;
  late Set<String> _selectedCategories;

  @override
  void initState() {
    super.initState();
    _sortType = widget.sortType;
    _selectedCategories = Set.of(widget.categories);
  }

  bool get _hasChanges =>
      _sortType != widget.sortType ||
      !_sameCategories(_selectedCategories, widget.categories);

  void _setSortType(ComicSortType type) {
    if (_sortType == type) return;
    setState(() => _sortType = type);
  }

  void _toggleCategory(String category, bool selected) {
    setState(() {
      if (selected) {
        _selectedCategories.add(category);
      } else {
        _selectedCategories.remove(category);
      }
    });
  }

  void _clearCategories() {
    if (_selectedCategories.isEmpty) return;
    setState(_selectedCategories.clear);
  }

  void _apply() {
    widget.onFilter(type: _sortType, categories: Set.of(_selectedCategories));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final height = context.height;

    return AlertDialog(
      insetPadding: const EdgeInsets.all(20),
      title: const Text('筛选'),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 520, maxHeight: height * 0.66),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FilterSummary(
                sortTitle: _sortType.title,
                selectedCount: _selectedCategories.length,
              ),
              const SizedBox(height: 22),
              const _SectionHeader(icon: Icons.sort_rounded, title: '排序方式'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final type in ComicSortType.values)
                    _SortChip(
                      type: type,
                      selected: _sortType == type,
                      onSelected: () => _setSortType(type),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionHeader(
                icon: Icons.category_outlined,
                title: '限定分类',
                trailing: TextButton.icon(
                  onPressed: _selectedCategories.isEmpty
                      ? null
                      : _clearCategories,
                  icon: const Icon(Icons.clear_all_rounded),
                  label: const Text('清空'),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('不限分类'),
                    selected: _selectedCategories.isEmpty,
                    onSelected: (_) => _clearCategories(),
                    showCheckmark: false,
                    avatar: Icon(
                      Icons.all_inclusive_rounded,
                      size: 18,
                      color: _selectedCategories.isEmpty
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                    selectedColor: colorScheme.primaryContainer,
                    backgroundColor: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.42),
                    labelStyle: context.textTheme.labelLarge?.copyWith(
                      color: _selectedCategories.isEmpty
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: _selectedCategories.isEmpty
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  for (final category in allCategories)
                    _CategoryChip(
                      label: category,
                      selected: _selectedCategories.contains(category),
                      onSelected: (selected) =>
                          _toggleCategory(category, selected),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('取消')),
        FilledButton(
          onPressed: _hasChanges ? _apply : null,
          child: const Text('应用'),
        ),
      ],
    );
  }
}

bool _sameCategories(Set<String> a, Set<String> b) {
  return a.length == b.length && a.containsAll(b);
}

class _FilterSummary extends StatelessWidget {
  const _FilterSummary({required this.sortTitle, required this.selectedCount});

  final String sortTitle;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final categoryText = selectedCount == 0 ? '不限分类' : '$selectedCount 个分类';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_alt_rounded,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$sortTitle · $categoryText',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.type,
    required this.selected,
    required this.onSelected,
  });

  final ComicSortType type;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return ChoiceChip(
      label: Text(type.title),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: colorScheme.primaryContainer,
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.42,
      ),
      labelStyle: context.textTheme.labelLarge?.copyWith(
        color: selected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      checkmarkColor: colorScheme.primary,
      selectedColor: colorScheme.primaryContainer.withValues(alpha: 0.72),
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.42,
      ),
      labelStyle: context.textTheme.labelLarge?.copyWith(
        color: selected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
    );
  }
}
