enum ProxyMode { direct, socks5 }

class Socks5ProxyConfig {
  const Socks5ProxyConfig({
    required this.host,
    required this.port,
    this.username = '',
    this.password = '',
  });

  final String host;
  final int port;
  final String username;
  final String password;

  bool get hasCredentials => username.isNotEmpty || password.isNotEmpty;
  bool get isValid => host.trim().isNotEmpty && port > 0 && port <= 65535;

  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'host': host,
      'port': port,
      'username': username,
      'password': password,
    };
  }

  factory Socks5ProxyConfig.fromPayload(Map<dynamic, dynamic> payload) {
    return Socks5ProxyConfig(
      host: payload['host'] as String? ?? '',
      port: (payload['port'] as num?)?.toInt() ?? 0,
      username: payload['username'] as String? ?? '',
      password: payload['password'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Socks5ProxyConfig &&
            runtimeType == other.runtimeType &&
            host == other.host &&
            port == other.port &&
            username == other.username &&
            password == other.password;
  }

  @override
  int get hashCode => Object.hash(host, port, username, password);
}

class ProxyConfig {
  const ProxyConfig._direct()
    : mode = ProxyMode.direct,
      host = '',
      port = 0,
      username = '',
      password = '';

  static const ProxyConfig direct = ProxyConfig._direct();

  const ProxyConfig.directWith({
    this.host = '',
    this.port = 0,
    this.username = '',
    this.password = '',
  }) : mode = ProxyMode.direct;

  const ProxyConfig.socks5({
    required this.host,
    required this.port,
    this.username = '',
    this.password = '',
  }) : mode = ProxyMode.socks5;

  final ProxyMode mode;
  final String host;
  final int port;
  final String username;
  final String password;

  Socks5ProxyConfig? get socks5 {
    if (mode != ProxyMode.socks5) return null;
    return Socks5ProxyConfig(
      host: host,
      port: port,
      username: username,
      password: password,
    );
  }

  bool get enabled => mode == ProxyMode.socks5 && socks5?.isValid == true;

  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'mode': mode.name,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
    };
  }

  factory ProxyConfig.fromPayload(Map<dynamic, dynamic> payload) {
    final modeName = payload['mode'] as String?;
    final socks5Config = Socks5ProxyConfig.fromPayload(payload);
    if (modeName != ProxyMode.socks5.name) {
      return ProxyConfig.directWith(
        host: socks5Config.host,
        port: socks5Config.port,
        username: socks5Config.username,
        password: socks5Config.password,
      );
    }

    if (!socks5Config.isValid) {
      return ProxyConfig.directWith(
        host: socks5Config.host,
        port: socks5Config.port,
        username: socks5Config.username,
        password: socks5Config.password,
      );
    }

    return ProxyConfig.socks5(
      host: socks5Config.host,
      port: socks5Config.port,
      username: socks5Config.username,
      password: socks5Config.password,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProxyConfig &&
            runtimeType == other.runtimeType &&
            mode == other.mode &&
            host == other.host &&
            port == other.port &&
            username == other.username &&
            password == other.password;
  }

  @override
  int get hashCode => Object.hash(mode, host, port, username, password);
}
