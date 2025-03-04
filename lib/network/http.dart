import 'package:haka_comic/network/client.dart';
import 'package:haka_comic/network/models.dart';

Future<LoginResponse> login(LoginPayload payload) async {
  try {
    final response = await Client.post("auth/sign-in", data: payload.toJson());
    final data = BaseResponse<LoginResponse>.fromJson(
      response,
      (data) => LoginResponse.fromJson(data),
    );
    return data.data;
  } catch (e) {
    rethrow;
  }
}
