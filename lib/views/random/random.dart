import 'package:flutter/material.dart';
import 'package:haka_comic/mixin/auto_register_handler.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/router/aware_page_wrapper.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/ui.dart';
import 'package:haka_comic/views/comics/list_item.dart';
import 'package:haka_comic/widgets/base_page.dart';

class Random extends StatefulWidget {
  const Random({super.key});

  @override
  State<Random> createState() => _RandomState();
}

class _RandomState extends State<Random> with AutoRegisterHandlerMixin {
  final _handler = fetchRandomComics.useRequest(
    onSuccess: (data, _) {
      Log.info('fetch random comics success', data.toString());
    },
    onError: (e, _) {
      Log.error('fetch random comics error', e);
    },
  );

  @override
  List<AsyncRequestHandler> registerHandler() => [_handler];

  @override
  void initState() {
    super.initState();
    _handler.run();
  }

  @override
  Widget build(BuildContext context) {
    final width = context.width;
    final comics = _handler.data?.comics ?? [];
    return RouteAwarePageWrapper(
      builder: (context, completed) {
        return Scaffold(
          appBar: AppBar(title: const Text('随机本子')),
          body: BasePage(
            isLoading: _handler.isLoading,
            onRetry: _handler.refresh,
            error: _handler.error,
            child: CustomScrollView(
              slivers: [
                SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent:
                        UiMode.m1(context)
                            ? width
                            : UiMode.m2(context)
                            ? width / 2
                            : width / 3,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                    childAspectRatio: 2.5,
                  ),
                  itemBuilder: (context, index) {
                    return ListItem(doc: comics[index]);
                  },
                  itemCount: comics.length,
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _handler.isLoading ? null : () => _handler.refresh(),
            child: const Icon(Icons.refresh),
          ),
        );
      },
    );
  }
}
