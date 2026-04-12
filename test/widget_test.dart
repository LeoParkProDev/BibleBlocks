import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bible_blocks/app.dart';

void main() {
  testWidgets('App renders without error', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: BibleBlocksApp()),
    );
    expect(find.text('내 성경'), findsWidgets);
  });
}
