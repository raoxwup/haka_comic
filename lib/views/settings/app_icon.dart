import 'package:flutter/material.dart';
import 'package:haka_comic/utils/app_icon.dart';
import 'package:haka_comic/utils/common.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/settings/widgets/menu_list_tile.dart';

class AppIcon extends StatefulWidget {
  const AppIcon({super.key});

  @override
  State<AppIcon> createState() => _AppIconState();
}

class _AppIconState extends State<AppIcon> {
  String _icon = AppIconSwitcher.classicIconName;

  static const _titles = {
    AppIconSwitcher.classicIconName: '经典',
    AppIconSwitcher.modernIconName: '现代',
  };
  static const _options = [
    _AppIconOption(
      name: AppIconSwitcher.classicIconName,
      title: '经典',
      asset: 'assets/icons/android/icon.png',
    ),
    _AppIconOption(
      name: AppIconSwitcher.modernIconName,
      title: '现代',
      asset: 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_modern.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (isAndroid) {
      AppIconSwitcher.currentIconName().then((value) {
        if (mounted) {
          setState(() => _icon = value);
        }
      });
    }
  }

  Future<void> _select(String name) async {
    if (name == _icon) return;
    await AppIconSwitcher.setIcon(name);
    if (mounted) {
      setState(() => _icon = name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MenuListTile.withAction(
      icon: Icons.apps_outlined,
      title: '应用图标',
      value: _titles[_icon] ?? _titles[AppIconSwitcher.classicIconName],
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
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final option in _options)
                        _AppIconChoice(
                          title: option.title,
                          asset: option.asset,
                          selected: option.name == _icon,
                          onTap: () async {
                            Navigator.of(sheetContext).pop();
                            await _select(option.name);
                          },
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

class _AppIconOption {
  const _AppIconOption({
    required this.name,
    required this.title,
    required this.asset,
  });

  final String name;
  final String title;
  final String asset;
}

class _AppIconChoice extends StatelessWidget {
  const _AppIconChoice({
    required this.title,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(28);

    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 132,
            height: 146,
            padding: const EdgeInsets.fromLTRB(14, 17, 14, 15),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerLowest,
              borderRadius: radius,
              border: Border.all(
                color: selected
                    ? context.colorScheme.primary
                    : context.colorScheme.outlineVariant,
                width: selected ? 3 : 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: Image.asset(
                    asset,
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
                Text(
                  title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
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
