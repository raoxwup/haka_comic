import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';

class AppIconSwitcher {
  static const classicIconName =
      'com.github.raoxwup.haka_comic.IconClassic';
  static const modernIconName = 'com.github.raoxwup.haka_comic.IconModern';

  static const _supportedIcons = {classicIconName, modernIconName};

  static Future<String> currentIconName() async {
    final iconName = await FlutterDynamicIconPlus.alternateIconName;
    if (iconName != null && _supportedIcons.contains(iconName)) {
      return iconName;
    }
    return classicIconName;
  }

  static Future<void> setIcon(String name) async {
    if (!_supportedIcons.contains(name)) {
      throw ArgumentError.value(name, 'name', 'Unsupported app icon');
    }
    if (!await FlutterDynamicIconPlus.supportsAlternateIcons) {
      throw UnsupportedError('Alternate app icons are not supported');
    }
    await FlutterDynamicIconPlus.setAlternateIconName(iconName: name);
  }
}
