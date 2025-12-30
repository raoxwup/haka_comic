import 'package:flutter/widgets.dart';
import 'package:haka_comic/utils/extension.dart';

class TitleBox extends StatelessWidget {
  const TitleBox({
    super.key,
    required this.title,
    required this.builder,
    this.actions = const [],
  });

  final String title;
  final WidgetBuilder builder;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(title, style: context.textTheme.titleMedium),
            const Spacer(),
            ...actions,
          ],
        ),
        Builder(builder: builder),
      ],
    );
  }
}
