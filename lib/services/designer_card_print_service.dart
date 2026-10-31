import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/card_template.dart';
import '../repositories/persons_repository.dart';
import '../widgets/card_designer_preview.dart';
import 'pdf_generation_task.dart';

/// Packs cards at their declared millimetre size, reducing the requested grid
/// when necessary instead of stretching the design to fill each grid cell.
class DesignerCardPageLayout {
  DesignerCardPageLayout(
    CardTemplate template,
    int requestedColumns,
    int requestedRows,
  ) : width = template.width * PdfPageFormat.mm,
      height = template.height * PdfPageFormat.mm {
    final maxColumns =
        ((PdfPageFormat.a4.width - 2 * margin + gap) / (width + gap)).floor();
    final maxRows =
        ((PdfPageFormat.a4.height - 2 * margin + gap) / (height + gap)).floor();
    if (maxColumns < 1 || maxRows < 1) {
      throw ArgumentError('مقاس البطاقة أكبر من مساحة الطباعة على ورقة A4.');
    }
    columns = math.min(requestedColumns.clamp(1, 10), maxColumns);
    rows = math.min(requestedRows.clamp(1, 20), maxRows);
  }

  static const margin = 10 * PdfPageFormat.mm;
  static const gap = 4 * PdfPageFormat.mm;
  final double width;
  final double height;
  late final int columns;
  late final int rows;
  int get capacity => columns * rows;
}

class _RenderedCards {
  const _RenderedCards(this.fronts, this.backs, this.layout);
  final List<Uint8List> fronts;
  final List<Uint8List>? backs;
  final DesignerCardPageLayout layout;
}

