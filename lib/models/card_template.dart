import 'dart:convert';
import 'dart:typed_data';

import '../repositories/persons_repository.dart';

enum CardBackgroundFit {
  shrinkToFit('shrinkToFit', 'احتواء داخل البطاقة'),
  zoomToFit('zoomToFit', 'ملء البطاقة'),
  actualSize('actualSize', 'الحجم الأصلي');

  const CardBackgroundFit(this.value, this.arabicLabel);

  final String value;
  final String arabicLabel;

  static CardBackgroundFit fromValue(Object? value) {
    return CardBackgroundFit.values.firstWhere(
      (fit) => fit.value == value,
      orElse: () => CardBackgroundFit.shrinkToFit,
    );
  }
}

enum CardLabelMode {
  inherit('inherit', 'حسب الإعداد العام'),
  show('show', 'إظهار العنوان'),
  hide('hide', 'إخفاء العنوان');

  const CardLabelMode(this.value, this.arabicLabel);

  final String value;
  final String arabicLabel;

  static CardLabelMode fromValue(Object? value) {
    return CardLabelMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => CardLabelMode.inherit,
    );
  }
}

enum CardCodeType {
  barcode('barcode', 'باركود شريطي'),
  qr('qr', 'كود مربع');

  const CardCodeType(this.value, this.arabicLabel);

  final String value;
  final String arabicLabel;

  static CardCodeType fromValue(Object? value) {
    return CardCodeType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CardCodeType.barcode,
    );
  }
}

enum CardBarcodeBackgroundMode {
  white('white', 'خلفية بيضاء'),
  transparent('transparent', 'بدون خلفية');

  const CardBarcodeBackgroundMode(this.value, this.arabicLabel);

  final String value;
  final String arabicLabel;

  static CardBarcodeBackgroundMode fromValue(Object? value) {
    return CardBarcodeBackgroundMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => CardBarcodeBackgroundMode.white,
    );
  }
}

enum CardTextAlign {
  right('right', 'يمين'),
  center('center', 'منتصف'),
  left('left', 'يسار');

  const CardTextAlign(this.value, this.arabicLabel);

  final String value;
  final String arabicLabel;

  static CardTextAlign fromValue(Object? value) {
    return CardTextAlign.values.firstWhere(
      (align) => align.value == value,
      orElse: () => CardTextAlign.right,
    );
  }
}

class CardTemplate {
  static const int currentVersion = 1;
  static const double defaultWidth = 86;
  static const double defaultHeight = 54;
  static const double fontReferenceWidth = 900;
  static const double minTextSize = 7;
  static const double maxTextSize = 512;

  final int version;
  final double width;
  final double height;
  final bool showLabels;
  final String? backgroundImageBase64;
  final CardBackgroundFit backgroundFit;
  final double backgroundOpacity;
  final bool transparentBackground;
  final List<CardDataFieldElement> fields;
  final List<CardFixedTextElement> fixedTexts;
  final List<CardImageElement> imageElements;
  final CardBarcodeElement barcode;
  final List<String> layerOrder;

  const CardTemplate({
    this.version = currentVersion,
    this.width = defaultWidth,
    this.height = defaultHeight,
    this.showLabels = true,
    this.backgroundImageBase64,
    this.backgroundFit = CardBackgroundFit.shrinkToFit,
    this.backgroundOpacity = 1,
    this.transparentBackground = false,
    required this.fields,
    this.fixedTexts = const [],
    this.imageElements = const [],
    this.barcode = const CardBarcodeElement(),
    this.layerOrder = const [],
  });

