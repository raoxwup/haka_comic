import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:haka_comic/config/app_config.dart';

const host = 'https://picaapi.picacomic.com/';
const apiKey = 'C69BAF41DA5ABD1FFEDC6D2FEA56B';
const secretKey =
    "~d}\$Q7\$eIni=V)9\\RK/P.RM4;9[7|@/CA}b~OW!3?EV`:<>M7pddUBL5n|0/*Cn";
const nonce = "4ce7a7aa759b40f794d189a88b84aba8";

enum ImageQuality { low, medium, high, original }

Map<String, String> defaultHeaders = {
  "accept": "application/vnd.picacomic.com.v1+json",
  "User-Agent": "okhttp/3.8.1",
  "Content-Type": "application/json; charset=UTF-8",
  "api-key": apiKey,
  "app-build-version": "45",
  "app-channel": "1",
  "app-platform": "android",
  "app-uuid": "defaultUuid",
  "app-version": "2.2.1.3.3.4",
  "image-quality": ImageQuality.original.name,
  "nonce": nonce,
};

enum Method { get, post, delete, put }

String getMethod(Method method) {
  switch (method) {
    case Method.get:
      return 'GET';
    case Method.post:
      return 'POST';
    case Method.delete:
      return 'DELETE';
    case Method.put:
      return 'PUT';
  }
}

String getSignature(String url, String timestamp, String nonce, Method method) {
  final key =
      (url + timestamp + nonce + getMethod(method) + apiKey).toLowerCase();
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
  return {
    ...defaultHeaders,
    "time": timestamp,
    "signature": signature,
    "authorization": AppConfig().token,
  };
}
