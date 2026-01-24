import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';
import 'package:haka_comic/widgets/toast.dart';
import 'package:provider/provider.dart';

extension BuildContextListState on BuildContext {
  ListStateProvider get stateReader => read<ListStateProvider>();
  ListStateProvider get stateWatcher => watch<ListStateProvider>();
  T stateSelector<T>(T Function(ListStateProvider) s) =>
      select<ListStateProvider, T>(s);
}

class ListStateProvider extends ChangeNotifier {
  /// 是否按下了Ctrl
  bool _isCtrlPressed = false;
  bool get isCtrlPressed => _isCtrlPressed;
  set isCtrlPressed(bool value) {
    _isCtrlPressed = value;
    notifyListeners();
  }

  /// 列表ScrollPhysics
  ScrollPhysics _physics = const BouncingScrollPhysics();
  ScrollPhysics get physics => _physics;
  set physics(ScrollPhysics physics) {
    _physics = physics;
    notifyListeners();
  }

  /// 条漫模式宽度
  double _verticalListWidthRatio = AppConf().verticalListWidthRatio;
  double get verticalListWidthRatio => _verticalListWidthRatio;
  set verticalListWidthRatio(double width) {
    _verticalListWidthRatio = width;
    AppConf().verticalListWidthRatio = width;
    notifyListeners();
  }

  /// 锁定菜单
  bool _lockMenu = false;
  bool get lockMenu => _lockMenu;
  void toggleLockMenu() {
    _lockMenu = !_lockMenu;
    notifyListeners();
    Toast.show(message: _lockMenu ? '菜单已锁定' : '菜单已解锁');
  }

  /// 切换页码显隐
  bool _showPageNumbers = AppConf().showPageNumbers;
  bool get showPageNumbers => _showPageNumbers;
  void toggleShowPageNumbers() {
    _showPageNumbers = !_showPageNumbers;
    AppConf().showPageNumbers = _showPageNumbers;
    notifyListeners();
  }
}
