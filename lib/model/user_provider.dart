import 'package:flutter/material.dart';
import 'package:haka_comic/network/http.dart';
import 'package:haka_comic/network/models.dart';
import 'package:haka_comic/utils/extension.dart';
import 'package:haka_comic/utils/log.dart';
import 'package:haka_comic/widgets/toast.dart';

class UserProvider with ChangeNotifier {
  late final _userProfileHandler = fetchUserProfile.useRequest(
    onSuccess: (data, _) {
      Log.info('Fetch user profile success', data.toString());
      user = data.user;
      if (!data.user.isPunched) {
        _punchInHandler.run();
      }
    },
    onError: (e, _) => Log.error('Fetch user profile error', e),
  );

  late final _punchInHandler = punchIn.useRequest(
    onSuccess: (_, __) {
      Log.info('Punch in success', '');
      Toast.show(message: '打卡成功');
    },
    onError: (e, _) => Log.error('Punch in error', e),
  );

  User? _user;

  User? get user => _user;

  set user(User? user) {
    _user = user;
    notifyListeners();
  }

  AsyncRequestHandler0<UserProfileResponse> get userProfileHandler =>
      _userProfileHandler;

  @override
  void dispose() {
    _userProfileHandler.dispose();
    _punchInHandler.dispose();
    super.dispose();
  }
}
