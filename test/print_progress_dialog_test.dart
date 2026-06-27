import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/widgets/print_progress_dialog.dart';

void main() {
  testWidgets('shows exact count, percentage, and cancel button', (
    tester,
  ) async {
    late BuildContext dialogContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            dialogContext = context;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );

    final controllerFuture = showPrintProgressDialog(dialogContext);
    await tester.pump();
    final controller = await controllerFuture;
    controller.update('جاري إنشاء ملف PDF...', current: 1, total: 599);
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('1 من 599'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('إلغاء'), findsOneWidget);

    await tester.tap(find.text('إلغاء'));
    await tester.pump();
    expect(find.text('جاري الإلغاء...'), findsWidgets);

    controller.close();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 350));
  });
}
