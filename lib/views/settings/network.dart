import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/client.dart';
import 'package:haka_comic/network/utils.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/settings/widgets/menu_list_tile.dart';

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
      value: _api.alias,
      items: Api.values.map((api) {
        return PopupMenuItem(
          value: api.alias,
          child: ListTile(
            leading: Icon(
              _api.alias == api.alias
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: context.colorScheme.primary,
            ),
            title: Text(api.alias),
          ),
        );
      }).toList(),
      onSelected: (value) {
        if (value == _api.alias) return;
        setState(() {
          final api = Api.fromAlias(value);
          _api = api;
          AppConf().api = api;
          Client.setBaseUrl(api.host);
        });
      },
    );
  }
}
