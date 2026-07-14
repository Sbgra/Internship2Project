import 'package:flutter_test/flutter_test.dart';
import 'package:internship2project/app.dart';

void main() {
  testWidgets('App widget mounts correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
  });
}
