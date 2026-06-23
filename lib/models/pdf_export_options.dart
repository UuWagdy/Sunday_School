import 'package:pdf/pdf.dart';

enum PdfPageOrientationOption { auto, portrait, landscape }

enum PdfGroupExportMode { singlePdfNewPages, separatePdfPerGroup }

class PdfExportOptions {
  const PdfExportOptions({
    this.orientation = PdfPageOrientationOption.auto,
    this.stretchToFit = true,
    this.groupMode = PdfGroupExportMode.singlePdfNewPages,
  });

  final PdfPageOrientationOption orientation;
  final bool stretchToFit;
  final PdfGroupExportMode groupMode;

  PdfExportOptions copyWith({
    PdfPageOrientationOption? orientation,
    bool? stretchToFit,
    PdfGroupExportMode? groupMode,
  }) {
    return PdfExportOptions(
      orientation: orientation ?? this.orientation,
      stretchToFit: stretchToFit ?? this.stretchToFit,
      groupMode: groupMode ?? this.groupMode,
    );
  }

  PdfPageFormat pageFormatForColumnCount(
    int columnCount, {
    int landscapeThreshold = 8,
  }) {
    switch (orientation) {
      case PdfPageOrientationOption.portrait:
        return PdfPageFormat.a4;
      case PdfPageOrientationOption.landscape:
        return PdfPageFormat.a4.landscape;
      case PdfPageOrientationOption.auto:
        return columnCount > landscapeThreshold
            ? PdfPageFormat.a4.landscape
            : PdfPageFormat.a4;
    }
  }

  double fittedFontSize(
    int columnCount, {
    required double baseSize,
    int comfortableColumnCount = 8,
    double minSize = 5,
  }) {
    if (!stretchToFit || columnCount <= comfortableColumnCount) {
      return baseSize;
    }
    final scale = comfortableColumnCount / columnCount;
    final fitted = baseSize * scale.clamp(0.65, 1.0);
    return fitted.clamp(minSize, baseSize).toDouble();
  }
}
