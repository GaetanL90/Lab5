import 'package:flutter_test/flutter_test.dart';
import 'package:offline_posts_manager/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App shows posts manager title', (WidgetTester tester) async {
    await tester.pumpWidget(const OfflinePostsApp());
    await tester.pump();
    expect(find.text('Offline Posts'), findsAtLeastNWidgets(1));
  });
}
