import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/models/card_template.dart';
import 'package:petros_pols_flutter/repositories/persons_repository.dart';
import 'package:petros_pols_flutter/widgets/card_designer_preview.dart';

void main() {
  testWidgets('card designer preview shows empty selected person state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: CardDesignerPreview(
                template: CardTemplate.defaults(),
                person: null,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('اختر شخصًا لمعاينة الكارنيه'), findsOneWidget);
  });

  testWidgets('card designer preview renders khoros field and fixed text', (tester) async {
    final template = CardTemplate.defaults().copyWith(
      fixedTexts: const [
        CardFixedTextElement(
          text: 'خدمة ابتدائي',
          x: 0.10,
          y: 0.02,
          width: 0.60,
          height: 0.10,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: CardDesignerPreview(
                template: template,
                person: PersonListDTO(
                  id: 12,
                  name: 'مينا جورج',
                  stageName: 'ابتدائي',
                  khorosName: 'خورس أ',
                  areaName: 'المنطقة الأولى',
                  phone: '',
                  mobile: '',
                  streetName: '',
                  fatherName: '',
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('خورس أ'), findsOneWidget);
    expect(find.text('خدمة ابتدائي'), findsOneWidget);
  });
}
