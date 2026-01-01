import 'package:flutter/material.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/providers/block_provider.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/views/comics/common_tmi_list.dart';
import 'package:haka_comic/widgets/error_page.dart';

class Random extends StatefulWidget {
  const Random({super.key});

  @override
  State<Random> createState() => _RandomState();
}

class _RandomState extends State<Random> with RequestMixin {
  late final _handler = fetchRandomComics.useRequest(
    onSuccess: (data) {
      Log.info('fetch random comics success', data.toString());
    },
    onError: (e) {
      Log.error('fetch random comics error', e);
    },
  );

  @override
  List<RequestHandler> registerHandler() => [_handler];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('随机本子')),
      body: switch (_handler.state) {
        Success(:final data) => CommonTMIList(
          comics: context.filtered(data.comics),
        ),
        Error(:final error) => ErrorPage(
          errorMessage: error.toString(),
          onRetry: _handler.refresh,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: FloatingActionButton(
        onPressed: _handler.state.loading ? null : () => _handler.refresh(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
