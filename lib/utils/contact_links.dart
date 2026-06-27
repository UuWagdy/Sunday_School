class ContactLinks {
  static const defaultVisitationMessageTemplate = '''
سلام ونعمة
ازيك يا {name}
افتقدناك الأسبوع ده في خدمة {service}
مجتش ليه؟
وعاوزين نشوفك المرة الجاية''';

  static String normalizeEgyptPhone(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return '';

    final hasLeadingPlus = value.startsWith('+');
    value = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (hasLeadingPlus) {
      value = '+${value.replaceAll('+', '')}';
    } else {
      value = value.replaceAll('+', '');
    }

    if (value.startsWith('+')) {
      value = value.substring(1);
    }

    while (value.startsWith('00')) {
      value = value.substring(2);
    }

    if (value.startsWith('0') && value.length >= 10) {
      value = '20${value.substring(1)}';
    } else if (value.startsWith('1') && value.length == 10) {
      value = '20$value';
    } else if (value.startsWith('20')) {
      value = value;
    }

    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static Uri? telUri(String raw) {
    final normalized = normalizeEgyptPhone(raw);
    if (normalized.isEmpty) return null;
    return Uri.parse('tel:+$normalized');
  }

  static Uri? whatsappUri(String raw, String message) {
    final normalized = normalizeEgyptPhone(raw);
    if (normalized.isEmpty) return null;
    return Uri.https('api.whatsapp.com', '/send', {
      'phone': normalized,
      'text': message,
    });
  }

  static String nameWithParts(String fullName, int parts) {
    final pieces = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((piece) => piece.isNotEmpty)
        .toList();
    if (pieces.isEmpty) return fullName.trim();
    if (parts <= 0 || parts >= pieces.length) return pieces.join(' ');
    return pieces.take(parts).join(' ');
  }

  static String renderVisitationMessage({
    required String template,
    required String personName,
    required String serviceName,
    required String date,
    required int nameParts,
    int? personCode,
    String? phone,
  }) {
    final name = nameWithParts(personName, nameParts);
    final pieces = personName
        .trim()
        .split(RegExp(r'\s+'))
        .where((piece) => piece.isNotEmpty)
        .toList();
    String namePart(int index) => index < pieces.length ? pieces[index] : '';

    return template
        .replaceAll('{name}', name)
        .replaceAll('{full_name}', personName)
        .replaceAll('{first_name}', namePart(0))
        .replaceAll('{second_name}', namePart(1))
        .replaceAll('{third_name}', namePart(2))
        .replaceAll('{service}', serviceName)
        .replaceAll('{date}', date)
        .replaceAll('{code}', personCode?.toString() ?? '')
        .replaceAll('{phone}', phone ?? '');
  }

  static bool looksLikePhoneField(String label) {
    final lower = label.toLowerCase();
    return lower.contains('phone') ||
        lower.contains('mobile') ||
        lower.contains('whats') ||
        label.contains('موبايل') ||
        label.contains('تليفون') ||
        label.contains('تلفون') ||
        label.contains('واتس') ||
        label.contains('رقم');
  }
}
