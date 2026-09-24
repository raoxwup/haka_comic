import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haka_comic/views/settings/block_list_page.dart';

void main() {
  testWidgets('block list page renders items as responsive cards', (
    tester,
  ) async {
    final items = ['标签一', '标签二'];
    final deleted = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: BlockListPage(
          items: items,
          addDialogTitle: '添加标签',
          inputHintText: '输入标签（2~20个字符）',
          lengthErrorMessage: '标签长度应为2~20个字符',
          onInsert: (_) async {},
          onDelete: deleted.add,
        ),
      ),
    );

    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
    expect(find.byType(Card), findsNWidgets(items.length));
    expect(find.text('标签一'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pump();

    expect(deleted, ['标签一']);
  });

  testWidgets('block list page trims input before inserting', (tester) async {
    final inserted = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: BlockListPage(
          items: const [],
          addDialogTitle: '添加关键词',
          inputHintText: '输入关键词（2~20个字符）',
          lengthErrorMessage: '关键词长度应为2~20个字符',
          onInsert: inserted.add,
          onDelete: (_) async {},
        ),
      ),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  关键词  ');
    await tester.tap(find.widgetWithText(TextButton, '添加'));
    await tester.pumpAndSettle();

    expect(inserted, ['关键词']);
  });
}
