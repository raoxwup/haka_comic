import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/client.dart';
import 'package:haka_comic/network/utils.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/settings/widgets/menu_list_tile.dart';
import 'package:haka_comic/widgets/toast.dart';

class Network extends StatefulWidget {
  const Network({super.key});

  @override
  State<Network> createState() => _NetworkState();
}

class _NetworkState extends State<Network> {
  Api _api = AppConf().api;

  @override
  Widget build(BuildContext context) {
    return MenuListTile.withValue(
      icon: Icons.network_check_outlined,
      title: 'API切换',
      value: _api.value,
      items:
          Api.values.map((api) {
            return PopupMenuItem(
              value: api.value,
              child: ListTile(
                leading: Icon(
                  _api.value == api.value
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: context.colorScheme.primary,
                ),
                title: Text(api.name),
              ),
            );
          }).toList(),
      onSelected: (value) {
        if (value == _api.value) return;
        setState(() {
          final api = Api.fromValue(value);
          _api = api;
          AppConf().api = api;
          Client.setBaseUrl(api.host);
        });
        Toast.show(message: '建议重启应用以确保切换生效');
      },
    );
  }
}
