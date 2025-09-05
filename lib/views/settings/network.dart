import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/client.dart';
import 'package:haka_comic/network/utils.dart';
import 'package:haka_comic/utils/extension.dart';

class Network extends StatefulWidget {
  const Network({super.key});

  @override
  State<Network> createState() => _NetworkState();
}

class _NetworkState extends State<Network> {
  Api _api = AppConf().api;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('网络设置')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Text('API选择', style: context.textTheme.titleMedium),
          const SizedBox(height: 12),
          RadioGroup(
            onChanged: (value) {
              setState(() => _api = Api.fromValue(value!));
              AppConf().api = _api;
              Client.setBaseUrl(_api == Api.app ? host : webHost);
            },
            groupValue: _api.value,
            child: Column(
              children:
                  Api.values
                      .map(
                        (e) => ListTile(
                          title: Text(e.name),
                          leading: Radio<String>(value: e.value),
                          onTap: () => setState(() => _api = e),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
