import 'package:flutter/material.dart';
import 'package:haka_comic/database/images_helper.dart';

class WebDAV extends StatefulWidget {
  const WebDAV({super.key});

  @override
  State<WebDAV> createState() => _WebDAVState();
}

class _WebDAVState extends State<WebDAV> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebDAV')),
      body: ListView(
        children: [
          FilledButton.tonal(
            onPressed: () async {
              final file = await ImagesHelper.backup();
              await ImagesHelper.restore(file);
            },
            child: const Text('备份images'),
          ),
        ],
      ),
    );
  }
}
