import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:haka_comic/model/theme_provider.dart';
import 'package:provider/provider.dart';

final Map<String, Color?> colors = {
  'System': null,
  'Red': Colors.red,
  'Pink': Colors.pink,
  'Purple': Colors.purple,
  'Deep Purple': Colors.deepPurple,
  'Indigo': Colors.indigo,
  'Blue': Colors.blue,
  'Light Blue': Colors.lightBlue,
  'Cyan': Colors.cyan,
  'Teal': Colors.teal,
  'Green': Colors.green,
  'Light Green': Colors.lightGreen,
  'Lime': Colors.lime,
  'Yellow': Colors.yellow,
  'Amber': Colors.amber,
  'Orange': Colors.orange,
  'Deep Orange': Colors.deepOrange,
  'Brown': Colors.brown,
  'Grey': Colors.grey,
  'Blue Grey': Colors.blueGrey,
};

String getKeyFromColor(Color? targetColor) {
  for (var entry in colors.entries) {
    if (entry.value != null && entry.value == targetColor) {
      return entry.key;
    }
  }
  return 'System';
}

class ThemeColor extends StatefulWidget {
  const ThemeColor({super.key});

  @override
  State<ThemeColor> createState() => _ThemeColorState();
}

class _ThemeColorState extends State<ThemeColor> {
  @override
  Widget build(BuildContext context) {
    final primaryColor = context.select<ThemeProvider, Color?>(
      (values) => values.primaryColor,
    );
    final title = getKeyFromColor(primaryColor);
    return ListTile(
      title: const Text('主题颜色'),
      leading: const Icon(Icons.color_lens),
      trailing: Row(
        spacing: 5.0,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontSize: 12)),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          useSafeArea: true,
          constraints: const BoxConstraints(maxWidth: 400),
          isScrollControlled: true,
          builder: (BuildContext context) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 10,
                children: [
                  const Text(
                    '选择主题颜色',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: colors.length,
                      itemBuilder: (context, index) {
                        final key = colors.keys.elementAt(index);
                        final color = colors[key];
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 10,
                          children: [
                            const SizedBox(width: 75.0),
                            GestureDetector(
                              onTap: () {
                                context.read<ThemeProvider>().setPrimaryColor(
                                  color,
                                );
                                context.pop();
                              },
                              child: CircleAvatar(
                                backgroundColor: color,
                                radius: 25,
                                child:
                                    key == title
                                        ? const Icon(
                                          Icons.done,
                                          size: 30,
                                          color: Colors.white,
                                        )
                                        : null,
                              ),
                            ),
                            Text(key, style: const TextStyle(fontSize: 12)),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
