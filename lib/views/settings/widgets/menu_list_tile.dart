import 'package:material_ui/material_ui.dart';
import 'package:haka_comic/utils/extension.dart';

class MenuListTile<T> extends StatelessWidget {
  const MenuListTile.withValue({
    super.key,
    this.icon,
    required this.title,
    required this.value,
    required this.items,
    this.onSelected,
    this.subtitle,
  }) : onTap = null;

  const MenuListTile.withAction({
    super.key,
    this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.subtitle,
  }) : items = null,
       onSelected = null;

  final String title;
  final String? value;
  final IconData? icon;
  final List<PopupMenuEntry<T>>? items;
  final ValueChanged<T>? onSelected;
  final VoidCallback? onTap;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle,
      leading: icon == null
          ? null
          : Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, weight: 700),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5.0,
        children: [
          if (value != null)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.38,
              ),
              child: Tooltip(
                message: value!,
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap ?? () => _showMenu(context),
    );
  }

  void _showMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final value = await showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: items!,
    );

    if (value != null) {
      onSelected?.call(value);
    }
  }
}
