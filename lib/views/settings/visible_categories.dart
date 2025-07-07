import 'package:flutter/material.dart';
import 'package:haka_comic/config/app_config.dart';

/// 所有分类
List<String> categories = [
  "排行榜",
  "留言板",
  "最近更新",
  "随机本子",
  "大家都在看",
  "大濕推薦",
  "那年今天",
  "官方都在看",
  "嗶咔漢化",
  "全彩",
  "長篇",
  "同人",
  "短篇",
  "圓神領域",
  "碧藍幻想",
  "CG雜圖",
  "英語 ENG",
  "生肉",
  "純愛",
  "百合花園",
  "後宮閃光",
  "扶他樂園",
  "耽美花園",
  "偽娘哲學",
  "單行本",
  "姐姐系",
  "妹妹系",
  "性轉換",
  "SM",
  "足の恋",
  "人妻",
  "NTR",
  "強暴",
  "非人類",
  "艦隊收藏",
  "Love Live",
  "SAO 刀劍神域",
  "Fate",
  "東方",
  "WEBTOON",
  "禁書目錄",
  "歐美",
  "Cosplay",
  "重口地帶",
];

class VisibleCategories extends StatefulWidget {
  const VisibleCategories({super.key});

  @override
  State<VisibleCategories> createState() => _VisibleCategoriesState();
}

class _VisibleCategoriesState extends State<VisibleCategories> {
  List<String> selectedCategories = List.from(
    AppConf().visibleCategories.isEmpty
        ? categories
        : AppConf().visibleCategories,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('显示的分类')),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final item = categories[index];
          return SwitchListTile(
            title: Text(item),
            value: selectedCategories.contains(item),
            onChanged: (value) {
              setState(() {
                if (value) {
                  selectedCategories.add(item);
                  AppConf().visibleCategories = selectedCategories;
                } else {
                  selectedCategories.remove(item);
                  AppConf().visibleCategories = selectedCategories;
                }
              });
            },
          );
        },
      ),
    );
  }
}
