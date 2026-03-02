import 'package:flutter/material.dart';
import 'package:haka_comic/network/http.dart' hide register;
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/utils/request/request.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:provider/provider.dart';

extension BuildContextUserExt on BuildContext {
  UserProvider get userReader => read<UserProvider>();
  UserProvider get userWatcher => watch<UserProvider>();
  T userSelector<T>(T Function(UserProvider) s) => select<UserProvider, T>(s);
}

class UserProvider extends RequestProvider {
  late final userHandler = fetchUserProfile.useRequest(
    manual: true,
    onSuccess: (data) {
      Log.i('Fetched user profile successfully', data);
      if (!data.user.isPunched) {
        punchInHandler.run();
      }
    },
    onError: (error) {
      Log.e('Failed to fetch user profile ', error: error);
    },
  );

  late final punchInHandler = punchIn.useRequest(
    manual: true,
    onSuccess: (data) {
      Log.i('Punched in successfully', 'Punched in successfully');
      Toast.show(message: '打卡成功');
    },
    onError: (error) {
      Log.e('Failed to punch in ', error: error);
    },
  );

  UserProvider() {
    register(userHandler);
  }
}
