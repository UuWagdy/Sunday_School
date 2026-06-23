import 'package:flutter/material.dart';

import '../models/card_template.dart';
import '../repositories/persons_repository.dart';

class CardDesignerPreview extends StatelessWidget {
  const CardDesignerPreview({
    super.key,
    required this.template,
    required this.person,
    this.editable = false,
    this.selectedElementId,
    this.selectedElementIds = const <String>{},
    this.onElementSelected,
    this.onElementDragStarted,
    this.onElementDragEnded,
    this.onElementMoved,
    this.onElementResized,
  });

  final CardTemplate template;
  final PersonListDTO? person;
  final bool editable;
  final String? selectedElementId;
  final Set<String> selectedElementIds;
  final ValueChanged<String>? onElementSelected;
  final ValueChanged<String>? onElementDragStarted;
  final ValueChanged<String>? onElementDragEnded;
  final void Function(String elementId, Offset normalizedDelta)? onElementMoved;
  final void Function(String elementId, Offset normalizedDelta)?
  onElementResized;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AspectRatio(
        aspectRatio: template.width / template.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth;
            final cardHeight = constraints.maxHeight;
            return Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: template.transparentBackground
                    ? Colors.transparent
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (template.transparentBackground) _buildTransparencyGrid(),
                  _buildBackground(),
                  if (person == null)
                    Center(
                      child: Text(
                        'اختر شخصًا لمعاينة الكارنيه',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    for (final layerId in template.normalizedLayerOrder)
                      _buildLayerElement(
                        layerId,
                        person!,
                        cardWidth,
                        cardHeight,
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLayerElement(
    String layerId,
    PersonListDTO person,
    double cardWidth,
    double cardHeight,
  ) {
    if (layerId == 'barcode') {
      if (!template.barcode.visible) return const SizedBox.shrink();
      return _buildBarcode(person, cardWidth, cardHeight);
    }
    final parts = layerId.split(':');
    if (parts.length != 2) return const SizedBox.shrink();
    final index = int.tryParse(parts[1]);
    if (index == null) return const SizedBox.shrink();
    if (parts.first == 'image' &&
        index >= 0 &&
        index < template.imageElements.length &&
        template.imageElements[index].visible) {
      return _buildImageElement(
        layerId,
        template.imageElements[index],
        cardWidth,
        cardHeight,
      );
    }
    if (parts.first == 'field' &&
        index >= 0 &&
        index < template.fields.length &&
        template.fields[index].visible) {
      return _buildField(
        layerId,
        template.fields[index],
        person,
        cardWidth,
        cardHeight,
      );
    }
    if (parts.first == 'fixed' &&
        index >= 0 &&
        index < template.fixedTexts.length &&
        template.fixedTexts[index].visible) {
      return _buildFixedText(
        layerId,
        template.fixedTexts[index],
        cardWidth,
        cardHeight,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBackground() {
    final bytes = template.backgroundImageBytes;
    if (bytes == null) return const SizedBox.shrink();
    final fit = switch (template.backgroundFit) {
      CardBackgroundFit.shrinkToFit => BoxFit.contain,
      CardBackgroundFit.zoomToFit => BoxFit.cover,
      CardBackgroundFit.actualSize => BoxFit.none,
    };
    return IgnorePointer(
      child: Opacity(
        opacity: template.backgroundOpacity.clamp(0, 1).toDouble(),
        child: Image.memory(
          bytes,
          fit: fit,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) => Container(
            alignment: Alignment.center,
            color: Colors.red.shade50,
            child: const Text('صورة الخلفية غير صالحة'),
          ),
        ),
      ),
    );
  }

  Widget _buildTransparencyGrid() {
    return CustomPaint(
      painter: _TransparencyGridPainter(),
      child: const SizedBox.expand(),
    );
  }

  Widget _buildImageElement(
    String elementId,
    CardImageElement image,
    double cardWidth,
    double cardHeight,
  ) {
    final rect = _rectFor(
      image.x,
      image.y,
      image.width,
      image.height,
      cardWidth,
      cardHeight,
    );
    final bytes = image.imageBytes;
    final fit = switch (image.fit) {
      CardBackgroundFit.shrinkToFit => BoxFit.contain,
      CardBackgroundFit.zoomToFit => BoxFit.cover,
      CardBackgroundFit.actualSize => BoxFit.none,
    };
    return _buildEditableElement(
      elementId: elementId,
      rect: rect,
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      child: bytes == null
          ? const SizedBox.shrink()
          : ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Opacity(
                opacity: image.opacity.clamp(0, 1).toDouble(),
                child: Image.memory(bytes, fit: fit),
              ),
            ),
    );
  }

  Widget _buildField(
    String elementId,
    CardDataFieldElement field,
    PersonListDTO person,
    double cardWidth,
    double cardHeight,
  ) {
    final rect = _rectFor(
      field.x,
      field.y,
      field.width,
      field.height,
      cardWidth,
      cardHeight,
    );
    if (field.fieldKey == CardFieldKeys.photo) {
      return _buildEditableElement(
        elementId: elementId,
        rect: rect,
        cardWidth: cardWidth,
        cardHeight: cardHeight,
        child: person.photo == null
            ? const SizedBox.shrink()
            : ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.memory(person.photo!, fit: BoxFit.cover),
              ),
      );
    }

    final value = CardFieldKeys.valueFor(person, field.fieldKey);
    final label = CardFieldKeys.arabicLabel(field.fieldKey);
    final text = field.shouldShowLabel(template.showLabels)
        ? '$label: $value'
        : value;
    return _buildEditableElement(
      elementId: elementId,
      rect: rect,
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      child: Text(
        text,
        textAlign: _flutterTextAlign(field.textAlign),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Color(field.color),
          fontSize: _scaledFontSize(field.fontSize, cardWidth),
          fontWeight: field.fieldKey == CardFieldKeys.name
              ? FontWeight.bold
              : FontWeight.w600,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _buildFixedText(
    String elementId,
    CardFixedTextElement fixedText,
    double cardWidth,
    double cardHeight,
  ) {
    final rect = _rectFor(
      fixedText.x,
      fixedText.y,
      fixedText.width,
      fixedText.height,
      cardWidth,
      cardHeight,
    );
    return _buildEditableElement(
      elementId: elementId,
      rect: rect,
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      child: Text(
        fixedText.text,
        textAlign: _flutterTextAlign(fixedText.textAlign),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Color(fixedText.color),
          fontSize: _scaledFontSize(fixedText.fontSize, cardWidth),
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
    );
  }

  Widget _buildBarcode(
    PersonListDTO person,
    double cardWidth,
    double cardHeight,
  ) {
    final barcode = template.barcode;
    final rect = _rectFor(
      barcode.x,
      barcode.y,
      barcode.width,
      barcode.height,
      cardWidth,
      cardHeight,
    );
    final hasWhiteBackground =
        barcode.backgroundMode == CardBarcodeBackgroundMode.white;
    return _buildEditableElement(
      elementId: 'barcode',
      rect: rect,
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: hasWhiteBackground ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: hasWhiteBackground
                ? Colors.grey.shade300
                : Colors.grey.shade500,
          ),
        ),
        child: Center(
          child: barcode.type == CardCodeType.qr
              ? Icon(
                  Icons.qr_code_2,
                  size: rect.shortestSide * 0.75,
                  color: Colors.black87,
                )
              : FittedBox(
                  fit: BoxFit.contain,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.view_week_outlined,
                        color: Colors.black87,
                      ),
                      Text(
                        person.id.toString(),
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildEditableElement({
    required String elementId,
    required Rect rect,
    required double cardWidth,
    required double cardHeight,
    required Widget child,
  }) {
    final isLocked = _isLocked(elementId);
    final isSelected =
        editable &&
        (selectedElementId == elementId ||
            selectedElementIds.contains(elementId));
    Widget content = child;
    if (editable) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          child,
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isLocked
                      ? const Color(0xFF9CA3AF)
                      : isSelected
                      ? const Color(0xFF1A237E)
                      : const Color(0x553B82F6),
                  width: isSelected ? 2 : 1,
                ),
              ),
            ),
          ),
          if (isLocked)
            const Positioned(
              left: 2,
              top: 2,
              child: Icon(Icons.lock, size: 14, color: Color(0xFF4B5563)),
            ),
          if (isSelected && !isLocked)
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  onElementResized?.call(
                    elementId,
                    Offset(
                      details.delta.dx / cardWidth,
                      details.delta.dy / cardHeight,
                    ),
                  );
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeDownRight,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A237E),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                      ),
                    ),
                    child: const Icon(
                      Icons.open_in_full,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Positioned.fromRect(
      rect: rect,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: editable && !isLocked
            ? () => onElementSelected?.call(elementId)
            : null,
        onPanStart: editable && !isLocked
            ? (_) {
                onElementSelected?.call(elementId);
                onElementDragStarted?.call(elementId);
              }
            : null,
        onPanUpdate: editable && !isLocked
            ? (details) {
                onElementMoved?.call(
                  elementId,
                  Offset(
                    details.delta.dx / cardWidth,
                    details.delta.dy / cardHeight,
                  ),
                );
              }
            : null,
        onPanEnd: editable && !isLocked
            ? (_) => onElementDragEnded?.call(elementId)
            : null,
        onPanCancel: editable && !isLocked
            ? () => onElementDragEnded?.call(elementId)
            : null,
        child: MouseRegion(
          cursor: editable
              ? isLocked
                    ? SystemMouseCursors.forbidden
                    : SystemMouseCursors.move
              : MouseCursor.defer,
          child: content,
        ),
      ),
    );
  }

  bool _isLocked(String elementId) {
    if (elementId == 'barcode') return template.barcode.locked;
    final parts = elementId.split(':');
    if (parts.length != 2) return false;
    final index = int.tryParse(parts[1]);
    if (index == null) return false;
    return switch (parts.first) {
      'field' =>
        index >= 0 && index < template.fields.length
            ? template.fields[index].locked
            : false,
      'image' =>
        index >= 0 && index < template.imageElements.length
            ? template.imageElements[index].locked
            : false,
      'fixed' =>
        index >= 0 && index < template.fixedTexts.length
            ? template.fixedTexts[index].locked
            : false,
      _ => false,
    };
  }

  TextAlign _flutterTextAlign(CardTextAlign align) {
    return switch (align) {
      CardTextAlign.right => TextAlign.right,
      CardTextAlign.center => TextAlign.center,
      CardTextAlign.left => TextAlign.left,
    };
  }

  Rect _rectFor(
    double x,
    double y,
    double width,
    double height,
    double cardWidth,
    double cardHeight,
  ) {
    return Rect.fromLTWH(
      x * cardWidth,
      y * cardHeight,
      width * cardWidth,
      height * cardHeight,
    );
  }

  double _scaledFontSize(double fontSize, double cardWidth) {
    return fontSize * cardWidth / CardTemplate.fontReferenceWidth;
  }
}

class _TransparencyGridPainter extends CustomPainter {
  static const double cellSize = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()..color = const Color(0xFFFFFFFF);
    final darkPaint = Paint()..color = const Color(0xFFE5E7EB);
    canvas.drawRect(Offset.zero & size, lightPaint);

    for (double y = 0; y < size.height; y += cellSize) {
      for (double x = 0; x < size.width; x += cellSize) {
        final drawDark =
            ((x / cellSize).floor() + (y / cellSize).floor()).isEven;
        if (drawDark) {
          canvas.drawRect(Rect.fromLTWH(x, y, cellSize, cellSize), darkPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
