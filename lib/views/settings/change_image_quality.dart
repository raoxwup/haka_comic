import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/utils.dart';
import 'package:haka_comic/views/settings/widgets/menu_list_tile.dart';

class ChangeImageQuality extends StatefulWidget {
  const ChangeImageQuality({super.key});

  @override
  State<ChangeImageQuality> createState() => _ChangeImageQualityState();
}

class _ChangeImageQualityState extends State<ChangeImageQuality> {
  ImageQuality _imageQuality = AppConf().imageQuality;

  @override
  Widget build(BuildContext context) {
    return MenuListTile.withValue(
      icon: Icons.image_outlined,
      title: '图片质量',
      value: getImageQualityDisplayName(_imageQuality),
      items:
          ImageQuality.values.map((imageQuality) {
            return PopupMenuItem(
              value: imageQuality,
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
      onSelected:
          (value) => setState(() {
            _imageQuality = value;
            AppConf().imageQuality = value;
          }),
    );
  }
}
