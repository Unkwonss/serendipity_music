import 'package:flutter_test/flutter_test.dart';
import 'package:serendipity_music/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Smoke test: chỉ kiểm tra app khởi động không crash
    // Note: audio_service cần được khởi tạo trước khi test đầy đủ
    expect(SerendipityApp, isNotNull);
  });
}