  factory CardTemplate.defaults() {
    return const CardTemplate(
      fields: [
        CardDataFieldElement(
          fieldKey: CardFieldKeys.name,
          x: 0.08,
          y: 0.12,
          width: 0.84,
          height: 0.12,
          fontSize: 18,
        ),
        CardDataFieldElement(
          fieldKey: CardFieldKeys.code,
          x: 0.08,
          y: 0.28,
          width: 0.38,
          height: 0.09,
        ),
        CardDataFieldElement(
          fieldKey: CardFieldKeys.stage,
          x: 0.08,
          y: 0.40,
          width: 0.38,
          height: 0.09,
        ),
        CardDataFieldElement(
          fieldKey: CardFieldKeys.khoros,
          x: 0.08,
          y: 0.52,
          width: 0.38,
          height: 0.09,
        ),
        CardDataFieldElement(
          fieldKey: CardFieldKeys.area,
          x: 0.08,
          y: 0.64,
          width: 0.38,
          height: 0.09,
        ),
        CardDataFieldElement(
          fieldKey: CardFieldKeys.photo,
          x: 0.60,
          y: 0.28,
          width: 0.26,
          height: 0.36,
          visible: false,
          labelMode: CardLabelMode.hide,
        ),
        CardDataFieldElement(
          fieldKey: CardFieldKeys.father,
          x: 0.08,
          y: 0.76,
          width: 0.84,
          height: 0.08,
          visible: false,
        ),
        CardDataFieldElement(
          fieldKey: CardFieldKeys.mobile,
          x: 0.08,
          y: 0.86,
          width: 0.40,
          height: 0.08,
          visible: false,
        ),
        CardDataFieldElement(
          fieldKey: CardFieldKeys.phone,
          x: 0.52,
          y: 0.86,
          width: 0.40,
          height: 0.08,
          visible: false,
        ),
        CardDataFieldElement(
          fieldKey: CardFieldKeys.street,
          x: 0.08,
          y: 0.76,
          width: 0.84,
          height: 0.08,
          visible: false,
        ),
        CardDataFieldElement(
          fieldKey: CardFieldKeys.rohot,
          x: 0.52,
          y: 0.76,
          width: 0.40,
          height: 0.08,
          visible: false,
        ),
      ],
    );
  }

