import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/utils/extension.dart';

class ComicBlockScale extends StatefulWidget {
  const ComicBlockScale({super.key});

  @override
  State<ComicBlockScale> createState() => _ComicBlockScaleState();
}

class _ComicBlockScaleState extends State<ComicBlockScale> {
  double _scale = AppConf().scale;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('简洁漫画块大小'),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: context.colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.grid_3x3_outlined, size: 22),
      ),
      subtitle: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Slider(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            value: _scale,
            max: 2.0,
            min: 0.5,
            divisions: 15,
            label: _scale.toString(),
            onChanged: (double value) {
              setState(() {
                _scale = value;
                AppConf().scale = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
