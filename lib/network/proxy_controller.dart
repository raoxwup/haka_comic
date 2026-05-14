import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/network/proxy_config.dart';
import 'package:haka_comic/network/proxy_overrides.dart';

typedef LoadProxyConfig = ProxyConfig Function();
typedef SaveProxyConfig = void Function(ProxyConfig proxy);
typedef ApplyProxyConfig = void Function(ProxyConfig proxy);
typedef ProxyListener = void Function(ProxyConfig proxy);

class ProxyController {
  ProxyController({
    LoadProxyConfig? loadProxy,
    SaveProxyConfig? saveProxy,
    ApplyProxyConfig? applyProxy,
  }) : _loadProxy = loadProxy ?? (() => AppConf().proxyConfig),
       _saveProxy = saveProxy ?? ((proxy) => AppConf().proxyConfig = proxy),
       _applyProxy = applyProxy ?? applyProxyConfig;

  final LoadProxyConfig _loadProxy;
  final SaveProxyConfig _saveProxy;
  final ApplyProxyConfig _applyProxy;
  final Set<ProxyListener> _listeners = <ProxyListener>{};

  ProxyConfig? _currentProxy;

  ProxyConfig get currentProxy => _currentProxy ?? _loadProxy();

  void start() {
    _setProxy(_loadProxy(), force: true);
  }

  void update(ProxyConfig proxy) {
    if (proxy == _currentProxy) return;
    _saveProxy(proxy);
    _setProxy(proxy);
  }

  void addListener(ProxyListener listener, {bool emitCurrent = false}) {
    _listeners.add(listener);
    if (emitCurrent && _currentProxy != null) {
      listener(_currentProxy!);
    }
  }

  void removeListener(ProxyListener listener) {
    _listeners.remove(listener);
  }

  void dispose() {
    _listeners.clear();
  }

  static void applyProxyConfig(ProxyConfig proxy) {
    ProxyHttpOverrides.updateProxy(proxy);
  }

  void _setProxy(ProxyConfig proxy, {bool force = false}) {
    if (!force && proxy == _currentProxy) return;
    _currentProxy = proxy;
    _applyProxy(proxy);
    for (final listener in List<ProxyListener>.from(_listeners)) {
      listener(proxy);
    }
  }
}

final ProxyController appProxyController = ProxyController();
