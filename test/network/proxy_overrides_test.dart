import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:haka_comic/network/proxy_config.dart';
import 'package:haka_comic/network/proxy_overrides.dart';

void main() {
  tearDown(() {
    ProxyHttpOverrides.updateProxy(ProxyConfig.direct);
  });

  group('ProxyHttpOverrides', () {
    test('routes HTTP requests through the configured SOCKS5 proxy', () async {
      final server = await _FakeSocks5Server.start((session) async {
        await session.acceptNoAuth();

        final request = await session.readConnectRequest();
        expect(request.host, 'example.com');
        expect(request.port, 80);

        session.writeSuccess();
        final httpRequest = await session.readHttpHeaders();
        expect(httpRequest, contains('GET / HTTP/1.1'));
        expect(httpRequest, contains('host: example.com'));
        session.writeHttpResponse('ok');
      });
      addTearDown(server.close);

      ProxyHttpOverrides.updateProxy(
        ProxyConfig.socks5(
          host: InternetAddress.loopbackIPv4.address,
          port: server.port,
        ),
      );

      final client = ProxyHttpOverrides().createHttpClient(null);
      addTearDown(() => client.close(force: true));

      final request = await client.getUrl(Uri.parse('http://example.com/'));
      final response = await request.close();

      expect(await utf8.decodeStream(response), 'ok');
    });

    test('passes SOCKS5 username and password to the proxy', () async {
      final server = await _FakeSocks5Server.start((session) async {
        await session.acceptPasswordAuth(username: 'user', password: 'pass');

        final request = await session.readConnectRequest();
        expect(request.host, 'example.com');
        session.writeSuccess();
        await session.readHttpHeaders();
        session.writeHttpResponse('ok');
      });
      addTearDown(server.close);

      ProxyHttpOverrides.updateProxy(
        ProxyConfig.socks5(
          host: InternetAddress.loopbackIPv4.address,
          port: server.port,
          username: 'user',
          password: 'pass',
        ),
      );

      final client = ProxyHttpOverrides().createHttpClient(null);
      addTearDown(() => client.close(force: true));

      final request = await client.getUrl(Uri.parse('http://example.com/'));
      final response = await request.close();

      expect(await utf8.decodeStream(response), 'ok');
    });
  });
}

class _FakeSocks5Server {
  const _FakeSocks5Server._(this._server, this._done);

  final ServerSocket _server;
  final Future<void> _done;

  int get port => _server.port;

  static Future<_FakeSocks5Server> start(
    Future<void> Function(_SocksSession session) handler,
  ) async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final done = server.first.then((socket) async {
      final session = _SocksSession(socket);
      try {
        await handler(session);
      } finally {
        await session.close();
      }
    });
    return _FakeSocks5Server._(server, done);
  }

  Future<void> close() async {
    await _server.close();
    await _done;
  }
}

class _SocksSession {
  _SocksSession(this._socket) : _reader = _SocketReader(_socket);

  final Socket _socket;
  final _SocketReader _reader;

  Future<void> acceptNoAuth() async {
    expect(await _reader.read(2), [0x05, 0x01]);
    expect(await _reader.read(1), [0x00]);
    _socket.add([0x05, 0x00]);
  }

  Future<void> acceptPasswordAuth({
    required String username,
    required String password,
  }) async {
    expect(await _reader.read(2), [0x05, 0x02]);
    expect(await _reader.read(2), containsAll(<int>[0x00, 0x02]));
    _socket.add([0x05, 0x02]);

    expect(await _reader.read(1), [0x01]);
    final usernameLength = (await _reader.read(1)).single;
    expect(utf8.decode(await _reader.read(usernameLength)), username);
    final passwordLength = (await _reader.read(1)).single;
    expect(utf8.decode(await _reader.read(passwordLength)), password);
    _socket.add([0x01, 0x00]);
  }

  Future<_ConnectRequest> readConnectRequest() async {
    final header = await _reader.read(4);
    expect(header[0], 0x05);
    expect(header[1], 0x01);
    expect(header[2], 0x00);

    final addressType = header[3];
    late final String host;
    switch (addressType) {
      case 0x01:
        host = InternetAddress.fromRawAddress(
          Uint8List.fromList(await _reader.read(4)),
        ).address;
      case 0x03:
        final length = (await _reader.read(1)).single;
        host = utf8.decode(await _reader.read(length));
      case 0x04:
        host = InternetAddress.fromRawAddress(
          Uint8List.fromList(await _reader.read(16)),
        ).address;
      default:
        fail('Unsupported address type: $addressType');
    }

    final portBytes = await _reader.read(2);
    final port = (portBytes[0] << 8) | portBytes[1];
    return _ConnectRequest(host, port);
  }

  void writeSuccess() {
    _socket.add([0x05, 0x00, 0x00, 0x01, 0, 0, 0, 0, 0, 0]);
  }

  Future<String> readHttpHeaders() async {
    return utf8.decode(await _reader.readUntil('\r\n\r\n'.codeUnits));
  }

  void writeHttpResponse(String body) {
    final bytes = utf8.encode(body);
    _socket.add(
      utf8.encode(
        'HTTP/1.1 200 OK\r\n'
        'Content-Length: ${bytes.length}\r\n'
        'Connection: close\r\n'
        '\r\n',
      ),
    );
    _socket.add(bytes);
  }

  Future<void> close() async {
    await _reader.cancel();
    await _socket.close();
  }
}

class _ConnectRequest {
  const _ConnectRequest(this.host, this.port);

  final String host;
  final int port;
}

class _SocketReader {
  _SocketReader(Socket socket) {
    _subscription = socket.listen(
      (bytes) {
        _buffer.addAll(bytes);
        _wake();
      },
      onError: _completeWithError,
      onDone: () => _completeWithError(StateError('Socket closed')),
      cancelOnError: true,
    );
  }

  final Queue<int> _buffer = Queue<int>();
  Completer<void>? _waiter;
  Object? _error;
  late final StreamSubscription<List<int>> _subscription;

  Future<List<int>> read(int length) async {
    while (_buffer.length < length) {
      if (_error != null) {
        throw _error!;
      }
      _waiter ??= Completer<void>();
      await _waiter!.future.timeout(const Duration(seconds: 10));
    }

    return List<int>.generate(length, (_) => _buffer.removeFirst());
  }

  Future<List<int>> readUntil(List<int> marker) async {
    while (!_endsWithMarker(marker)) {
      if (_error != null) {
        throw _error!;
      }
      _waiter ??= Completer<void>();
      await _waiter!.future.timeout(const Duration(seconds: 10));
    }

    return List<int>.generate(_buffer.length, (_) => _buffer.removeFirst());
  }

  Future<void> cancel() => _subscription.cancel();

  bool _endsWithMarker(List<int> marker) {
    if (_buffer.length < marker.length) return false;
    final tail = _buffer.skip(_buffer.length - marker.length);
    var index = 0;
    for (final byte in tail) {
      if (byte != marker[index++]) return false;
    }
    return true;
  }

  void _completeWithError(Object error) {
    _error = error;
    _wake();
  }

  void _wake() {
    final waiter = _waiter;
    if (waiter == null || waiter.isCompleted) return;
    _waiter = null;
    waiter.complete();
  }
}