  factory CardTemplate.fromJson(Map<String, dynamic> json) {
    final parsedFields =
        (json['fields'] as List?)
            ?.whereType<Map>()
            .map(
              (item) => CardDataFieldElement.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList() ??
        <CardDataFieldElement>[];

    final hasRohot = parsedFields.any((f) => f.fieldKey == CardFieldKeys.rohot);
    if (!hasRohot && parsedFields.isNotEmpty) {
      parsedFields.add(
        const CardDataFieldElement(
          fieldKey: CardFieldKeys.rohot,
          x: 0.52,
          y: 0.76,
          width: 0.40,
          height: 0.08,
          visible: false,
        ),
      );
    }
    final parsedFixedTexts =
        (json['fixedTexts'] as List?)
            ?.whereType<Map>()
            .map(
              (item) => CardFixedTextElement.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList() ??
        const <CardFixedTextElement>[];
    final parsedImages =
        (json['imageElements'] as List?)
            ?.whereType<Map>()
            .map(
              (item) =>
                  CardImageElement.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList() ??
        const <CardImageElement>[];

    return CardTemplate(
      version: _asInt(json['version'], currentVersion),
      width: _asDouble(json['width'], defaultWidth),
      height: _asDouble(json['height'], defaultHeight),
      showLabels: json['showLabels'] is bool
          ? json['showLabels'] as bool
          : true,
      backgroundImageBase64: json['backgroundImageBase64'] as String?,
      backgroundFit: CardBackgroundFit.fromValue(json['backgroundFit']),
      backgroundOpacity: _asDouble(
        json['backgroundOpacity'],
        1,
      ).clamp(0, 1).toDouble(),
      transparentBackground: json['transparentBackground'] is bool
          ? json['transparentBackground'] as bool
          : false,
      fields: parsedFields.isEmpty
          ? CardTemplate.defaults().fields
          : parsedFields,
      fixedTexts: parsedFixedTexts,
      imageElements: parsedImages,
      barcode: json['barcode'] is Map
          ? CardBarcodeElement.fromJson(
              Map<String, dynamic>.from(json['barcode'] as Map),
            )
          : const CardBarcodeElement(),
      layerOrder:
          (json['layerOrder'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const <String>[],
    );
  }

  factory CardTemplate.fromJsonString(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>)
        return CardTemplate.fromJson(decoded);
      if (decoded is Map)
        return CardTemplate.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {}
    return CardTemplate.defaults();
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'width': width,
      'height': height,
      'showLabels': showLabels,
      'backgroundImageBase64': backgroundImageBase64,
      'backgroundFit': backgroundFit.value,
      'backgroundOpacity': backgroundOpacity,
      'transparentBackground': transparentBackground,
      'fields': fields.map((field) => field.toJson()).toList(),
      'fixedTexts': fixedTexts.map((text) => text.toJson()).toList(),
      'imageElements': imageElements.map((image) => image.toJson()).toList(),
      'barcode': barcode.toJson(),
      'layerOrder': normalizedLayerOrder,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  Uint8List? get backgroundImageBytes {
    final value = backgroundImageBase64;
    if (value == null || value.isEmpty) return null;
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  CardTemplate copyWith({
    bool? showLabels,
    String? backgroundImageBase64,
    bool clearBackgroundImage = false,
    CardBackgroundFit? backgroundFit,
    double? backgroundOpacity,
    bool? transparentBackground,
    List<CardDataFieldElement>? fields,
    List<CardFixedTextElement>? fixedTexts,
    List<CardImageElement>? imageElements,
    CardBarcodeElement? barcode,
    List<String>? layerOrder,
  }) {
    return CardTemplate(
      version: version,
      width: width,
      height: height,
      showLabels: showLabels ?? this.showLabels,
      backgroundImageBase64: clearBackgroundImage
          ? null
          : backgroundImageBase64 ?? this.backgroundImageBase64,
      backgroundFit: backgroundFit ?? this.backgroundFit,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      transparentBackground:
          transparentBackground ?? this.transparentBackground,
      fields: fields ?? this.fields,
      fixedTexts: fixedTexts ?? this.fixedTexts,
      imageElements: imageElements ?? this.imageElements,
      barcode: barcode ?? this.barcode,
      layerOrder: layerOrder ?? this.layerOrder,
    );
  }

  List<String> get defaultLayerOrder {
    return [
      for (var i = 0; i < fields.length; i++) 'field:$i',
      for (var i = 0; i < imageElements.length; i++) 'image:$i',
      for (var i = 0; i < fixedTexts.length; i++) 'fixed:$i',
      'barcode',
    ];
  }

  List<String> get normalizedLayerOrder {
    final available = defaultLayerOrder.toSet();
    final ordered = <String>[
      for (final id in layerOrder)
        if (available.contains(id)) id,
    ];
    for (final id in defaultLayerOrder) {
      if (!ordered.contains(id)) ordered.add(id);
    }
    return ordered;
  }

  List<String> validate() {
    final errors = <String>[];
    if (width <= 0 || height <= 0) {
      errors.add('أبعاد البطاقة غير صحيحة');
    }
    if (backgroundImageBase64 != null && backgroundImageBytes == null) {
      errors.add('صورة الخلفية غير صالحة');
    }
    for (final field in fields) {
      errors.addAll(field.validate(CardFieldKeys.arabicLabel(field.fieldKey)));
    }
    for (final text in fixedTexts) {
      errors.addAll(text.validate());
    }
    for (final image in imageElements) {
      errors.addAll(image.validate());
    }
    errors.addAll(barcode.validate());
    return errors;
  }
}

class CardDataFieldElement {
  final String fieldKey;
  final bool visible;
  final CardLabelMode labelMode;
  final double x;
  final double y;
  final double width;
  final double height;
  final double fontSize;
  final int color;
  final CardTextAlign textAlign;
  final bool locked;

  const CardDataFieldElement({
    required this.fieldKey,
    this.visible = true,
    this.labelMode = CardLabelMode.inherit,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.fontSize = 11,
    this.color = 0xFF111111,
    this.textAlign = CardTextAlign.right,
    this.locked = false,
  });

  factory CardDataFieldElement.fromJson(Map<String, dynamic> json) {
    return CardDataFieldElement(
      fieldKey: json['fieldKey'] as String? ?? CardFieldKeys.name,
      visible: json['visible'] is bool ? json['visible'] as bool : true,
      labelMode: CardLabelMode.fromValue(json['labelMode']),
      x: _asDouble(json['x'], 0.05),
      y: _asDouble(json['y'], 0.05),
      width: _asDouble(json['width'], 0.40),
      height: _asDouble(json['height'], 0.10),
      fontSize: _asDouble(json['fontSize'], 11),
      color: _asInt(json['color'], 0xFF111111),
      textAlign: CardTextAlign.fromValue(json['textAlign']),
      locked: json['locked'] is bool ? json['locked'] as bool : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fieldKey': fieldKey,
      'visible': visible,
      'labelMode': labelMode.value,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'fontSize': fontSize,
      'color': color,
      'textAlign': textAlign.value,
      'locked': locked,
    };
  }

  CardDataFieldElement copyWith({
    bool? visible,
    CardLabelMode? labelMode,
    double? x,
    double? y,
    double? width,
    double? height,
    double? fontSize,
    int? color,
    CardTextAlign? textAlign,
    bool? locked,
  }) {
    return CardDataFieldElement(
      fieldKey: fieldKey,
      visible: visible ?? this.visible,
      labelMode: labelMode ?? this.labelMode,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      textAlign: textAlign ?? this.textAlign,
      locked: locked ?? this.locked,
    );
  }

  bool shouldShowLabel(bool globalShowLabels) {
    return switch (labelMode) {
      CardLabelMode.show => true,
      CardLabelMode.hide => false,
      CardLabelMode.inherit => globalShowLabels,
    };
  }

  List<String> validate(String label) {
    final errors = <String>[];
    if (!CardFieldKeys.all.contains(fieldKey)) {
      errors.add('حقل غير معروف: $fieldKey');
    }
    if (fontSize < CardTemplate.minTextSize ||
        fontSize > CardTemplate.maxTextSize) {
      errors.add('حجم خط $label خارج النطاق المسموح');
    }
    if (!_isNormalizedRect(x, y, width, height)) {
      errors.add('موضع $label خارج حدود البطاقة');
    }
    return errors;
  }
}

class CardFixedTextElement {
  final String text;
  final bool visible;
  final double x;
  final double y;
  final double width;
  final double height;
  final double fontSize;
  final int color;
  final CardTextAlign textAlign;
  final bool locked;

  const CardFixedTextElement({
    required this.text,
    this.visible = true,
    required this.x,
    required this.y,
    this.width = 0.5,
    this.height = 0.10,
    this.fontSize = 12,
    this.color = 0xFF111111,
    this.textAlign = CardTextAlign.right,
    this.locked = false,
  });

  factory CardFixedTextElement.fromJson(Map<String, dynamic> json) {
    return CardFixedTextElement(
      text: json['text'] as String? ?? '',
      visible: json['visible'] is bool ? json['visible'] as bool : true,
      x: _asDouble(json['x'], 0.10),
      y: _asDouble(json['y'], 0.10),
      width: _asDouble(json['width'], 0.50),
      height: _asDouble(json['height'], 0.10),
      fontSize: _asDouble(json['fontSize'], 12),
      color: _asInt(json['color'], 0xFF111111),
      textAlign: CardTextAlign.fromValue(json['textAlign']),
      locked: json['locked'] is bool ? json['locked'] as bool : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'visible': visible,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'fontSize': fontSize,
      'color': color,
      'textAlign': textAlign.value,
      'locked': locked,
    };
  }

  CardFixedTextElement copyWith({
    String? text,
    bool? visible,
    double? x,
    double? y,
    double? width,
    double? height,
    double? fontSize,
    int? color,
    CardTextAlign? textAlign,
    bool? locked,
  }) {
    return CardFixedTextElement(
      text: text ?? this.text,
      visible: visible ?? this.visible,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      textAlign: textAlign ?? this.textAlign,
      locked: locked ?? this.locked,
    );
  }

  List<String> validate() {
    final errors = <String>[];
    if (text.trim().isEmpty) {
      errors.add('يوجد نص ثابت فارغ');
    }
    if (fontSize < CardTemplate.minTextSize ||
        fontSize > CardTemplate.maxTextSize) {
      errors.add('حجم خط النص الثابت خارج النطاق المسموح');
    }
    if (!_isNormalizedRect(x, y, width, height)) {
      errors.add('موضع النص الثابت خارج حدود البطاقة');
    }
    return errors;
  }
}

class CardImageElement {
  final String imageBase64;
  final bool visible;
  final double opacity;
  final double x;
  final double y;
  final double width;
  final double height;
  final CardBackgroundFit fit;
  final bool locked;

  const CardImageElement({
    required this.imageBase64,
    this.visible = true,
    this.opacity = 1,
    required this.x,
    required this.y,
    this.width = 0.20,
    this.height = 0.20,
    this.fit = CardBackgroundFit.shrinkToFit,
    this.locked = false,
  });

  factory CardImageElement.fromJson(Map<String, dynamic> json) {
    return CardImageElement(
      imageBase64: json['imageBase64'] as String? ?? '',
      visible: json['visible'] is bool ? json['visible'] as bool : true,
      opacity: _asDouble(json['opacity'], 1).clamp(0, 1).toDouble(),
      x: _asDouble(json['x'], 0.10),
      y: _asDouble(json['y'], 0.10),
      width: _asDouble(json['width'], 0.20),
      height: _asDouble(json['height'], 0.20),
      fit: CardBackgroundFit.fromValue(json['fit']),
      locked: json['locked'] is bool ? json['locked'] as bool : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageBase64': imageBase64,
      'visible': visible,
      'opacity': opacity,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'fit': fit.value,
      'locked': locked,
    };
  }

  Uint8List? get imageBytes {
    if (imageBase64.isEmpty) return null;
    try {
      return base64Decode(imageBase64);
    } catch (_) {
      return null;
    }
  }

  CardImageElement copyWith({
    String? imageBase64,
    bool? visible,
    double? opacity,
    double? x,
    double? y,
    double? width,
    double? height,
    CardBackgroundFit? fit,
    bool? locked,
  }) {
    return CardImageElement(
      imageBase64: imageBase64 ?? this.imageBase64,
      visible: visible ?? this.visible,
      opacity: opacity ?? this.opacity,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      fit: fit ?? this.fit,
      locked: locked ?? this.locked,
    );
  }

  List<String> validate() {
    final errors = <String>[];
    if (imageBytes == null) {
      errors.add('يوجد عنصر صورة غير صالح');
    }
    if (!_isNormalizedRect(x, y, width, height)) {
      errors.add('موضع عنصر الصورة خارج حدود البطاقة');
    }
    return errors;
  }
}

class CardBarcodeElement {
  final bool visible;
  final CardCodeType type;
  final double x;
  final double y;
  final double width;
  final double height;
  final CardBarcodeBackgroundMode backgroundMode;
  final bool locked;

  const CardBarcodeElement({
    this.visible = true,
    this.type = CardCodeType.barcode,
    this.x = 0.25,
    this.y = 0.78,
    this.width = 0.50,
    this.height = 0.13,
    this.backgroundMode = CardBarcodeBackgroundMode.white,
    this.locked = false,
  });

  factory CardBarcodeElement.fromJson(Map<String, dynamic> json) {
    return CardBarcodeElement(
      visible: json['visible'] is bool ? json['visible'] as bool : true,
      type: CardCodeType.fromValue(json['type']),
      x: _asDouble(json['x'], 0.25),
      y: _asDouble(json['y'], 0.78),
      width: _asDouble(json['width'], 0.50),
      height: _asDouble(json['height'], 0.13),
      backgroundMode: CardBarcodeBackgroundMode.fromValue(
        json['backgroundMode'],
      ),
      locked: json['locked'] is bool ? json['locked'] as bool : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'visible': visible,
      'type': type.value,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'backgroundMode': backgroundMode.value,
      'locked': locked,
    };
  }

  CardBarcodeElement copyWith({
    bool? visible,
    CardCodeType? type,
    double? x,
    double? y,
    double? width,
    double? height,
    CardBarcodeBackgroundMode? backgroundMode,
    bool? locked,
  }) {
    return CardBarcodeElement(
      visible: visible ?? this.visible,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      backgroundMode: backgroundMode ?? this.backgroundMode,
      locked: locked ?? this.locked,
    );
  }

  List<String> validate() {
    final errors = <String>[];
    if (!_isNormalizedRect(x, y, width, height)) {
      errors.add('موضع الكود خارج حدود البطاقة');
    }
    if (type == CardCodeType.qr && (width < 0.14 || height < 0.14)) {
      errors.add('حجم QR صغير وقد يصعب مسحه');
    }
    if (type == CardCodeType.barcode && (width < 0.28 || height < 0.08)) {
      errors.add('حجم الباركود صغير وقد يصعب مسحه');
    }
    return errors;
  }
}

class CardFieldKeys {
  static const name = 'name';
  static const code = 'code';
  static const stage = 'stage';
  static const area = 'area';
  static const street = 'street';
  static const phone = 'phone';
  static const mobile = 'mobile';
  static const father = 'father';
  static const photo = 'photo';
  static const khoros = 'khoros';
  static const rohot = 'rohot';

  static const all = <String>[
    name,
    code,
    stage,
    area,
    street,
    phone,
    mobile,
    father,
    photo,
    khoros,
    rohot,
  ];

  static String arabicLabel(String key) {
    return switch (key) {
      name => 'الاسم',
      code => 'الكود',
      stage => 'المرحلة',
      area => 'المنطقة',
      street => 'العنوان',
      phone => 'تليفون',
      mobile => 'موبايل',
      father => 'أب الاعتراف',
      photo => 'صورة المخدوم',
      khoros => 'الخورس',
      rohot => 'الرهط',
      _ => key,
    };
  }

  static String valueFor(PersonListDTO person, String key) {
    return switch (key) {
      name => person.name,
      code => person.id.toString(),
      stage => person.stageName,
      area => person.areaName,
      street => person.streetName,
      phone => person.phone,
      mobile => person.mobile,
      father => person.fatherName,
      khoros => person.khorosName,
      rohot => person.rohot ?? '',
      photo => '',
      _ => '',
    };
  }
}

bool _isNormalizedRect(double x, double y, double width, double height) {
  return x >= 0 &&
      y >= 0 &&
      width > 0 &&
      height > 0 &&
      x + width <= 1.0001 &&
      y + height <= 1.0001;
}

double _asDouble(Object? value, double fallback) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int _asInt(Object? value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}
