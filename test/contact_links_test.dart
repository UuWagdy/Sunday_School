import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/utils/contact_links.dart';

void main() {
  test('normalizes common Egyptian phone formats for WhatsApp', () {
    expect(ContactLinks.normalizeEgyptPhone('01508445956'), '201508445956');
    expect(ContactLinks.normalizeEgyptPhone('201508445956'), '201508445956');
    expect(ContactLinks.normalizeEgyptPhone('+201508445956'), '201508445956');
    expect(ContactLinks.normalizeEgyptPhone('201508445956ا'), '201508445956');
  });

  test('renders visitation message variables with configured name parts', () {
    final message = ContactLinks.renderVisitationMessage(
      template:
          'ازيك يا {name} / {full_name} / {first_name} / {second_name} / {third_name} في خدمة {service} يوم {date} كود {code} رقم {phone}',
      personName: 'كيرلس فادي سمير',
      serviceName: 'إعدادي',
      date: '2026-06-26',
      nameParts: 2,
      personCode: 77,
      phone: '01508445956',
    );

    expect(
      message,
      'ازيك يا كيرلس فادي / كيرلس فادي سمير / كيرلس / فادي / سمير في خدمة إعدادي يوم 2026-06-26 كود 77 رقم 01508445956',
    );
  });
}
