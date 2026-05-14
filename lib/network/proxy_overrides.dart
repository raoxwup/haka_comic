import 'dart:async';
import 'dart:io';

import 'package:haka_comic/network/proxy_config.dart';
import 'package:socks5_proxy/socks_client.dart' as socks5;

/// 全局 HttpOverrides，让所有 HttpClient（包括图片缓存、Dio 底层）
/// 都使用应用内手动代理配置。
///
/// 每个 Isolate 需单独调用 [install]；[updateProxy] 是 Isolate-local 的。
class ProxyHttpOverrides extends HttpOverrides {
  static ProxyConfig _proxyConfig = ProxyConfig.direct;

  /// 安装到当前 Isolate 的全局 HttpOverrides。
  static void install() {
    HttpOverrides.global = ProxyHttpOverrides();
  }

  /// 根据应用内设置更新当前 Isolate 的代理配置。
  static void updateProxy(ProxyConfig proxy) {
    _proxyConfig = proxy;
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (_) => 'DIRECT';
    client.connectionFactory = (uri, _, _) {
      final proxy = _proxyConfig;
      if (proxy.enabled) {
        return _startSocks5Connect(
          uri: uri,
          proxy: proxy.socks5!,
          context: context,
        );
      }

      return _startDirectConnect(uri, context);
    };
    return client;
  }

  Future<ConnectionTask<Socket>> _startSocks5Connect({
    required Uri uri,
    required Socks5ProxyConfig proxy,
    SecurityContext? context,
  }) async {
    final socketFuture = _connectViaSocks5(
      uri: uri,
      proxy: proxy,
      context: context,
    );

    return ConnectionTask.fromSocket<Socket>(socketFuture, () {
      unawaited(
        socketFuture.then((socket) => socket.destroy(), onError: (_) {}),
      );
    });
  }

  Future<Socket> _connectViaSocks5({
    required Uri uri,
    required Socks5ProxyConfig proxy,
    SecurityContext? context,
  }) async {
    final proxyHost = proxy.host.trim();
    final socksSocket = await socks5.SocksTCPClient.connect(
      [
        socks5.ProxySettings(
          await _resolveProxyHost(proxyHost),
          proxy.port,
          username: proxy.hasCredentials ? proxy.username : null,
          password: proxy.hasCredentials ? proxy.password : null,
        ),
      ],
      _destinationAddress(uri.host),
      _effectivePort(uri),
    );

    if (uri.isScheme('https')) {
      return socksSocket.secure(uri.host, context: context);
    }

    return socksSocket;
  }

  Future<ConnectionTask<Socket>> _startDirectConnect(
    Uri uri,
    SecurityContext? context,
  ) async {
    final port = _effectivePort(uri);
    if (uri.isScheme('https')) {
      final task = await SecureSocket.startConnect(
        uri.host,
        port,
        context: context,
      );
      return ConnectionTask.fromSocket<Socket>(task.socket, task.cancel);
    }

    return Socket.startConnect(uri.host, port);
  }

  int _effectivePort(Uri uri) {
    if (uri.hasPort) return uri.port;
    if (uri.isScheme('https')) return 443;
    return 80;
  }

  Future<InternetAddress> _resolveProxyHost(String host) async {
    final parsed = InternetAddress.tryParse(host);
    if (parsed != null) return parsed;

    final addresses = await InternetAddress.lookup(host);
    if (addresses.isEmpty) {
      throw SocketException('Failed to resolve SOCKS5 proxy host: $host');
    }
    return addresses.first;
  }

  InternetAddress _destinationAddress(String host) {
    final parsed = InternetAddress.tryParse(host);
    if (parsed != null) return parsed;

    return InternetAddress(host, type: InternetAddressType.unix);
  }
}
