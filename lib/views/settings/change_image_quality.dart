import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/utils.dart';

class ChangeImageQuality extends StatefulWidget {
  const ChangeImageQuality({super.key});

  @override
  State<ChangeImageQuality> createState() => _ChangeImageQualityState();
}

class _ChangeImageQualityState extends State<ChangeImageQuality> {
  ImageQuality _imageQuality = AppConf().imageQuality;

  void _showImageQualityDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('修改图片质量'),
          children:
              ImageQuality.values.map((imageQuality) {
                return SimpleDialogOption(
                  onPressed: () {
                    setState(() {
                      _imageQuality = imageQuality;
                      AppConf().imageQuality = imageQuality;
                    });
                    context.pop();
                  },
                  child: ListTile(
                    leading: Icon(
                      _imageQuality == imageQuality
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(getImageQualityDisplayName(imageQuality)),
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.image),
      title: Text('图片质量'),
      trailing: Row(
        spacing: 5.0,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            getImageQualityDisplayName(_imageQuality),
            style: const TextStyle(fontSize: 12),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: _showImageQualityDialog,
    );
  }
}
