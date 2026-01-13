import 'package:flutter_test/flutter_test.dart';

import 'package:synonyms_admin/main.dart';

void main() {
  testWidgets('App loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SynonymsAdminApp());

    expect(find.text('Synonyms Admin'), findsOneWidget);
    expect(find.text('Enter password to continue'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
