import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

class PdfGenerationProgress {
  const PdfGenerationProgress({
    required this.current,
    required this.total,
    required this.message,
  });

  final int current;
  final int total;
  final String message;

  double get fraction => total == 0 ? 0 : current / total;
}

class PdfGenerationCancelledException implements Exception {
  const PdfGenerationCancelledException();
}

class PdfGenerationReporter {
  const PdfGenerationReporter(this._sendPort);

  final SendPort _sendPort;

  void update(int current, int total, String message) {
    _sendPort.send(['progress', current, total, message]);
  }

  void complete(Uint8List bytes) {
    _sendPort.send([
      'result',
      TransferableTypedData.fromList([bytes]),
    ]);
  }

  void fail(Object error, StackTrace stackTrace) {
    _sendPort.send(['error', error.toString(), stackTrace.toString()]);
  }
}

class PdfProgressMarker extends pw.StatelessWidget {
  PdfProgressMarker({required this.child, required this.onPaint});

  final pw.Widget child;
  final void Function() onPaint;
  bool _reported = false;

  @override
  pw.Widget build(pw.Context context) => child;

  @override
  void paint(pw.Context context) {
    super.paint(context);
    if (_reported) return;
    _reported = true;
    onPaint();
  }
}

class PdfGenerationTask {
  PdfGenerationTask._();

  final StreamController<PdfGenerationProgress> _progressController =
      StreamController<PdfGenerationProgress>();
  final Completer<Uint8List> _resultCompleter = Completer<Uint8List>();
  late final ReceivePort _receivePort;
  late final Isolate _isolate;
  bool _isCancelled = false;
  bool _isClosed = false;

  Stream<PdfGenerationProgress> get progress => _progressController.stream;
  Future<Uint8List> get result => _resultCompleter.future;

  static Future<PdfGenerationTask> start<T>(
    void Function(List<Object?>) entryPoint,
    T payload,
  ) async {
    final task = PdfGenerationTask._();
    task._receivePort = ReceivePort();
    task._receivePort.listen(task._handleMessage);
    task._isolate = await Isolate.spawn<List<Object?>>(entryPoint, [
      task._receivePort.sendPort,
      payload,
    ]);
    return task;
  }

  void cancel() {
    if (_isCancelled || _resultCompleter.isCompleted) return;
    _isCancelled = true;
    _isolate.kill(priority: Isolate.immediate);
    _resultCompleter.completeError(const PdfGenerationCancelledException());
    _close();
  }

  void _handleMessage(dynamic message) {
    if (_isCancelled || message is! List || message.isEmpty) return;

    switch (message.first) {
      case 'progress':
        _progressController.add(
          PdfGenerationProgress(
            current: message[1] as int,
            total: message[2] as int,
            message: message[3] as String,
          ),
        );
        return;
      case 'result':
        final data = message[1] as TransferableTypedData;
        _resultCompleter.complete(data.materialize().asUint8List());
        _close();
        return;
      case 'error':
        _resultCompleter.completeError(
          Exception(message[1] as String),
          StackTrace.fromString(message[2] as String),
        );
        _close();
        return;
    }
  }

  void _close() {
    if (_isClosed) return;
    _isClosed = true;
    _receivePort.close();
    _progressController.close();
  }
}
