import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haka_comic/network/proxy_config.dart';
import 'package:haka_comic/network/proxy_controller.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/views/settings/widgets/block.dart';

class ProxySettings extends StatefulWidget {
  ProxySettings({super.key, ProxyController? controller})
    : controller = controller ?? appProxyController;

  final ProxyController controller;

  @override
  State<ProxySettings> createState() => _ProxySettingsState();
}

class _ProxySettingsState extends State<ProxySettings> {
  late bool _enabled;
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final proxy = widget.controller.currentProxy;
    _enabled = proxy.mode == ProxyMode.socks5;
    _hostController = TextEditingController(text: proxy.host);
    _portController = TextEditingController(
      text: proxy.port == 0 ? '' : proxy.port.toString(),
    );
    _usernameController = TextEditingController(text: proxy.username);
    _passwordController = TextEditingController(text: proxy.password);
    _hostController.addListener(_onProxyFieldsChanged);
    _portController.addListener(_onProxyFieldsChanged);
    _usernameController.addListener(_onProxyFieldsChanged);
    _passwordController.addListener(_onProxyFieldsChanged);
  }

  @override
  void dispose() {
    _hostController.removeListener(_onProxyFieldsChanged);
    _portController.removeListener(_onProxyFieldsChanged);
    _usernameController.removeListener(_onProxyFieldsChanged);
    _passwordController.removeListener(_onProxyFieldsChanged);
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('代理设置')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          children: [
            Block(
              title: '网络代理',
              children: [
                _ProxyTextField(
                  controller: _hostController,
                  labelText: '主机',
                  hintText: '127.0.0.1',
                  enabled: !_enabled,
                ),
                _ProxyTextField(
                  controller: _portController,
                  labelText: '端口',
                  hintText: '1080',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  enabled: !_enabled,
                ),
                _ProxyTextField(
                  controller: _usernameController,
                  labelText: '用户名',
                  hintText: '可选',
                  enabled: !_enabled,
                ),
                _ProxyTextField(
                  controller: _passwordController,
                  labelText: '密码',
                  hintText: '可选',
                  obscureText: true,
                  enabled: !_enabled,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'SOCKS5 会让代理服务器解析目标域名',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),
            Block(
              children: [
                SwitchListTile(
                  value: _enabled,
                  onChanged: _canEnable ? _setEnabled : null,
                  secondary: const Icon(Icons.hub_outlined),
                  title: const Text('启用 SOCKS5 代理'),
                  subtitle: Text(_canEnable ? '关闭后所有请求直连' : '填写主机和端口后可启用'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool get _canEnable {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    return host.isNotEmpty && port != null && port > 0 && port <= 65535;
  }

  void _onProxyFieldsChanged() {
    final canEnable = _canEnable;
    final nextEnabled = _enabled && canEnable;
    if (nextEnabled != _enabled) {
      setState(() => _enabled = nextEnabled);
    } else {
      setState(() {});
    }

    _persistProxy(enabled: nextEnabled);
  }

  void _setEnabled(bool enabled) {
    if (enabled && !_canEnable) return;
    setState(() => _enabled = enabled);
    _persistProxy(enabled: enabled);
  }

  void _persistProxy({required bool enabled}) {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 0;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (enabled) {
      widget.controller.update(
        ProxyConfig.socks5(
          host: host,
          port: port,
          username: username,
          password: password,
        ),
      );
      return;
    }

    widget.controller.update(
      ProxyConfig.directWith(
        host: host,
        port: port,
        username: username,
        password: password,
      ),
    );
  }
}

class _ProxyTextField extends StatelessWidget {
  const _ProxyTextField({
    required this.controller,
    required this.labelText,
    this.hintText,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}
