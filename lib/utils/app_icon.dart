import 'package:flutter/services.dart';

class AppIconChannel {
  static const MethodChannel _channel = MethodChannel('haka_comic/app_icon');

  static Future<String> getIcon() async {
    final name = await _channel.invokeMethod<String>('getIcon');
    return name ?? 'default';
  }

  static Future<void> setIcon(String name) async {
    await _channel.invokeMethod('setIcon', {'name': name});
  }
}
