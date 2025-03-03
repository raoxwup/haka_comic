import 'package:haka_comic/network/client.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/log.dart';

Future<String> login(LoginPayload payload) async {
  try {
    final response = await Client.post("auth/sign-in", data: payload.toJson());
    return response;
  } catch (e) {
    Log.error("Sign in failed", e);
    rethrow;
  }
}