Future<void> _renderedCardsEntry(List<Object?> message) async {
  final reporter = PdfGenerationReporter(message[0] as SendPort);
  final request = message[1] as _RenderedCards;
  try {
    final pdf = pw.Document();
    final layout = request.layout;
    pw.Widget card(Uint8List bytes) => pw.SizedBox(
      width: layout.width,
      height: layout.height,
      child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.fill),
    );
    void addPage(
      List<Uint8List> images,
      int start, {
      bool reverseColumns = false,
    }) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(DesignerCardPageLayout.margin),
          build: (_) => pw.Column(
            children: [
              for (var row = 0; row < layout.rows; row++) ...[
                if (row > 0) pw.SizedBox(height: DesignerCardPageLayout.gap),
                pw.Row(
                  children: [
                    for (var col = 0; col < layout.columns; col++) ...[
                      if (col > 0)
                        pw.SizedBox(width: DesignerCardPageLayout.gap),
                      _cardAt(
                        images,
                        start,
                        row,
                        reverseColumns ? layout.columns - 1 - col : col,
                        layout,
                        card,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }

    for (
      var start = 0;
      start < request.fronts.length;
      start += layout.capacity
    ) {
      addPage(request.fronts, start);
      if (request.backs != null) {
        addPage(request.backs!, start, reverseColumns: true);
      }
      reporter.update(
        math.min(start + layout.capacity, request.fronts.length),
        request.fronts.length,
        'جاري تجهيز صفحات الطباعة بنفس مقاس التصميم...',
      );
    }
    reporter.complete(await pdf.save());
  } catch (error, stack) {
    reporter.fail(error, stack);
  }
}

pw.Widget _cardAt(
  List<Uint8List> images,
  int start,
  int row,
  int column,
  DesignerCardPageLayout layout,
  pw.Widget Function(Uint8List) build,
) {
  final index = start + row * layout.columns + column;
  return index < images.length
      ? build(images[index])
      : pw.SizedBox(width: layout.width, height: layout.height);
}

class DesignerCardPrintService {
  static const printDpi = 600.0;

  /// Uses the actual Flutter designer widget and its inherited font and text
  /// scale. Increasing raster resolution never changes logical layout.
  static Future<Uint8List> renderCard({
    required BuildContext context,
    required CardTemplate template,
    required PersonListDTO person,
    double logicalWidth = CardTemplate.fontReferenceWidth,
    double dpi = printDpi,
  }) async {
    final decodedImages = <String, Uint8List>{};
    final background = template.backgroundImageBytes;
    if (background != null) decodedImages['background'] = background;
    for (var i = 0; i < template.imageElements.length; i++) {
      final element = template.imageElements[i];
      if (!element.visible) continue;
      final bytes = element.imageBytes;
      if (bytes != null) decodedImages['image:$i'] = bytes;
    }
    final images = <Uint8List>[
      ...decodedImages.values,
      if (person.photo != null &&
          template.fields.any(
            (f) => f.visible && f.fieldKey == CardFieldKeys.photo,
          ))
        person.photo!,
    ];
    for (final bytes in images) {
      if (!context.mounted) throw const PdfGenerationCancelledException();
      Object? imageError;
      await precacheImage(
        MemoryImage(bytes),
        context,
        onError: (error, stack) => imageError = error,
      );
      if (imageError != null) {
        throw StateError('تعذر تحميل صورة في تصميم البطاقة: $imageError');
      }
    }
    if (!context.mounted) throw const PdfGenerationCancelledException();
    final size = Size(
      logicalWidth,
      logicalWidth * template.height / template.width,
    );
    final pixelRatio = template.width / 25.4 * dpi / logicalWidth;
    final boundary = RenderRepaintBoundary();
    final pipeline = PipelineOwner();
    final owner = BuildOwner(focusManager: FocusManager());
    final view = RenderView(
      view: View.of(context),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(size),
        physicalConstraints: BoxConstraints.tight(size),
      ),
      child: boundary,
    );
    pipeline.rootNode = view;
    view.prepareInitialFrame();
    final element = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: InheritedTheme.captureAll(
        context,
        MediaQuery(
          data: MediaQuery.of(context),
          child: DefaultTextStyle(
            style: DefaultTextStyle.of(context).style,
            child: CardDesignerPreview(
              template: template,
              person: person,
              showTransparencyGrid: false,
              decodedImages: decodedImages,
            ),
          ),
        ),
      ),
    ).attachToRenderTree(owner);
    try {
      owner.buildScope(element);
      owner.finalizeTree();
      pipeline.flushLayout();
      pipeline.flushCompositingBits();
      pipeline.flushPaint();
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) throw StateError('تعذر تجهيز صورة البطاقة للطباعة.');
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } finally {
        image.dispose();
      }
    } finally {
      // Font loading may queue relayout callbacks during PNG encoding. Dispose
      // after the next frame's font callbacks, just like the visible widget tree.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        RenderObjectToWidgetAdapter<RenderBox>(
          container: boundary,
        ).attachToRenderTree(owner, element);
        owner.buildScope(element);
        owner.finalizeTree();
        pipeline.rootNode = null;
        view.child = null;
        boundary.dispose();
        view.dispose();
        pipeline.dispose();
        owner.focusManager.dispose();
      });
      WidgetsBinding.instance.scheduleFrame();
    }
  }

  static Future<PdfGenerationTask> startGeneration({
    required BuildContext context,
    required List<PersonListDTO> persons,
    required CardTemplate template,
    CardTemplate? backTemplate,
    required int cardsPerRow,
    required int cardsPerCol,
    double logicalWidth = CardTemplate.fontReferenceWidth,
    required bool Function() isCancelled,
    required void Function(int current, int total) onRendered,
  }) async {
    if (backTemplate != null &&
        (backTemplate.width != template.width ||
            backTemplate.height != template.height)) {
      throw ArgumentError('يجب أن يكون مقاس وجه البطاقة وظهرها متساويًا.');
    }
    final layout = DesignerCardPageLayout(template, cardsPerRow, cardsPerCol);
    final fronts = <Uint8List>[];
    final backs = backTemplate == null ? null : <Uint8List>[];
    for (var i = 0; i < persons.length; i++) {
      if (isCancelled() || !context.mounted) {
        throw const PdfGenerationCancelledException();
      }
      fronts.add(
        await renderCard(
          context: context,
          template: template,
          person: persons[i],
          logicalWidth: logicalWidth,
        ),
      );
      if (backTemplate != null) {
        if (isCancelled() || !context.mounted) {
          throw const PdfGenerationCancelledException();
        }
        backs!.add(
          await renderCard(
            context: context,
            template: backTemplate,
            person: persons[i],
            logicalWidth: logicalWidth,
          ),
        );
      }
      onRendered(i + 1, persons.length);
    }
    if (isCancelled()) throw const PdfGenerationCancelledException();
    return PdfGenerationTask.start(
      _renderedCardsEntry,
      _RenderedCards(fronts, backs, layout),
    );
  }
}
