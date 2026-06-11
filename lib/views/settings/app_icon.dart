import 'package:flutter/material.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/settings/widgets/menu_list_tile.dart';
import 'package:dynamic_app_icon_flutter_plus/dynamic_app_icon_flutter_plus.dart';

class AppIcon extends StatefulWidget {
  const AppIcon({super.key});

  @override
  State<AppIcon> createState() => _AppIconState();
}

class _AppIconState extends State<AppIcon> {
  static const _modernIconName = 'IconModern';

  String? _icon;

  @override
  void initState() {
    super.initState();
    if (isAndroid) {
      DynamicAppIconFlutterPlus.getAlternateIconName().then((currentIcon) {
        if (mounted) {
          setState(() => _icon = currentIcon);
        }
      });
    }
  }

  Future<void> _select(String? name) async {
    if (name == _icon) return;
    await DynamicAppIconFlutterPlus.setAlternateIconName(name);
    if (mounted) {
      setState(() => _icon = name);
    }
  }

  void _selectFromSheet(BuildContext sheetContext, String? name) {
    Navigator.of(sheetContext).pop();
    _select(name).wait();
  }

  @override
  Widget build(BuildContext context) {
    return MenuListTile.withAction(
      icon: Icons.apps_outlined,
      title: '应用图标',
      value: _icon == null ? '经典' : '现代',
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          useSafeArea: true,
          constraints: const BoxConstraints(maxWidth: 400),
          isScrollControlled: true,
          builder: (sheetContext) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10.0),
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '选择应用图标',
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '选择后将应用新的应用图标',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 34),
                  Row(
                    spacing: 18,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _AppIconOption(
                        label: '经典',
                        asset: 'assets/icons/pc/linux_icon.png',
                        backgroundColor: const Color(0xFFd0ffad),
                        selected: _icon == null,
                        onTap: () => _selectFromSheet(sheetContext, null),
                      ),
                      _AppIconOption(
                        label: '现代',
                        asset: 'assets/images/foreground.png',
                        backgroundColor: const Color(0xFFfef9fa),
                        selected: _icon == _modernIconName,
                        onTap: () =>
                            _selectFromSheet(sheetContext, _modernIconName),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AppIconOption extends StatelessWidget {
  const _AppIconOption({
    required this.label,
    required this.asset,
    required this.backgroundColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String asset;
  final Color backgroundColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 112,
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            decoration: BoxDecoration(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.08)
                  : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.7),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        asset,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (selected)
                      Positioned(
                        right: -5,
                        bottom: -5,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.surfaceContainerLowest,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.check,
                            color: colorScheme.onPrimary,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
