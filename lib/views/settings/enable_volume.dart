import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/utils/extension.dart';

class EnableVolume extends StatefulWidget {
  const EnableVolume({super.key});

  @override
  State<EnableVolume> createState() => _EnableVolumeState();
}

class _EnableVolumeState extends State<EnableVolume> {
  bool _enable = AppConf().enableVolume;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('音量键翻页'),
      leading: CircleAvatar(
        radius: 17,
        backgroundColor: context.colorScheme.primary.withValues(alpha: .1),
        child: const Icon(Icons.volume_down_outlined, size: 22),
      ),
      trailing: Switch(
        value: _enable,
        onChanged: (value) {
          setState(() {
            _enable = value;
            AppConf().enableVolume = value;
          });
        },
      ),
    );
  }
}
