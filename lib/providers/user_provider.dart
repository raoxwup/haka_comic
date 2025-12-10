import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/widgets/toast.dart';

final userProvider = FutureProvider<User>((ref) async {
  final response = await fetchUserProfile();
  if (!response.user.isPunched) {
    punchIn().then((_) {
      Toast.show(message: '打卡成功');
    });
  }
  return response.user;
});
