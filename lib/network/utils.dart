import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:haka_comic/config/app_config.dart';

const apiKey = 'C69BAF41DA5ABD1FFEDC6D2FEA56B';
const secretKey =
    "~d}\$Q7\$eIni=V)9\\RK/P.RM4;9[7|@/CA}b~OW!3?EV`:<>M7pddUBL5n|0/*Cn";
const nonce = "4ce7a7aa759b40f794d189a88b84aba8";

/// 图片质量
enum ImageQuality {
  low('低'),
  medium('中'),
  high('高'),
  original('原画');

  final String displayName;

  const ImageQuality(this.displayName);

  static ImageQuality fromName(String? name) {
    return ImageQuality.values.firstWhere(
      (quality) => quality.name == name,
      orElse: () => original,
    );
  }
}

enum Api {
  app('https://picaapi.picacomic.com/', '直连'),
  web('https://api.go2778.com/', '代理');

  final String host;
  final String alias;

  const Api(this.host, this.alias);

  static Api fromName(String? name) {
    return Api.values.firstWhere((api) => api.name == name, orElse: () => web);
  }

  static Api fromAlias(String? alias) {
    return Api.values.firstWhere(
      (api) => api.alias == alias,
      orElse: () => web,
    );
  }
}

Map<String, String> defaultHeaders = {
  "accept": "application/vnd.picacomic.com.v1+json",
  "User-Agent": "okhttp/3.8.1",
  "Content-Type": "application/json; charset=UTF-8",
  "api-key": apiKey,
  "app-build-version": "45",
  "app-platform": "android",
  "app-uuid": "defaultUuid",
  "app-version": "2.2.1.3.3.4",
  "nonce": nonce,
  "app-channel": '1',
};

enum Method {
  get('GET'),
  post('POST'),
  delete('DELETE'),
  put('PUT');

  final String value;

  const Method(this.value);
}

String getSignature(String url, String timestamp, String nonce, Method method) {
  final key = (url + timestamp + nonce + method.value + apiKey).toLowerCase();
  var hmac = Hmac(sha256, utf8.encode(secretKey));
  var digest = hmac.convert(utf8.encode(key));
  return digest.toString();
}

String getTimestamp() {
  return (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
}

Map<String, String> getHeaders(String url, Method method) {
  final timestamp = getTimestamp();
  final signature = getSignature(url, timestamp, nonce, method);
  final conf = AppConf();
  return {
    ...defaultHeaders,
    "time": timestamp,
    "signature": signature,
    "authorization": conf.token,
    "image-quality": conf.imageQuality.name,
  };
}
