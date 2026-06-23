import 'package:flutter/material.dart';

class PrintProgressState {
  const PrintProgressState({
    required this.message,
    this.current,
    this.total,
    this.isCancelling = false,
    this.isComplete = false,
  });

  final String message;
  final int? current;
  final int? total;
  final bool isCancelling;
  final bool isComplete;

  double? get progress {
    if (current == null || total == null || total == 0) return null;
    if (isComplete) return 1;
    return (current! / total!).clamp(0, 0.99);
  }
}

class PrintProgressController {
  PrintProgressController._(this._context, this._state);

  final BuildContext _context;
  final ValueNotifier<PrintProgressState> _state;
  bool _isOpen = true;
  bool _isCancelled = false;
  VoidCallback? _cancelAction;

  bool get isCancelled => _isCancelled;

  void setCancelAction(VoidCallback action) {
    _cancelAction = action;
    if (_isCancelled) action();
  }

  void update(String message, {int? current, int? total}) {
    if (!_isOpen) return;
    _state.value = PrintProgressState(
      message: message,
      current: current,
      total: total,
      isCancelling: _isCancelled,
    );
  }

  Future<void> complete(String message, {required int total}) async {
    if (!_isOpen) return;
    _state.value = PrintProgressState(
      message: message,
      current: total,
      total: total,
      isComplete: true,
    );
    await WidgetsBinding.instance.endOfFrame;
  }

  void cancel() {
    if (!_isOpen || _isCancelled) return;
    _isCancelled = true;
    _state.value = PrintProgressState(
      message: 'جاري إلغاء الطباعة...',
      current: _state.value.current,
      total: _state.value.total,
      isCancelling: true,
    );
    _cancelAction?.call();
  }

  void close() {
    if (!_isOpen) return;
    _isOpen = false;
    Navigator.of(_context, rootNavigator: true).pop();
    Future<void>.delayed(const Duration(milliseconds: 300), _state.dispose);
  }
}

Future<PrintProgressController> showPrintProgressDialog(
  BuildContext context, {
  String initialMessage = 'جاري تجهيز الطباعة...',
}) async {
  final state = ValueNotifier(PrintProgressState(message: initialMessage));
  final controller = PrintProgressController._(context, state);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => PopScope(
      canPop: false,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          content: SizedBox(
            width: 360,
            child: ValueListenableBuilder<PrintProgressState>(
              valueListenable: state,
              builder: (context, value, child) {
                final progress = value.progress;
                final percentage = progress == null
                    ? null
                    : '${value.isComplete ? 100 : (progress * 100).floor()}%';
                final counter = value.current == null || value.total == null
                    ? null
                    : '${value.current} من ${value.total}';
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.print_outlined,
                      size: 42,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      value.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: progress),
                    if (percentage != null && counter != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            counter,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            percentage,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'يمكنك متابعة العمل بعد فتح نافذة الطابعة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: value.isCancelling ? null : controller.cancel,
                      icon: value.isCancelling
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cancel_outlined),
                      label: Text(
                        value.isCancelling ? 'جاري الإلغاء...' : 'إلغاء',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );

  await WidgetsBinding.instance.endOfFrame;
  return controller;
}
