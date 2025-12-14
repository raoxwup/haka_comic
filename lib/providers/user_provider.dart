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
    onSuccess: (data) {
      Log.info('Fetched user profile successfully', data.toString());
      if (!data.user.isPunched) {
        punchInHandler.run();
      }
    },
    onError: (error) {
      Log.error('Failed to fetch user profile ', error);
    },
  );

  late final punchInHandler = punchIn.useRequest(
    manual: true,
    onSuccess: (data) {
      Log.info('Punched in successfully', 'Punched in successfully');
      Toast.show(message: '打卡成功');
    },
    onError: (error) {
      Log.error('Failed to punch in ', error);
    },
  );

  UserProvider() {
    register(userHandler);
  }
}
