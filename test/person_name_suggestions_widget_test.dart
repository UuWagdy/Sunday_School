import 'package:drift/drift.dart' as d;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/database/database.dart';
import 'package:petros_pols_flutter/database/database_provider.dart';
import 'package:petros_pols_flutter/screens/person_dialog.dart';
import 'package:petros_pols_flutter/services/auth_service.dart';

class NameTestAuth extends AuthService {
  @override
  Future<User?> build() async => null;
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'similar names preserve the draft and match the $brightness theme',
      (tester) async {
        final theme = ThemeData(
          brightness: brightness,
          colorSchemeSeed: Colors.indigo,
        );
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        await db
            .into(db.persons)
            .insert(
              PersonsCompanion.insert(
                personId: const d.Value(7),
                personName: const d.Value('أحمد إبراهيم بطرس'),
              ),
            );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              authServiceProvider.overrideWith(NameTestAuth.new),
            ],
            child: MaterialApp(
              theme: theme,
              home: const Scaffold(body: PersonDialog()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final name = find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.prefixIcon is Icon &&
              ((w.decoration?.prefixIcon as Icon).icon == Icons.person_outline),
        );
        expect(name, findsOneWidget);
        await tester.enterText(name, 'احمد ابراهيم');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
        expect(find.text('أحمد إبراهيم بطرس'), findsOneWidget);
        expect(
          find.textContaining('أسماء مشابهة مسجلة بالفعل'),
          findsOneWidget,
        );
        final controller = tester.widget<TextField>(name).controller!;
        expect(controller.text, 'احمد ابراهيم');
        final suggestions = find.textContaining('أسماء مشابهة مسجلة بالفعل');
        final card = tester.widget<Card>(
          find.ancestor(of: suggestions, matching: find.byType(Card)).first,
        );
        expect(card.color, theme.colorScheme.surfaceContainerHigh);
        final tile = tester.widget<ListTile>(
          find
              .ancestor(
                of: find.text('أحمد إبراهيم بطرس'),
                matching: find.byType(ListTile),
              )
              .first,
        );
        expect(tile.textColor, theme.colorScheme.onSurface);
        expect(
          tile.subtitleTextStyle?.color,
          theme.colorScheme.onSurfaceVariant,
        );
        expect(tile.iconColor, theme.colorScheme.primary);
        final contrast =
            (theme.colorScheme.onSurface.computeLuminance() + .05) /
            (card.color!.computeLuminance() + .05);
        if (brightness == Brightness.dark) expect(contrast, greaterThan(4.5));
        await tester.pumpWidget(const SizedBox());
        await db.close();
      },
    );
  }
}
