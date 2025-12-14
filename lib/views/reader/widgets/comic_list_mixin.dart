import 'package:flutter/widgets.dart';
import 'package:haka_comic/database/images_helper.dart';

mixin ComicListMixin<T extends StatefulWidget> on State<T> {
  /// 将图片尺寸信息插入数据库
  void insertImageSize(ImageSize imageSize) {
    ImagesHelper().insert(imageSize);
  }
}
