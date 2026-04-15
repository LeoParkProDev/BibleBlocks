import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bible_blocks/app.dart';
import 'package:bible_blocks/providers/auth_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App renders without error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isGuestProvider.overrideWith(() => _AlwaysGuestNotifier()),
        ],
        child: const BibleBlocksApp(),
      ),
    );
    await tester.pumpAndSettle();
    // 내 성경 탭 라벨이 BottomNavigationBar에 존재
    expect(find.text('내 성경'), findsWidgets);
  });
}

class _AlwaysGuestNotifier extends IsGuestNotifier {
  @override
  Future<bool> build() async => true;
}
