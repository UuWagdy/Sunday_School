import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../models/card_template.dart';
import '../repositories/persons_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/stages_repository.dart';
import '../repositories/areas_repository.dart';
import '../repositories/fields_repository.dart';
import '../services/id_card_pdf_generator.dart';
import '../services/pdf_generation_task.dart';
import '../widgets/card_designer_preview.dart';
import '../widgets/print_progress_dialog.dart';

class IdCardScreen extends ConsumerStatefulWidget {
  const IdCardScreen({super.key});

  @override
  ConsumerState<IdCardScreen> createState() => _IdCardScreenState();
}

class _IdCardScreenState extends ConsumerState<IdCardScreen> {
  static CardTemplate _defaultBackCardTemplate() {
    final hiddenFields = CardTemplate.defaults().fields
        .map((field) => field.copyWith(visible: false))
        .toList();
    return CardTemplate(
      showLabels: false,
      fields: hiddenFields,
      fixedTexts: const [
        CardFixedTextElement(
          text: 'مدرسة الشمامسة',
          x: 0.12,
          y: 0.18,
          width: 0.76,
          height: 0.12,
          fontSize: 18,
          textAlign: CardTextAlign.center,
        ),
        CardFixedTextElement(
          text: 'خدمة الكنيسة',
          x: 0.12,
          y: 0.68,
          width: 0.76,
          height: 0.12,
          fontSize: 14,
          textAlign: CardTextAlign.center,
        ),
      ],
      barcode: const CardBarcodeElement(
        x: 0.25,
        y: 0.40,
        width: 0.50,
        height: 0.18,
      ),
      layerOrder: const ['fixed:0', 'barcode', 'fixed:1'],
    );
  }

  Uint8List? _logoBytes;
  Uint8List? _backgroundBytes;
  double _backgroundOpacity = 0.15;
  bool _isGenerating = false;
  bool _isDesignerMode = false;
  CardTemplate _cardTemplate = CardTemplate.defaults();
  CardTemplate _frontCardTemplate = CardTemplate.defaults();
  CardTemplate _backCardTemplate = _defaultBackCardTemplate();
  bool _isDesigningBackSide = false;
  bool _isTemplateLoading = true;
  String? _selectedDesignerElementId = 'field:0';
  final Set<String> _selectedDesignerElementIds = {'field:0'};
  final List<CardTemplate> _designerUndoStack = [];
  bool _showDesignerLayers = true;
  bool _captureDragUndo = false;
  Offset? _selectionDragStart;
  Offset? _selectionDragCurrent;
  ValueChanged<int>? _pendingColorPick;
  final GlobalKey _designerPreviewKey = GlobalKey();
  final FocusNode _designerFocusNode = FocusNode(debugLabel: 'cardDesigner');

  // Card layout
  final _colsController = TextEditingController(text: '2');
  final _rowsController = TextEditingController(text: '5');

  // Back side settings
  bool _printBackSide = false;
  Uint8List? _backLogoBytes;
  Uint8List? _backBackgroundBytes;
  double _backBackgroundOpacity = 0.15;
  final _backTopTextController = TextEditingController();
  final _backBottomTextController = TextEditingController();

  // Fields to show
  final Map<String, bool> _visibleFields = {
    'name': true,
    'code': true,
    'stage': true,
    'khoros': true,
    'area': true,
    'street': false,
    'phone': false,
    'mobile': false,
    'father': false,
    'photo': false,
    'rohot': false,
  };

  // Code type (barcode or qr)
  String _codeType = 'barcode';
  bool _simpleShowFieldLabels = true;
  CardBarcodeBackgroundMode _simpleCodeBackgroundMode =
      CardBarcodeBackgroundMode.white;

  // Persons selection
  String _searchQuery = '';
  int? _filterStageId;
  int? _filterAreaId;
  final List<PersonListDTO> _allFetchedPersons = [];
  final Set<int> _selectedPersonIds = {};

  // Pagination
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _limit = 50;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _fetchPersons();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _colsController.dispose();
    _rowsController.dispose();
    _backTopTextController.dispose();
    _backBottomTextController.dispose();
    _designerFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadSettings() async {
    final repo = ref.read(settingsRepositoryProvider);
    final activeTemplateJson = await repo.getSetting(
      SettingsRepository.idCardActiveTemplateKey,
    );
    final activeTemplate =
        activeTemplateJson == null || activeTemplateJson.trim().isEmpty
        ? null
        : CardTemplate.fromJsonString(activeTemplateJson);
    final backTemplateJson = await repo.getSetting('id_card_back_template');
    final backTemplate =
        backTemplateJson == null || backTemplateJson.trim().isEmpty
        ? _defaultBackCardTemplate()
        : CardTemplate.fromJsonString(backTemplateJson);

    final logoBase64 = await repo.getSetting('id_card_logo');
    if (logoBase64 != null && logoBase64.isNotEmpty) {
      if (mounted) setState(() => _logoBytes = base64Decode(logoBase64));
    }

    final backgroundBase64 = await repo.getSetting('id_card_background');
    if (backgroundBase64 != null && backgroundBase64.isNotEmpty && mounted) {
      setState(() => _backgroundBytes = base64Decode(backgroundBase64));
    }
    final backgroundOpacity = double.tryParse(
      await repo.getSetting('id_card_background_opacity') ?? '',
    );
    if (backgroundOpacity != null && mounted) {
      setState(
        () => _backgroundOpacity = backgroundOpacity.clamp(0, 1).toDouble(),
      );
    }

    final cols = await repo.getSetting('id_card_cols');
    if (cols != null) _colsController.text = cols;

    final rows = await repo.getSetting('id_card_rows');
    if (rows != null) _rowsController.text = rows;

    final printBack = await repo.getSetting('id_card_print_back');
    if (printBack != null && mounted)
      setState(() => _printBackSide = printBack == 'true');

    final backLogoBase64 = await repo.getSetting('id_card_back_logo');
    if (backLogoBase64 != null && backLogoBase64.isNotEmpty && mounted) {
      setState(() => _backLogoBytes = base64Decode(backLogoBase64));
    }
    final backBackgroundBase64 = await repo.getSetting(
      'id_card_back_background',
    );
    if (backBackgroundBase64 != null &&
        backBackgroundBase64.isNotEmpty &&
        mounted) {
      setState(() => _backBackgroundBytes = base64Decode(backBackgroundBase64));
    }
    final backBackgroundOpacity = double.tryParse(
      await repo.getSetting('id_card_back_background_opacity') ?? '',
    );
    if (backBackgroundOpacity != null && mounted) {
      setState(
        () => _backBackgroundOpacity = backBackgroundOpacity
            .clamp(0, 1)
            .toDouble(),
      );
    }

    final backTopText = await repo.getSetting('id_card_back_top_text');
    if (backTopText != null) _backTopTextController.text = backTopText;

    final backBottomText = await repo.getSetting('id_card_back_bottom_text');
    if (backBottomText != null) _backBottomTextController.text = backBottomText;

    for (final key in _visibleFields.keys) {
      final val = await repo.getSetting('id_card_show_$key');
      if (val != null) {
        if (mounted) setState(() => _visibleFields[key] = val == 'true');
      }
    }

    final savedCodeType = await repo.getSetting('id_card_code_type');
    if (savedCodeType != null && mounted) {
      setState(() => _codeType = savedCodeType);
    }

    final savedShowLabels = await repo.getSetting('id_card_simple_show_labels');
    if (savedShowLabels != null && mounted) {
      setState(() => _simpleShowFieldLabels = savedShowLabels == 'true');
    }

    final savedCodeBackground = await repo.getSetting(
      'id_card_simple_code_background',
    );
    if (savedCodeBackground != null && mounted) {
      setState(
        () => _simpleCodeBackgroundMode = CardBarcodeBackgroundMode.fromValue(
          savedCodeBackground,
        ),
      );
    }

    if (!mounted) return;
    final templateErrors = activeTemplate?.validate() ?? const <String>[];
    setState(() {
      _frontCardTemplate = activeTemplate != null && templateErrors.isEmpty
          ? activeTemplate
          : _buildTemplateFromSimpleSettings(
              logoBase64: logoBase64,
              backgroundBase64: backgroundBase64,
              backgroundOpacity: backgroundOpacity,
              codeType: savedCodeType ?? _codeType,
            );
      _backCardTemplate = backTemplate.validate().isEmpty
          ? backTemplate
          : _defaultBackCardTemplate();
      _cardTemplate = _isDesigningBackSide
          ? _backCardTemplate
          : _frontCardTemplate;
      _isTemplateLoading = false;
    });
  }

  Future<void> _saveSetting(String key, String value) async {
    await ref.read(settingsRepositoryProvider).saveSetting(key, value);
  }

  CardTemplate _buildTemplateFromSimpleSettings({
    String? logoBase64,
    String? backgroundBase64,
    double? backgroundOpacity,
    String? codeType,
  }) {
    final defaults = CardTemplate.defaults();
    final fields = defaults.fields.map((field) {
      return field.copyWith(
        visible: _visibleFields[field.fieldKey] ?? field.visible,
      );
    }).toList();

    final images = <CardImageElement>[
      if (logoBase64 != null && logoBase64.isNotEmpty)
        CardImageElement(
          imageBase64: logoBase64,
          x: 0.72,
          y: 0.06,
          width: 0.18,
          height: 0.20,
        ),
    ];

    return defaults.copyWith(
      backgroundImageBase64:
          backgroundBase64 != null && backgroundBase64.isNotEmpty
          ? backgroundBase64
          : null,
      backgroundOpacity: backgroundOpacity?.clamp(0, 1).toDouble() ?? 1,
      fields: fields,
      imageElements: images,
      barcode: defaults.barcode.copyWith(
        type: codeType == 'qr' ? CardCodeType.qr : CardCodeType.barcode,
      ),
    );
  }

  void _loadSimpleDesignIntoDesigner() {
    _replaceDesignerTemplate(
      _buildTemplateFromSimpleSettings(
        logoBase64: _logoBytes == null ? null : base64Encode(_logoBytes!),
        backgroundBase64: _backgroundBytes == null
            ? null
            : base64Encode(_backgroundBytes!),
        backgroundOpacity: _backgroundOpacity,
        codeType: _codeType,
      ),
      selectedElementId: 'field:0',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تحميل التصميم الأصلي للتعديل عليه')),
    );
  }

  Future<void> _fetchPersons() async {
    if (mounted)
      setState(() {
        _isLoading = true;
        _allFetchedPersons.clear();
        _offset = 0;
        _hasMore = true;
      });

    final repo = ref.read(personsRepositoryProvider.notifier);

    try {
      final results = await Future.wait([
        repo.fetchTotalCount(
          search: _searchQuery,
          stageIds: _filterStageId != null ? [_filterStageId!] : [],
          areaIds: _filterAreaId != null ? [_filterAreaId!] : [],
        ),
        repo.fetchPersons(
          search: _searchQuery,
          limit: _limit,
          offset: 0,
          stageIds: _filterStageId != null ? [_filterStageId!] : [],
          areaIds: _filterAreaId != null ? [_filterAreaId!] : [],
          includeServices: false,
        ),
      ]);

      final total = results[0] as int;
      final persons = results[1] as List<PersonListDTO>;

      if (mounted) {
        setState(() {
          _totalCount = total;
          _allFetchedPersons.addAll(persons);
          _offset = persons.length;
          _isLoading = false;
          if (persons.length < _limit) _hasMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    if (mounted) setState(() => _isLoading = true);

    final repo = ref.read(personsRepositoryProvider.notifier);
    final persons = await repo.fetchPersons(
      search: _searchQuery,
      limit: _limit,
      offset: _offset,
      stageIds: _filterStageId != null ? [_filterStageId!] : [],
      areaIds: _filterAreaId != null ? [_filterAreaId!] : [],
      includeServices: false,
    );

    if (mounted) {
      setState(() {
        _allFetchedPersons.addAll(persons);
        _isLoading = false;
        _offset += persons.length;
        if (persons.length < _limit) _hasMore = false;
      });
    }
  }

  Future<void> _fetchAllMatching() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final repo = ref.read(personsRepositoryProvider.notifier);
    try {
      final persons = await repo.fetchPersons(
        search: _searchQuery,
        limit: null, // Load all matching records
        offset: 0,
        stageIds: _filterStageId != null ? [_filterStageId!] : [],
        areaIds: _filterAreaId != null ? [_filterAreaId!] : [],
        includeServices: false,
      );

      if (mounted) {
        setState(() {
          _allFetchedPersons.clear();
          _allFetchedPersons.addAll(persons);
          _totalCount = persons.length;
          _offset = persons.length;
          _isLoading = false;
          _hasMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSelectAllOptions() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تحديد الكل'),
          content: Text(
            'يوجد $_totalCount شخص مطابق للبحث، ولكن تم تحميل ${_allFetchedPersons.length} فقط.\n\nهل تريد تحميل كافة الأشخاص وتحديدهم؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedPersonIds.addAll(
                    _allFetchedPersons.map((p) => p.id),
                  );
                });
              },
              child: const Text('تحديد المحملين فقط'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _fetchAllMatching();
                setState(() {
                  _selectedPersonIds.addAll(
                    _allFetchedPersons.map((p) => p.id),
                  );
                });
              },
              child: const Text('تحميل وتحديد الجميع'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      setState(() => _logoBytes = bytes);
      await _saveSetting('id_card_logo', base64Encode(bytes));
    } else if (result != null && result.files.single.path != null) {
      try {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        setState(() => _logoBytes = bytes);
        await _saveSetting('id_card_logo', base64Encode(bytes));
      } catch (_) {}
    }
  }

  Future<void> _deleteLogo() async {
    setState(() => _logoBytes = null);
    await ref.read(settingsRepositoryProvider).deleteSetting('id_card_logo');
  }

  Future<void> _pickBackground() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;

    Uint8List? bytes = result.files.single.bytes;
    final path = result.files.single.path;
    if (bytes == null && path != null) {
      bytes = await File(path).readAsBytes();
    }
    if (bytes == null || !mounted) return;

    setState(() => _backgroundBytes = bytes);
    await _saveSetting('id_card_background', base64Encode(bytes));
  }

  Future<void> _deleteBackground() async {
    setState(() => _backgroundBytes = null);
    await ref
        .read(settingsRepositoryProvider)
        .deleteSetting('id_card_background');
  }

  Future<void> _pickBackLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      setState(() => _backLogoBytes = bytes);
      await _saveSetting('id_card_back_logo', base64Encode(bytes));
    } else if (result != null && result.files.single.path != null) {
      try {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        setState(() => _backLogoBytes = bytes);
        await _saveSetting('id_card_back_logo', base64Encode(bytes));
      } catch (_) {}
    }
  }

  Future<void> _deleteBackLogo() async {
    setState(() => _backLogoBytes = null);
    await ref
        .read(settingsRepositoryProvider)
        .deleteSetting('id_card_back_logo');
  }

  Future<void> _pickBackBackground() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;

    Uint8List? bytes = result.files.single.bytes;
    final path = result.files.single.path;
    if (bytes == null && path != null) {
      bytes = await File(path).readAsBytes();
    }
    if (bytes == null || !mounted) return;

    setState(() => _backBackgroundBytes = bytes);
    await _saveSetting('id_card_back_background', base64Encode(bytes));
  }

  Future<void> _deleteBackBackground() async {
    setState(() => _backBackgroundBytes = null);
    await ref
        .read(settingsRepositoryProvider)
        .deleteSetting('id_card_back_background');
  }

  Future<void> _generateCards() async {
    if (_isGenerating) return;
    final selectedPersons = _allFetchedPersons
        .where((p) => _selectedPersonIds.contains(p.id))
        .toList();
    if (selectedPersons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تحديد شخص واحد على الأقل')),
      );
      return;
    }

    final cols = int.tryParse(_colsController.text) ?? 2;
    final rows = int.tryParse(_rowsController.text) ?? 5;

    await _saveSetting('id_card_cols', cols.toString());
    await _saveSetting('id_card_rows', rows.toString());
    for (var entry in _visibleFields.entries) {
      await _saveSetting('id_card_show_${entry.key}', entry.value.toString());
    }
    await _saveSetting('id_card_code_type', _codeType);
    await _saveSetting(
      'id_card_simple_show_labels',
      _simpleShowFieldLabels.toString(),
    );
    await _saveSetting(
      'id_card_simple_code_background',
      _simpleCodeBackgroundMode.value,
    );
    await _saveSetting('id_card_print_back', _printBackSide.toString());
    await _saveSetting('id_card_back_top_text', _backTopTextController.text);
    await _saveSetting(
      'id_card_back_bottom_text',
      _backBottomTextController.text,
    );
    await _saveSetting(
      'id_card_background_opacity',
      _backgroundOpacity.toString(),
    );
    await _saveSetting(
      'id_card_back_background_opacity',
      _backBackgroundOpacity.toString(),
    );

    if (!mounted) return;
    setState(() => _isGenerating = true);
    final progress = await showPrintProgressDialog(
      context,
      initialMessage: 'جاري تجهيز بيانات الكارنيهات...',
    );

    try {
      final task = await IdCardPdfGenerator.startCardGeneration(
        persons: selectedPersons,
        logoBytes: _logoBytes,
        visibleFields: _visibleFields,
        codeType: _codeType,
        showFieldLabels: _simpleShowFieldLabels,
        codeBackgroundMode: _simpleCodeBackgroundMode,
        cardsPerRow: cols,
        cardsPerCol: rows,
        printBackSide: _printBackSide,
        backLogoBytes: _backLogoBytes,
        backTopText: _backTopTextController.text,
        backBottomText: _backBottomTextController.text,
        backgroundBytes: _backgroundBytes,
        backgroundOpacity: _backgroundOpacity,
        backBackgroundBytes: _backBackgroundBytes,
        backBackgroundOpacity: _backBackgroundOpacity,
      );
      progress.setCancelAction(task.cancel);
      final subscription = task.progress.listen(
        (value) => progress.update(
          value.message,
          current: value.current,
          total: value.total,
        ),
      );
      final pdfBytes = await task.result.whenComplete(subscription.cancel);

      if (!mounted) return;
      await progress.complete(
        'تم إنشاء الملف، جاري فتح نافذة الطباعة...',
        total: selectedPersons.length,
      );
      progress.close();
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'ID_Cards.pdf',
      );
    } on PdfGenerationCancelledException {
      progress.close();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إلغاء الطباعة')));
      }
    } catch (e) {
      if (mounted) {
        progress.close();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('خطأ'),
            content: Text('حدث خطأ أثناء إنشاء الكارنيهات:\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
      debugPrint('Error generating cards: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateDesignerCards() async {
    if (_isGenerating) return;
    final selectedPersons = _allFetchedPersons
        .where((p) => _selectedPersonIds.contains(p.id))
        .toList();
    if (selectedPersons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تحديد شخص واحد على الأقل')),
      );
      return;
    }

    _syncActiveDesignerSide();
    final errors = [
      ..._frontCardTemplate.validate(),
      if (_printBackSide) ..._backCardTemplate.validate(),
    ];
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.first), backgroundColor: Colors.red),
      );
      return;
    }

    await ref
        .read(settingsRepositoryProvider)
        .saveActiveCardTemplate(_frontCardTemplate);
    await ref
        .read(settingsRepositoryProvider)
        .saveSetting('id_card_back_template', _backCardTemplate.toJsonString());
    await _saveSetting('id_card_print_back', _printBackSide.toString());
    if (!mounted) return;
    setState(() => _isGenerating = true);
    final progress = await showPrintProgressDialog(
      context,
      initialMessage: 'جاري تجهيز بيانات الكارنيهات...',
    );

    try {
      final task = await IdCardPdfGenerator.startCardGeneration(
        persons: selectedPersons,
        logoBytes: _logoBytes,
        visibleFields: _visibleFields,
        codeType: _codeType,
        cardsPerRow: int.tryParse(_colsController.text) ?? 2,
        cardsPerCol: int.tryParse(_rowsController.text) ?? 5,
        printBackSide: _printBackSide,
        backTopText: _backTopTextController.text,
        backBottomText: _backBottomTextController.text,
        template: _frontCardTemplate,
        backTemplate: _printBackSide ? _backCardTemplate : null,
      );
      progress.setCancelAction(task.cancel);
      final subscription = task.progress.listen(
        (value) => progress.update(
          value.message,
          current: value.current,
          total: value.total,
        ),
      );
      final pdfBytes = await task.result.whenComplete(subscription.cancel);

      if (!mounted) return;
      await progress.complete(
        'تم إنشاء الملف، جاري فتح نافذة الطباعة...',
        total: selectedPersons.length,
      );
      progress.close();
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Designed_ID_Cards.pdf',
      );
    } on PdfGenerationCancelledException {
      progress.close();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إلغاء الطباعة')));
      }
    } catch (e) {
      if (mounted) {
        progress.close();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('خطأ'),
            content: Text('حدث خطأ أثناء إنشاء الكارنيهات:\n$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسنًا'),
              ),
            ],
          ),
        );
      }
      debugPrint('Error generating designed cards: $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  String _getLabel(String key, String fallback) {
    final fields = ref.read(fieldsRepositoryProvider).asData?.value ?? [];
    final f = fields.where((f) => f.fieldKey == key).firstOrNull;
    return f?.name ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    // Listen to repository changes to trigger data refresh
    ref.listen(personsRepositoryProvider, (previous, next) {
      if (previous?.hasValue == true && next.isLoading) {
        _fetchPersons();
      }
    });

    final isWide = MediaQuery.of(context).size.width >= 800;

    final body = _isDesignerMode
        ? _buildDesignerWorkspace(isWide: isWide)
        : isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Panel: Settings
              Expanded(flex: 1, child: _buildSettingsPanel()),
              const SizedBox(width: 16),
              // Right Panel: Selection
              Expanded(flex: 2, child: _buildSelectionPanel()),
            ],
          )
        : DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'إعدادات الكارنيه'),
                    Tab(text: 'اختيار الأشخاص'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [_buildSettingsPanel(), _buildSelectionPanel()],
                  ),
                ),
              ],
            ),
          );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(padding: const EdgeInsets.all(16.0), child: body),
      ),
    );
  }

  Widget _buildCardModeSwitch() {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: false,
          icon: Icon(Icons.print_outlined),
          label: Text('طباعة بسيطة'),
        ),
        ButtonSegment(
          value: true,
          icon: Icon(Icons.design_services_outlined),
          label: Text('تصميم البطاقة'),
        ),
      ],
      selected: {_isDesignerMode},
      onSelectionChanged: (values) =>
          setState(() => _isDesignerMode = values.first),
    );
  }

  PersonListDTO? get _previewPerson {
    for (final person in _allFetchedPersons) {
      if (_selectedPersonIds.contains(person.id)) return person;
    }
    return null;
  }

  void _replaceDesignerTemplate(
    CardTemplate next, {
    bool trackUndo = true,
    String? selectedElementId,
    Set<String>? selectedElementIds,
  }) {
    if (trackUndo) _pushDesignerUndo();
    final nextSelectedIds = selectedElementIds == null
        ? null
        : Set<String>.from(selectedElementIds);
    setState(() {
      _cardTemplate = next;
      if (_isDesigningBackSide) {
        _backCardTemplate = next;
      } else {
        _frontCardTemplate = next;
      }
      if (selectedElementId != null) {
        _selectedDesignerElementId = selectedElementId;
        _selectedDesignerElementIds
          ..clear()
          ..add(selectedElementId);
      }
      if (nextSelectedIds != null) {
        _selectedDesignerElementIds
          ..clear()
          ..addAll(nextSelectedIds);
        _selectedDesignerElementId = nextSelectedIds.isEmpty
            ? null
            : nextSelectedIds.last;
      }
    });
  }

  void _pushDesignerUndo() {
    if (_designerUndoStack.isNotEmpty &&
        _designerUndoStack.last.toJsonString() ==
            _cardTemplate.toJsonString()) {
      return;
    }
    _designerUndoStack.add(_cardTemplate);
    if (_designerUndoStack.length > 80) {
      _designerUndoStack.removeAt(0);
    }
  }

  void _undoDesignerChange() {
    if (_designerUndoStack.isEmpty) return;
    setState(() {
      _cardTemplate = _designerUndoStack.removeLast();
      _selectedDesignerElementIds.removeWhere((id) => !_elementExists(id));
      if (_selectedDesignerElementId != null &&
          !_elementExists(_selectedDesignerElementId!)) {
        _selectedDesignerElementId = _selectedDesignerElementIds.isEmpty
            ? null
            : _selectedDesignerElementIds.last;
      }
    });
  }

  void _selectDesignerElement(String elementId, {bool toggle = false}) {
    if (_isDesignerElementLocked(elementId)) return;
    setState(() {
      if (toggle) {
        if (_selectedDesignerElementIds.contains(elementId)) {
          _selectedDesignerElementIds.remove(elementId);
        } else {
          _selectedDesignerElementIds.add(elementId);
        }
      } else {
        _selectedDesignerElementIds
          ..clear()
          ..add(elementId);
      }
      _selectedDesignerElementId = _selectedDesignerElementIds.isEmpty
          ? null
          : elementId;
    });
  }

  bool _elementExists(String elementId) {
    if (elementId == 'background' || elementId == 'barcode') return true;
    final parts = elementId.split(':');
    if (parts.length != 2) return false;
    final index = int.tryParse(parts[1]);
    if (index == null) return false;
    return switch (parts.first) {
      'field' => index >= 0 && index < _cardTemplate.fields.length,
      'image' => index >= 0 && index < _cardTemplate.imageElements.length,
      'fixed' => index >= 0 && index < _cardTemplate.fixedTexts.length,
      _ => false,
    };
  }

  bool _isDesignerElementLocked(String elementId) {
    if (elementId == 'barcode') return _cardTemplate.barcode.locked;
    final parts = elementId.split(':');
    if (parts.length != 2) return false;
    final index = int.tryParse(parts[1]);
    if (index == null) return false;
    return switch (parts.first) {
      'field' =>
        index >= 0 && index < _cardTemplate.fields.length
            ? _cardTemplate.fields[index].locked
            : false,
      'image' =>
        index >= 0 && index < _cardTemplate.imageElements.length
            ? _cardTemplate.imageElements[index].locked
            : false,
      'fixed' =>
        index >= 0 && index < _cardTemplate.fixedTexts.length
            ? _cardTemplate.fixedTexts[index].locked
            : false,
      _ => false,
    };
  }

  bool _isDesignerTextElement(String elementId) {
    final parts = elementId.split(':');
    if (parts.length != 2) return false;
    final index = int.tryParse(parts[1]);
    if (index == null) return false;
    if (parts.first == 'fixed') {
      return index >= 0 && index < _cardTemplate.fixedTexts.length;
    }
    if (parts.first == 'field') {
      return index >= 0 &&
          index < _cardTemplate.fields.length &&
          _cardTemplate.fields[index].fieldKey != CardFieldKeys.photo;
    }
    return false;
  }

  (double, int, CardTextAlign) _textElementStyle(String elementId) {
    final parts = elementId.split(':');
    final index = int.tryParse(parts.length == 2 ? parts[1] : '');
    if (parts.first == 'fixed' &&
        index != null &&
        index < _cardTemplate.fixedTexts.length) {
      final fixed = _cardTemplate.fixedTexts[index];
      return (fixed.fontSize, fixed.color, fixed.textAlign);
    }
    if (parts.first == 'field' &&
        index != null &&
        index < _cardTemplate.fields.length) {
      final field = _cardTemplate.fields[index];
      return (field.fontSize, field.color, field.textAlign);
    }
    return (12, 0xFF111111, CardTextAlign.right);
  }

  void _updateSelectedTextElements({
    double? fontSize,
    int? color,
    CardTextAlign? textAlign,
  }) {
    final fields = [..._cardTemplate.fields];
    final fixedTexts = [..._cardTemplate.fixedTexts];
    var changed = false;
    for (final id in _selectedDesignerElementIds) {
      final parts = id.split(':');
      if (parts.length != 2) continue;
      final index = int.tryParse(parts[1]);
      if (index == null) continue;
      if (parts.first == 'field' &&
          index >= 0 &&
          index < fields.length &&
          fields[index].fieldKey != CardFieldKeys.photo) {
        fields[index] = fields[index].copyWith(
          fontSize: fontSize,
          color: color,
          textAlign: textAlign,
        );
        changed = true;
      } else if (parts.first == 'fixed' &&
          index >= 0 &&
          index < fixedTexts.length) {
        fixedTexts[index] = fixedTexts[index].copyWith(
          fontSize: fontSize,
          color: color,
          textAlign: textAlign,
        );
        changed = true;
      }
    }
    if (!changed) return;
    _replaceDesignerTemplate(
      _cardTemplate.copyWith(fields: fields, fixedTexts: fixedTexts),
      selectedElementIds: _selectedDesignerElementIds,
    );
  }

  void _switchDesignerSide({required bool backSide}) {
    if (_isDesigningBackSide == backSide) return;
    setState(() {
      if (_isDesigningBackSide) {
        _backCardTemplate = _cardTemplate;
      } else {
        _frontCardTemplate = _cardTemplate;
      }
      _isDesigningBackSide = backSide;
      _cardTemplate = backSide ? _backCardTemplate : _frontCardTemplate;
      _designerUndoStack.clear();
      _selectedDesignerElementIds
        ..clear()
        ..add(_cardTemplate.normalizedLayerOrder.firstOrNull ?? 'barcode');
      _selectedDesignerElementId = _selectedDesignerElementIds.firstOrNull;
    });
  }

  void _syncActiveDesignerSide() {
    if (_isDesigningBackSide) {
      _backCardTemplate = _cardTemplate;
    } else {
      _frontCardTemplate = _cardTemplate;
    }
  }

  Widget _buildDesignerWorkspace({required bool isWide}) {
    final validationErrors = _cardTemplate.validate();
    if (_isTemplateLoading) {
      return const Center(child: CircularProgressIndicator());
    }
 
    final canvas = _buildDesignerCanvas(validationErrors);
    final tools = _buildDesignerToolsPanel(validationErrors);
    final inspector = _buildDesignerInspector();
 
    if (!isWide) {
      return ListView(
        children: [
          _buildDesignerHeader(validationErrors),
          const SizedBox(height: 12),
          _buildDesignerQuickToolbar(),
          const SizedBox(height: 12),
          SizedBox(height: 320, child: canvas),
          const SizedBox(height: 12),
          if (_showDesignerLayers) ...[tools, const SizedBox(height: 12)],
          inspector,
        ],
      );
    }
 
    return Column(
      children: [
        _buildDesignerHeader(validationErrors),
        const SizedBox(height: 12),
        _buildDesignerQuickToolbar(),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_showDesignerLayers) ...[
                SizedBox(width: 300, child: tools),
                const SizedBox(width: 12),
              ],
              Expanded(child: canvas),
              const SizedBox(width: 12),
              SizedBox(width: 330, child: inspector),
            ],
          ),
        ),
      ],
    );
  }
 
  Widget _buildDesignerHeader(List<String> validationErrors) {
    final screenW = MediaQuery.of(context).size.width;
    final isMobile = screenW < 800;

    final modeSwitch = SizedBox(
      width: isMobile ? double.infinity : 360,
      child: _buildCardModeSwitch(),
    );

    final title = Text(
      validationErrors.isEmpty
          ? 'مصمم الكارنيه - القالب الافتراضي جاهز للتعديل'
          : 'مصمم الكارنيه - يوجد ${validationErrors.length} تنبيه',
      style: Theme.of(context).textTheme.titleMedium,
      textAlign: isMobile ? TextAlign.center : TextAlign.start,
    );

    final actions = Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        IconButton(
          tooltip: 'استعادة القالب الافتراضي',
          onPressed: _resetDesignerTemplate,
          icon: const Icon(Icons.restart_alt),
        ),
        IconButton(
          tooltip: 'تحميل التصميم الأصلي',
          onPressed: _loadSimpleDesignIntoDesigner,
          icon: const Icon(Icons.file_download_outlined),
        ),
        IconButton(
          tooltip: 'حفظ القالب',
          onPressed: _saveDesignerTemplate,
          icon: const Icon(Icons.save_outlined),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _isGenerating ? null : _generateDesignerCards,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: Text(
            _isGenerating ? 'جاري التجهيز...' : 'طباعة التصميم الحالي',
          ),
        ),
      ],
    );

    if (isMobile) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              modeSwitch,
              const SizedBox(height: 12),
              title,
              const SizedBox(height: 12),
              actions,
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            modeSwitch,
            const SizedBox(width: 16),
            Expanded(child: title),
            actions,
          ],
        ),
      ),
    );
  }
 
  Widget _buildDesignerQuickToolbar() {
    final screenW = MediaQuery.of(context).size.width;
    final isMobile = screenW < 800;

    final children = [
      IconButton.filledTonal(
        tooltip: 'إضافة نص',
        onPressed: () => _showFixedTextDialog(),
        icon: const Icon(Icons.title),
      ),
      const SizedBox(width: 6),
      IconButton.filledTonal(
        tooltip: 'إضافة صورة',
        onPressed: _addDesignerImageElement,
        icon: const Icon(Icons.add_photo_alternate_outlined),
      ),
      const SizedBox(width: 6),
      IconButton.filledTonal(
        tooltip: _showDesignerLayers ? 'إخفاء الطبقات' : 'إظهار الطبقات',
        onPressed: () =>
            setState(() => _showDesignerLayers = !_showDesignerLayers),
        icon: Icon(
          _showDesignerLayers
              ? Icons.layers_clear_outlined
              : Icons.layers_outlined,
        ),
      ),
      const SizedBox(width: 6),
      IconButton.filledTonal(
        tooltip: 'تراجع',
        onPressed: _designerUndoStack.isEmpty
            ? null
            : _undoDesignerChange,
        icon: const Icon(Icons.undo),
      ),
      const SizedBox(width: 10),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('طباعة ظهر الكارنيه'),
          Transform.scale(
            scale: 0.78,
            child: Switch(
              value: _printBackSide,
              onChanged: (value) {
                if (!value && _isDesigningBackSide) {
                  _switchDesignerSide(backSide: false);
                }
                setState(() => _printBackSide = value);
              },
            ),
          ),
        ],
      ),
      if (_printBackSide) ...[
        const SizedBox(width: 6),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('الوجه')),
            ButtonSegment(value: true, label: Text('الظهر')),
          ],
          selected: {_isDesigningBackSide},
          onSelectionChanged: (values) =>
              _switchDesignerSide(backSide: values.first),
        ),
      ],
      if (_pendingColorPick != null) ...[
        const SizedBox(width: 12),
        const Icon(Icons.colorize, color: Color(0xFF1A237E)),
        const SizedBox(width: 6),
        const Text('اضغط على البطاقة لالتقاط اللون'),
      ],
      if (!isMobile) const Spacer(),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text(
          _selectedDesignerElementIds.length > 1
              ? '${_selectedDesignerElementIds.length} طبقات محددة'
              : 'مصمم الكارنيه',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    ];

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: isMobile
            ? Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: children,
              )
            : Row(
                children: children,
              ),
      ),
    );
  }

  Widget _buildDesignerCanvas(List<String> validationErrors) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Focus(
                focusNode: _designerFocusNode,
                autofocus: true,
                onKeyEvent: _handleDesignerKeyEvent,
                child: LayoutBuilder(
                  builder: (context, constraints) =>
                      _buildBoundedDesignerPreview(constraints),
                ),
              ),
            ),
            if (_previewPerson == null) ...[
              const SizedBox(height: 10),
              Text(
                'حدد شخصًا من القائمة لمعاينة بيانات حقيقية على البطاقة.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
            if (validationErrors.isNotEmpty) ...[
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    validationErrors.take(2).join(' • '),
                    style: const TextStyle(color: Colors.red),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBoundedDesignerPreview(BoxConstraints constraints) {
    const maxPreviewWidth = 920.0;
    final aspectRatio = _cardTemplate.width / _cardTemplate.height;
    final availableWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : maxPreviewWidth;
    final maxWidth = math.min(availableWidth, maxPreviewWidth);
    final maxHeight = constraints.maxHeight;
    var previewWidth = maxWidth;

    if (maxHeight.isFinite) {
      previewWidth = math.min(previewWidth, maxHeight * aspectRatio);
    }

    final previewHeight = previewWidth / aspectRatio;

    return Center(
      child: SizedBox(
        width: previewWidth,
        height: previewHeight,
        child: RepaintBoundary(
          key: _designerPreviewKey,
          child: Listener(
            onPointerDown: _handlePreviewPointerDown,
            onPointerMove: _handlePreviewPointerMove,
            onPointerUp: _handlePreviewPointerUp,
            onPointerCancel: (_) => _clearSelectionDrag(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CardDesignerPreview(
                  template: _cardTemplate,
                  person: _previewPerson,
                  editable: true,
                  selectedElementId: _selectedDesignerElementId,
                  selectedElementIds: _selectedDesignerElementIds,
                  onElementSelected: (elementId) {
                    _designerFocusNode.requestFocus();
                    _selectDesignerElement(elementId);
                  },
                  onElementDragStarted: _startDesignerDrag,
                  onElementDragEnded: (_) => _captureDragUndo = false,
                  onElementMoved: _moveDesignerElement,
                  onElementResized: _resizeDesignerElement,
                ),
                if (_selectionDragStart != null &&
                    _selectionDragCurrent != null)
                  _buildSelectionDragOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesignerToolsPanel(List<String> validationErrors) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return Card(
      elevation: 3,
      child: ListView(
        shrinkWrap: !isWide,
        physics: isWide ? null : const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        children: [
          Text('الأدوات', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildDesignerPersonPicker(),
          const Divider(),
          _buildDesignerLayersPanel(),
          const Divider(),
          SwitchListTile(
            title: const Text('إظهار عناوين الحقول افتراضيًا'),
            value: _cardTemplate.showLabels,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (value) => setState(
              () => _cardTemplate = _cardTemplate.copyWith(showLabels: value),
            ),
          ),
          const Divider(),
          _buildDesignerBackgroundControls(),
          const Divider(),
          _buildImageElementControls(),
          const Divider(),
          _buildDesignerFieldsControls(),
          const Divider(),
          _buildFixedTextControls(),
          if (validationErrors.isNotEmpty) ...[
            const Divider(),
            const Text(
              'تنبيهات القالب',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 6),
            for (final error in validationErrors)
              Text(
                '• $error',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesignerPersonPicker() {
    final previewPerson = _previewPerson;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'شخص المعاينة والطباعة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: previewPerson?.id,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'اختر شخصًا',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: [
            for (final person in _allFetchedPersons)
              DropdownMenuItem<int>(
                value: person.id,
                child: Text(person.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (id) {
            if (id == null) return;
            setState(() {
              _selectedPersonIds
                ..clear()
                ..add(id);
            });
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text('المحدد للطباعة: ${_selectedPersonIds.length}'),
            ),
            TextButton.icon(
              onPressed: _fetchAllMatching,
              icon: const Icon(Icons.download, size: 18),
              label: const Text('تحميل الكل'),
            ),
          ],
        ),
        if (_allFetchedPersons.isEmpty)
          Text(
            'لا توجد بيانات محملة للمعاينة',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildDesignerLayersPanel() {
    final layers = <({String id, String title, IconData icon, bool visible})>[
      (
        id: 'background',
        title: 'خلفية البطاقة',
        icon: Icons.wallpaper_outlined,
        visible: _cardTemplate.backgroundOpacity > 0,
      ),
      for (var i = _cardTemplate.imageElements.length - 1; i >= 0; i--)
        (
          id: 'image:$i',
          title: 'صورة ${i + 1}',
          icon: Icons.image_outlined,
          visible: _cardTemplate.imageElements[i].visible,
        ),
      for (var i = _cardTemplate.fixedTexts.length - 1; i >= 0; i--)
        (
          id: 'fixed:$i',
          title: _cardTemplate.fixedTexts[i].text.isEmpty
              ? 'نص ثابت ${i + 1}'
              : _cardTemplate.fixedTexts[i].text,
          icon: Icons.title,
          visible: _cardTemplate.fixedTexts[i].visible,
        ),
      (
        id: 'barcode',
        title: 'الكود',
        icon: Icons.qr_code_2,
        visible: _cardTemplate.barcode.visible,
      ),
      for (var i = _cardTemplate.fields.length - 1; i >= 0; i--)
        (
          id: 'field:$i',
          title: CardFieldKeys.arabicLabel(_cardTemplate.fields[i].fieldKey),
          icon: _cardTemplate.fields[i].fieldKey == CardFieldKeys.photo
              ? Icons.person_outline
              : Icons.text_fields,
          visible: _cardTemplate.fields[i].visible,
        ),
    ];

    final order = _cardTemplate.normalizedLayerOrder;
    layers.sort((a, b) {
      if (a.id == 'background') return -1;
      if (b.id == 'background') return 1;
      return order.indexOf(b.id).compareTo(order.indexOf(a.id));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Layers',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              tooltip: 'إضافة نص',
              onPressed: () => _showFixedTextDialog(),
              icon: const Icon(Icons.add, size: 18),
              iconSize: 18,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              tooltip: 'إضافة صورة',
              onPressed: _addDesignerImageElement,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              iconSize: 18,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final layer in layers) _buildLayerTile(layer),
      ],
    );
  }

  Widget _buildLayerTile(
    ({String id, String title, IconData icon, bool visible}) layer,
  ) {
    final selected = _selectedDesignerElementIds.contains(layer.id);
    final locked = _isDesignerElementLocked(layer.id);
    final canToggle =
        layer.id != 'background' || _cardTemplate.backgroundImageBase64 != null;
    final canDelete =
        layer.id.startsWith('image:') || layer.id.startsWith('fixed:');
    final canReorder = layer.id != 'background';

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE8EAF6) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? const Color(0xFF1A237E) : Colors.grey.shade300,
        ),
      ),
      child: IconButtonTheme(
        data: IconButtonThemeData(
          style: IconButton.styleFrom(
            iconSize: 15,
            minimumSize: const Size(22, 22),
            fixedSize: const Size(22, 22),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        child: ListTile(
          dense: true,
          minLeadingWidth: 24,
          horizontalTitleGap: 4,
          contentPadding: const EdgeInsetsDirectional.only(start: 4, end: 4),
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          leading: SizedBox.square(
            dimension: 20,
            child: Transform.scale(
              scale: 0.75,
              child: Checkbox(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                value: selected,
                onChanged: locked
                    ? null
                    : (_) {
                        _designerFocusNode.requestFocus();
                        _selectDesignerElement(layer.id, toggle: true);
                      },
              ),
            ),
          ),
          title: Text(
            locked ? '${layer.title}  (مقفولة)' : layer.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          selected: selected,
          onTap: locked
              ? null
              : () {
                  _designerFocusNode.requestFocus();
                  _selectDesignerElement(layer.id);
                },
          trailing: Wrap(
            spacing: 2,
            children: [
              Icon(
                layer.icon,
                size: 15,
                color: selected ? const Color(0xFF1A237E) : null,
              ),
              if (layer.id != 'background')
                IconButton(
                  tooltip: locked ? 'فتح الطبقة' : 'قفل الطبقة',
                  onPressed: () => _toggleDesignerLayerLock(layer.id),
                  icon: Icon(locked ? Icons.lock : Icons.lock_open_outlined),
                ),
              if (canToggle)
                IconButton(
                  tooltip: layer.visible ? 'إخفاء الطبقة' : 'إظهار الطبقة',
                  onPressed: () => _toggleDesignerLayer(layer.id),
                  icon: Icon(
                    layer.visible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              if (canReorder) ...[
                IconButton(
                  tooltip: 'رفع الطبقة',
                  onPressed: () => _moveLayerOrder(layer.id, 1),
                  icon: const Icon(Icons.keyboard_arrow_up),
                ),
                IconButton(
                  tooltip: 'خفض الطبقة',
                  onPressed: () => _moveLayerOrder(layer.id, -1),
                  icon: const Icon(Icons.keyboard_arrow_down),
                ),
              ],
              if (canDelete)
                IconButton(
                  tooltip: 'حذف الطبقة',
                  onPressed: () => _deleteDesignerLayer(layer.id),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesignerInspector() {
    final selected = _selectedDesignerElementId;
    final isWide = MediaQuery.of(context).size.width >= 800;
    return Card(
      elevation: 3,
      child: ListView(
        shrinkWrap: !isWide,
        physics: isWide ? null : const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(14),
        children: [
          Text('خصائص العنصر', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (selected == null)
            Text(
              'اضغط على أي نص أو صورة أو كود داخل البطاقة لتعديل خصائصه.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ..._buildSelectedDesignerControls(selected),
        ],
      ),
    );
  }

  List<Widget> _buildSelectedDesignerControls(String selected) {
    final selectedTextIds = _selectedDesignerElementIds
        .where(_isDesignerTextElement)
        .toList();
    if (_selectedDesignerElementIds.length > 1 &&
        selectedTextIds.length == _selectedDesignerElementIds.length) {
      final reference = _textElementStyle(selectedTextIds.first);
      return [
        Text(
          'خصائص ${selectedTextIds.length} نصوص',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildScalarSlider(
          label: 'حجم الخط',
          value: reference.$1,
          min: CardTemplate.minTextSize,
          max: _designerFontSliderMax(reference.$1),
          onChanged: (value) => _updateSelectedTextElements(fontSize: value),
        ),
        _buildTextAlignControl(
          value: reference.$3,
          onChanged: (value) => _updateSelectedTextElements(textAlign: value),
        ),
        _buildColorControl(
          selectedColor: reference.$2,
          onSelected: (color) => _updateSelectedTextElements(color: color),
        ),
      ];
    }

    if (selected == 'background') {
      return [
        const Text(
          'خلفية البطاقة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildDesignerBackgroundControls(),
      ];
    }

    if (selected == 'barcode') {
      final barcode = _cardTemplate.barcode;
      return [
        const Text('الكود', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SwitchListTile(
          title: const Text('إظهار الكود'),
          value: barcode.visible,
          dense: true,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) => _replaceDesignerTemplate(
            _cardTemplate.copyWith(barcode: barcode.copyWith(visible: value)),
            selectedElementId: 'barcode',
          ),
        ),
        DropdownButtonFormField<CardCodeType>(
          value: barcode.type,
          decoration: const InputDecoration(
            labelText: 'نوع الكود',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: CardCodeType.values
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.arabicLabel),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(
              () => _cardTemplate = _cardTemplate.copyWith(
                barcode: barcode.copyWith(type: value),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<CardBarcodeBackgroundMode>(
          value: barcode.backgroundMode,
          decoration: const InputDecoration(
            labelText: 'خلفية الكود',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: CardBarcodeBackgroundMode.values
              .map(
                (mode) => DropdownMenuItem(
                  value: mode,
                  child: Text(mode.arabicLabel),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(
              () => _cardTemplate = _cardTemplate.copyWith(
                barcode: barcode.copyWith(backgroundMode: value),
              ),
            );
          },
        ),
        _buildNormalizedSlider(
          label: 'الموضع الأفقي',
          value: barcode.x,
          onChanged: (value) => setState(
            () => _cardTemplate = _cardTemplate.copyWith(
              barcode: barcode.copyWith(
                x: _clampPosition(value, barcode.width),
              ),
            ),
          ),
        ),
        _buildNormalizedSlider(
          label: 'الموضع الرأسي',
          value: barcode.y,
          onChanged: (value) => setState(
            () => _cardTemplate = _cardTemplate.copyWith(
              barcode: barcode.copyWith(
                y: _clampPosition(value, barcode.height),
              ),
            ),
          ),
        ),
        _buildNormalizedSlider(
          label: 'العرض',
          value: barcode.width,
          min: 0.10,
          onChanged: (value) => setState(
            () => _cardTemplate = _cardTemplate.copyWith(
              barcode: barcode.copyWith(
                width: _clampSize(value, barcode.x, min: 0.10),
              ),
            ),
          ),
        ),
        _buildNormalizedSlider(
          label: 'الارتفاع',
          value: barcode.height,
          min: 0.08,
          onChanged: (value) => setState(
            () => _cardTemplate = _cardTemplate.copyWith(
              barcode: barcode.copyWith(
                height: _clampSize(value, barcode.y, min: 0.08),
              ),
            ),
          ),
        ),
      ];
    }

    final parts = selected.split(':');
    if (parts.length != 2) {
      return [
        Text(
          'العنصر المحدد غير معروف',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ];
    }
    final index = int.tryParse(parts[1]);
    if (index == null) {
      return [
        Text(
          'العنصر المحدد غير معروف',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ];
    }

    if (parts[0] == 'field' &&
        index >= 0 &&
        index < _cardTemplate.fields.length) {
      final field = _cardTemplate.fields[index];
      final label = CardFieldKeys.arabicLabel(field.fieldKey);
      return [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        SwitchListTile(
          title: const Text('إظهار الحقل'),
          value: field.visible,
          dense: true,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) =>
              _updateDesignerField(index, field.copyWith(visible: value)),
        ),
        DropdownButtonFormField<CardLabelMode>(
          value: field.labelMode,
          decoration: const InputDecoration(
            labelText: 'عنوان الحقل',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: CardLabelMode.values
              .map(
                (mode) => DropdownMenuItem(
                  value: mode,
                  child: Text(mode.arabicLabel),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            _updateDesignerField(index, field.copyWith(labelMode: value));
          },
        ),
        _buildNormalizedSlider(
          label: 'الموضع الأفقي',
          value: field.x,
          onChanged: (value) => _updateDesignerField(
            index,
            field.copyWith(x: _clampPosition(value, field.width)),
          ),
        ),
        _buildNormalizedSlider(
          label: 'الموضع الرأسي',
          value: field.y,
          onChanged: (value) => _updateDesignerField(
            index,
            field.copyWith(y: _clampPosition(value, field.height)),
          ),
        ),
        _buildNormalizedSlider(
          label: 'العرض',
          value: field.width,
          min: 0.08,
          onChanged: (value) => _updateDesignerField(
            index,
            field.copyWith(width: _clampSize(value, field.x, min: 0.08)),
          ),
        ),
        _buildNormalizedSlider(
          label: 'الارتفاع',
          value: field.height,
          min: 0.05,
          onChanged: (value) => _updateDesignerField(
            index,
            field.copyWith(height: _clampSize(value, field.y, min: 0.05)),
          ),
        ),
        _buildScalarSlider(
          label: 'حجم الخط',
          value: field.fontSize,
          min: CardTemplate.minTextSize,
          max: _designerFontSliderMax(field.fontSize),
          inputMax: CardTemplate.maxTextSize,
          onChanged: (value) =>
              _updateDesignerField(index, field.copyWith(fontSize: value)),
        ),
        const Text('لون النص'),
        const SizedBox(height: 6),
        _buildTextAlignControl(
          value: field.textAlign,
          onChanged: (value) =>
              _updateDesignerField(index, field.copyWith(textAlign: value)),
        ),
        _buildColorControl(
          selectedColor: field.color,
          onSelected: (color) =>
              _updateDesignerField(index, field.copyWith(color: color)),
        ),
      ];
    }

    if (parts[0] == 'image' &&
        index >= 0 &&
        index < _cardTemplate.imageElements.length) {
      final image = _cardTemplate.imageElements[index];
      return [
        Text(
          'صورة ${index + 1}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        SwitchListTile(
          title: const Text('إظهار الصورة'),
          value: image.visible,
          dense: true,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) =>
              _updateDesignerImage(index, image.copyWith(visible: value)),
        ),
        DropdownButtonFormField<CardBackgroundFit>(
          value: image.fit,
          decoration: const InputDecoration(
            labelText: 'طريقة عرض الصورة',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: CardBackgroundFit.values
              .map(
                (fit) =>
                    DropdownMenuItem(value: fit, child: Text(fit.arabicLabel)),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            _updateDesignerImage(index, image.copyWith(fit: value));
          },
        ),
        _buildScalarSlider(
          label: 'شفافية الصورة',
          value: (image.opacity * 100).clamp(0, 100).toDouble(),
          min: 0,
          max: 100,
          divisions: 20,
          suffix: '%',
          onChanged: (value) =>
              _updateDesignerImage(index, image.copyWith(opacity: value / 100)),
        ),
        _buildNormalizedSlider(
          label: 'الموضع الأفقي',
          value: image.x,
          onChanged: (value) => _updateDesignerImage(
            index,
            image.copyWith(x: _clampPosition(value, image.width)),
          ),
        ),
        _buildNormalizedSlider(
          label: 'الموضع الرأسي',
          value: image.y,
          onChanged: (value) => _updateDesignerImage(
            index,
            image.copyWith(y: _clampPosition(value, image.height)),
          ),
        ),
        _buildNormalizedSlider(
          label: 'العرض',
          value: image.width,
          min: 0.08,
          onChanged: (value) => _updateDesignerImage(
            index,
            image.copyWith(width: _clampSize(value, image.x, min: 0.08)),
          ),
        ),
        _buildNormalizedSlider(
          label: 'الارتفاع',
          value: image.height,
          min: 0.08,
          onChanged: (value) => _updateDesignerImage(
            index,
            image.copyWith(height: _clampSize(value, image.y, min: 0.08)),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            final images = [..._cardTemplate.imageElements]..removeAt(index);
            setState(() {
              _cardTemplate = _cardTemplate.copyWith(imageElements: images);
              _selectedDesignerElementId = null;
            });
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('حذف الصورة'),
        ),
      ];
    }

    if (parts[0] == 'fixed' &&
        index >= 0 &&
        index < _cardTemplate.fixedTexts.length) {
      final fixed = _cardTemplate.fixedTexts[index];
      return [
        const Text('نص ثابت', style: TextStyle(fontWeight: FontWeight.bold)),
        SwitchListTile(
          title: const Text('إظهار النص'),
          value: fixed.visible,
          dense: true,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) =>
              _updateFixedText(index, fixed.copyWith(visible: value)),
        ),
        TextFormField(
          key: ValueKey('fixed_text_${index}_${fixed.text}'),
          initialValue: fixed.text,
          decoration: const InputDecoration(labelText: 'النص'),
          onChanged: (value) =>
              _updateFixedText(index, fixed.copyWith(text: value)),
        ),
        _buildNormalizedSlider(
          label: 'الموضع الأفقي',
          value: fixed.x,
          onChanged: (value) => _updateFixedText(
            index,
            fixed.copyWith(x: _clampPosition(value, fixed.width)),
          ),
        ),
        _buildNormalizedSlider(
          label: 'الموضع الرأسي',
          value: fixed.y,
          onChanged: (value) => _updateFixedText(
            index,
            fixed.copyWith(y: _clampPosition(value, fixed.height)),
          ),
        ),
        _buildNormalizedSlider(
          label: 'العرض',
          value: fixed.width,
          min: 0.10,
          onChanged: (value) => _updateFixedText(
            index,
            fixed.copyWith(width: _clampSize(value, fixed.x, min: 0.10)),
          ),
        ),
        _buildNormalizedSlider(
          label: 'الارتفاع',
          value: fixed.height,
          min: 0.05,
          onChanged: (value) => _updateFixedText(
            index,
            fixed.copyWith(height: _clampSize(value, fixed.y, min: 0.05)),
          ),
        ),
        _buildScalarSlider(
          label: 'حجم الخط',
          value: fixed.fontSize,
          min: CardTemplate.minTextSize,
          max: _designerFontSliderMax(fixed.fontSize),
          inputMax: CardTemplate.maxTextSize,
          onChanged: (value) =>
              _updateFixedText(index, fixed.copyWith(fontSize: value)),
        ),
        const Text('لون النص'),
        const SizedBox(height: 6),
        _buildTextAlignControl(
          value: fixed.textAlign,
          onChanged: (value) =>
              _updateFixedText(index, fixed.copyWith(textAlign: value)),
        ),
        _buildColorControl(
          selectedColor: fixed.color,
          onSelected: (color) =>
              _updateFixedText(index, fixed.copyWith(color: color)),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            final fixedTexts = [..._cardTemplate.fixedTexts]..removeAt(index);
            setState(() {
              _cardTemplate = _cardTemplate.copyWith(fixedTexts: fixedTexts);
              _selectedDesignerElementId = null;
            });
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('حذف النص'),
        ),
      ];
    }

    return [
      Text(
        'العنصر المحدد غير موجود',
        style: TextStyle(color: Colors.grey.shade600),
      ),
    ];
  }

  Widget _buildDesignerPanel() {
    final validationErrors = _cardTemplate.validate();
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isTemplateLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  _buildCardModeSwitch(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'مصمم الكارنيه',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'استعادة القالب الافتراضي',
                        onPressed: _resetDesignerTemplate,
                        icon: const Icon(Icons.restart_alt),
                      ),
                      IconButton(
                        tooltip: 'حفظ القالب',
                        onPressed: _saveDesignerTemplate,
                        icon: const Icon(Icons.save_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CardDesignerPreview(
                    template: _cardTemplate,
                    person: _previewPerson,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: _isGenerating ? null : _generateDesignerCards,
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(
                        _isGenerating
                            ? 'جاري التجهيز...'
                            : 'طباعة التصميم الحالي',
                      ),
                    ),
                  ),
                  if (_previewPerson == null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'حدد شخصًا من القائمة لمعاينة بيانات حقيقية على البطاقة.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (validationErrors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'يرجى مراجعة القالب',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 6),
                            for (final error in validationErrors)
                              Text(
                                '• $error',
                                style: const TextStyle(color: Colors.red),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('إظهار عناوين الحقول افتراضيًا'),
                    value: _cardTemplate.showLabels,
                    onChanged: (value) => setState(
                      () => _cardTemplate = _cardTemplate.copyWith(
                        showLabels: value,
                      ),
                    ),
                  ),
                  const Divider(),
                  _buildDesignerBackgroundControls(),
                  const Divider(),
                  _buildDesignerBarcodeControls(),
                  const Divider(),
                  _buildImageElementControls(),
                  const Divider(),
                  _buildDesignerFieldsControls(),
                  const Divider(),
                  _buildFixedTextControls(),
                ],
              ),
      ),
    );
  }

  Widget _buildDesignerBackgroundControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'خلفية البطاقة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickDesignerBackground,
              icon: const Icon(Icons.wallpaper_outlined, size: 18),
              label: Text(
                _cardTemplate.backgroundImageBase64 == null
                    ? 'اختيار خلفية'
                    : 'تغيير الخلفية',
              ),
            ),
            if (_cardTemplate.backgroundImageBase64 != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'حذف الخلفية',
                onPressed: _deleteDesignerBackground,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('أرضية البطاقة شفافة'),
          value: _cardTemplate.transparentBackground,
          dense: true,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            setState(
              () => _cardTemplate = _cardTemplate.copyWith(
                transparentBackground: value,
              ),
            );
          },
        ),
        Row(
          children: [
            const Text('شفافية الخلفية'),
            Expanded(
              child: Slider(
                value: _cardTemplate.backgroundOpacity.clamp(0, 1).toDouble(),
                min: 0,
                max: 1,
                divisions: 100,
                label: '${(_cardTemplate.backgroundOpacity * 100).round()}%',
                onChanged: (value) {
                  setState(
                    () => _cardTemplate = _cardTemplate.copyWith(
                      backgroundOpacity: value,
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                '${(_cardTemplate.backgroundOpacity * 100).round()}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<CardBackgroundFit>(
          value: _cardTemplate.backgroundFit,
          decoration: const InputDecoration(
            labelText: 'طريقة عرض الخلفية',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: CardBackgroundFit.values
              .map(
                (fit) =>
                    DropdownMenuItem(value: fit, child: Text(fit.arabicLabel)),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(
              () =>
                  _cardTemplate = _cardTemplate.copyWith(backgroundFit: value),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDesignerBarcodeControls() {
    final barcode = _cardTemplate.barcode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الكود', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<CardCodeType>(
          value: barcode.type,
          decoration: const InputDecoration(
            labelText: 'نوع الكود',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: CardCodeType.values
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.arabicLabel),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(
              () => _cardTemplate = _cardTemplate.copyWith(
                barcode: barcode.copyWith(type: value),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<CardBarcodeBackgroundMode>(
          value: barcode.backgroundMode,
          decoration: const InputDecoration(
            labelText: 'خلفية الكود',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: CardBarcodeBackgroundMode.values
              .map(
                (mode) => DropdownMenuItem(
                  value: mode,
                  child: Text(mode.arabicLabel),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(
              () => _cardTemplate = _cardTemplate.copyWith(
                barcode: barcode.copyWith(backgroundMode: value),
              ),
            );
          },
        ),
        _buildNormalizedSlider(
          label: 'الموضع الأفقي',
          value: barcode.x,
          onChanged: (value) => setState(
            () => _cardTemplate = _cardTemplate.copyWith(
              barcode: barcode.copyWith(x: value),
            ),
          ),
        ),
        _buildNormalizedSlider(
          label: 'الموضع الرأسي',
          value: barcode.y,
          onChanged: (value) => setState(
            () => _cardTemplate = _cardTemplate.copyWith(
              barcode: barcode.copyWith(y: value),
            ),
          ),
        ),
        _buildNormalizedSlider(
          label: 'العرض',
          value: barcode.width,
          min: 0.10,
          onChanged: (value) => setState(
            () => _cardTemplate = _cardTemplate.copyWith(
              barcode: barcode.copyWith(width: value),
            ),
          ),
        ),
        _buildNormalizedSlider(
          label: 'الارتفاع',
          value: barcode.height,
          min: 0.08,
          onChanged: (value) => setState(
            () => _cardTemplate = _cardTemplate.copyWith(
              barcode: barcode.copyWith(height: value),
            ),
          ),
        ),
        if (barcode.backgroundMode == CardBarcodeBackgroundMode.transparent)
          Text(
            'قد يصعب مسح الكود إذا كانت الخلفية داكنة أو مزدحمة.',
            style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildImageElementControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'عناصر الصور',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              tooltip: 'إضافة صورة',
              onPressed: _addDesignerImageElement,
              icon: const Icon(Icons.add_photo_alternate_outlined),
            ),
          ],
        ),
        if (_cardTemplate.imageElements.isEmpty)
          Text(
            'لا توجد صور إضافية',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        for (var i = 0; i < _cardTemplate.imageElements.length; i++)
          _buildImageElementTile(i, _cardTemplate.imageElements[i]),
      ],
    );
  }

  Widget _buildImageElementTile(int index, CardImageElement image) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        'صورة ${index + 1}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: IconButton(
        tooltip: 'حذف الصورة',
        onPressed: () {
          final images = [..._cardTemplate.imageElements]..removeAt(index);
          setState(
            () => _cardTemplate = _cardTemplate.copyWith(imageElements: images),
          );
        },
        icon: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      children: [
        _buildScalarSlider(
          label: 'شفافية الصورة',
          value: (image.opacity * 100).clamp(0, 100).toDouble(),
          min: 0,
          max: 100,
          divisions: 20,
          suffix: '%',
          onChanged: (value) =>
              _updateDesignerImage(index, image.copyWith(opacity: value / 100)),
        ),
        DropdownButtonFormField<CardBackgroundFit>(
          value: image.fit,
          decoration: const InputDecoration(
            labelText: 'طريقة عرض الصورة',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: CardBackgroundFit.values
              .map(
                (fit) =>
                    DropdownMenuItem(value: fit, child: Text(fit.arabicLabel)),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            _updateDesignerImage(index, image.copyWith(fit: value));
          },
        ),
        _buildNormalizedSlider(
          label: 'الموضع الأفقي',
          value: image.x,
          onChanged: (value) =>
              _updateDesignerImage(index, image.copyWith(x: value)),
        ),
        _buildNormalizedSlider(
          label: 'الموضع الرأسي',
          value: image.y,
          onChanged: (value) =>
              _updateDesignerImage(index, image.copyWith(y: value)),
        ),
        _buildNormalizedSlider(
          label: 'العرض',
          value: image.width,
          min: 0.08,
          onChanged: (value) =>
              _updateDesignerImage(index, image.copyWith(width: value)),
        ),
        _buildNormalizedSlider(
          label: 'الارتفاع',
          value: image.height,
          min: 0.08,
          onChanged: (value) =>
              _updateDesignerImage(index, image.copyWith(height: value)),
        ),
      ],
    );
  }

  Widget _buildDesignerFieldsControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'حقول البيانات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _cardTemplate.fields.length; i++)
          _buildDesignerFieldTile(i, _cardTemplate.fields[i]),
      ],
    );
  }

  Widget _buildDesignerFieldTile(int index, CardDataFieldElement field) {
    final label = CardFieldKeys.arabicLabel(field.fieldKey);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      leading: Switch(
        value: field.visible,
        onChanged: (value) =>
            _updateDesignerField(index, field.copyWith(visible: value)),
      ),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      children: [
        DropdownButtonFormField<CardLabelMode>(
          value: field.labelMode,
          decoration: const InputDecoration(
            labelText: 'عنوان الحقل',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          items: CardLabelMode.values
              .map(
                (mode) => DropdownMenuItem(
                  value: mode,
                  child: Text(mode.arabicLabel),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            _updateDesignerField(index, field.copyWith(labelMode: value));
          },
        ),
        _buildNormalizedSlider(
          label: 'الموضع الأفقي',
          value: field.x,
          onChanged: (value) =>
              _updateDesignerField(index, field.copyWith(x: value)),
        ),
        _buildNormalizedSlider(
          label: 'الموضع الرأسي',
          value: field.y,
          onChanged: (value) =>
              _updateDesignerField(index, field.copyWith(y: value)),
        ),
        _buildNormalizedSlider(
          label: 'العرض',
          value: field.width,
          min: 0.08,
          onChanged: (value) =>
              _updateDesignerField(index, field.copyWith(width: value)),
        ),
        _buildScalarSlider(
          label: 'حجم الخط',
          value: field.fontSize,
          min: CardTemplate.minTextSize,
          max: CardTemplate.maxTextSize,
          divisions: 21,
          onChanged: (value) =>
              _updateDesignerField(index, field.copyWith(fontSize: value)),
        ),
        Row(
          children: [
            const Text('لون النص'),
            const SizedBox(width: 12),
            Expanded(
              child: _buildColorSwatches(
                selectedColor: field.color,
                onSelected: (color) =>
                    _updateDesignerField(index, field.copyWith(color: color)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFixedTextControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'النصوص الثابتة',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              tooltip: 'إضافة نص ثابت',
              onPressed: () => _showFixedTextDialog(),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (_cardTemplate.fixedTexts.isEmpty)
          Text(
            'لا توجد نصوص ثابتة',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        for (var i = 0; i < _cardTemplate.fixedTexts.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_cardTemplate.fixedTexts[i].text),
            subtitle: Text(
              'حجم ${_cardTemplate.fixedTexts[i].fontSize.round()}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'تعديل',
                  onPressed: () => _showFixedTextDialog(index: i),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'حذف',
                  onPressed: () {
                    final fixedTexts = [..._cardTemplate.fixedTexts]
                      ..removeAt(i);
                    setState(
                      () => _cardTemplate = _cardTemplate.copyWith(
                        fixedTexts: fixedTexts,
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNormalizedSlider({
    required String label,
    required double value,
    double min = 0,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label),
            const Spacer(),
            SizedBox(
              width: 72,
              child: TextFormField(
                key: ValueKey('$label-${(value * 100).round()}'),
                initialValue: (value * 100).round().toString(),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  suffixText: '%',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (text) {
                  final number = double.tryParse(text.trim());
                  if (number == null) return;
                  onChanged((number / 100).clamp(min, 1).toDouble());
                },
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, 1).toDouble(),
          min: min,
          max: 1,
          divisions: 100,
          label: '${(value * 100).round()}%',
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildScalarSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    double? inputMax,
    int? divisions,
    String suffix = '',
    required ValueChanged<double> onChanged,
  }) {
    final displayValue = value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label),
            const Spacer(),
            SizedBox(
              width: 78,
              child: TextFormField(
                key: ValueKey('$label-$displayValue-$suffix'),
                initialValue: displayValue,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  suffixText: suffix.isEmpty ? null : suffix,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: const OutlineInputBorder(),
                ),
                onFieldSubmitted: (text) {
                  final number = double.tryParse(text.trim());
                  if (number == null) return;
                  onChanged(number.clamp(min, inputMax ?? max).toDouble());
                },
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          label: displayValue,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildColorSwatches({
    required int selectedColor,
    required ValueChanged<int> onSelected,
  }) {
    const colors = [
      0xFF000000,
      0xFF374151,
      0xFF6B7280,
      0xFFFFFFFF,
      0xFF7F1D1D,
      0xFFDC2626,
      0xFFF97316,
      0xFFF59E0B,
      0xFF854D0E,
      0xFFEAB308,
      0xFF365314,
      0xFF16A34A,
      0xFF15803D,
      0xFF0F766E,
      0xFF14B8A6,
      0xFF0891B2,
      0xFF0284C7,
      0xFF1D4ED8,
      0xFF1A237E,
      0xFF4F46E5,
      0xFF6D28D9,
      0xFF7E22CE,
      0xFFA21CAF,
      0xFFDB2777,
      0xFFE11D48,
      0xFFC5A059,
      0xFFFDE68A,
      0xFFBFDBFE,
      0xFFBBF7D0,
      0xFFFBCFE8,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final swatch in colors)
          InkWell(
            onTap: () => onSelected(swatch),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Color(swatch),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selectedColor == swatch
                      ? const Color(0xFF1A237E)
                      : Colors.grey.shade300,
                  width: 2,
                ),
                boxShadow: selectedColor == swatch
                    ? const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: selectedColor == swatch
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: swatch == 0xFFFFFFFF ? Colors.black : Colors.white,
                    )
                  : null,
            ),
          ),
      ],
    );
  }

  double _designerFontSliderMax(double value) {
    return value > 140 ? value.clamp(140, CardTemplate.maxTextSize) : 140;
  }

  Widget _buildTextAlignControl({
    required CardTextAlign value,
    required ValueChanged<CardTextAlign> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SegmentedButton<CardTextAlign>(
        segments: const [
          ButtonSegment(
            value: CardTextAlign.right,
            icon: Icon(Icons.format_align_right),
          ),
          ButtonSegment(
            value: CardTextAlign.center,
            icon: Icon(Icons.format_align_center),
          ),
          ButtonSegment(
            value: CardTextAlign.left,
            icon: Icon(Icons.format_align_left),
          ),
        ],
        selected: {value},
        onSelectionChanged: (values) => onChanged(values.first),
      ),
    );
  }

  Widget _buildColorControl({
    required int selectedColor,
    required ValueChanged<int> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => _showAdvancedColorPicker(
                initialColor: selectedColor,
                onSelected: onSelected,
              ),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 46,
                height: 34,
                decoration: BoxDecoration(
                  color: Color(selectedColor),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade400),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                key: ValueKey('hex_$selectedColor'),
                initialValue: _colorToHex(selectedColor),
                decoration: const InputDecoration(
                  labelText: 'HEX / RGB',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (value) {
                  final parsed = _parseColorInput(value);
                  if (parsed != null) onSelected(parsed);
                },
              ),
            ),
            IconButton(
              tooltip: 'اختيار لون',
              onPressed: () => _showAdvancedColorPicker(
                initialColor: selectedColor,
                onSelected: onSelected,
              ),
              icon: const Icon(Icons.palette_outlined),
            ),
            IconButton(
              tooltip: 'التقاط من البطاقة',
              onPressed: () {
                setState(() => _pendingColorPick = onSelected);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'اضغط على أي نقطة داخل البطاقة لالتقاط اللون',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.colorize),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildColorSwatches(
          selectedColor: selectedColor,
          onSelected: onSelected,
        ),
      ],
    );
  }

  void _handlePreviewPointerDown(PointerDownEvent event) {
    if (_pendingColorPick != null) {
      _handleColorPickPointer(event);
      return;
    }
    final local = _previewLocalPosition(event.position);
    final size = _previewSize;
    if (local == null || size == null) return;
    final hitLayer = _layerIdAtPreviewPosition(local, size);
    if (hitLayer != null) return;
    _designerFocusNode.requestFocus();
    setState(() {
      _selectionDragStart = local;
      _selectionDragCurrent = local;
    });
  }

  void _handlePreviewPointerMove(PointerMoveEvent event) {
    if (_selectionDragStart == null) return;
    final local = _previewLocalPosition(event.position);
    final size = _previewSize;
    if (local == null || size == null) return;
    setState(() {
      _selectionDragCurrent = Offset(
        local.dx.clamp(0, size.width).toDouble(),
        local.dy.clamp(0, size.height).toDouble(),
      );
    });
  }

  void _handlePreviewPointerUp(PointerUpEvent event) {
    final start = _selectionDragStart;
    final current = _selectionDragCurrent;
    final size = _previewSize;
    if (start == null || current == null || size == null) {
      _clearSelectionDrag();
      return;
    }
    final rect = Rect.fromPoints(start, current);
    if (rect.width.abs() < 4 && rect.height.abs() < 4) {
      _clearSelectionDrag();
      return;
    }
    final selected = _layerIdsIntersectingPreviewRect(rect, size);
    setState(() {
      _selectedDesignerElementIds
        ..clear()
        ..addAll(selected);
      _selectedDesignerElementId = selected.isEmpty ? null : selected.last;
      _selectionDragStart = null;
      _selectionDragCurrent = null;
    });
  }

  void _clearSelectionDrag() {
    if (_selectionDragStart == null && _selectionDragCurrent == null) return;
    setState(() {
      _selectionDragStart = null;
      _selectionDragCurrent = null;
    });
  }

  Widget _buildSelectionDragOverlay() {
    final rect = Rect.fromPoints(_selectionDragStart!, _selectionDragCurrent!);
    return Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0x221A237E),
            border: Border.all(color: const Color(0xFF1A237E), width: 1),
          ),
        ),
      ),
    );
  }

  Size? get _previewSize {
    final context = _designerPreviewKey.currentContext;
    final boundary = context?.findRenderObject() as RenderBox?;
    return boundary?.size;
  }

  Offset? _previewLocalPosition(Offset globalPosition) {
    final context = _designerPreviewKey.currentContext;
    final boundary = context?.findRenderObject() as RenderBox?;
    return boundary?.globalToLocal(globalPosition);
  }

  String? _layerIdAtPreviewPosition(Offset local, Size size) {
    final normalized = Offset(local.dx / size.width, local.dy / size.height);
    for (final layerId in _cardTemplate.normalizedLayerOrder.reversed) {
      if (_isDesignerElementLocked(layerId)) continue;
      final rect = _normalizedLayerRect(layerId);
      if (rect != null && rect.contains(normalized)) return layerId;
    }
    return null;
  }

  List<String> _layerIdsIntersectingPreviewRect(Rect selection, Size size) {
    final normalizedSelection = Rect.fromLTRB(
      selection.left / size.width,
      selection.top / size.height,
      selection.right / size.width,
      selection.bottom / size.height,
    );
    final selected = <String>[];
    for (final layerId in _cardTemplate.normalizedLayerOrder) {
      if (_isDesignerElementLocked(layerId)) continue;
      final rect = _normalizedLayerRect(layerId);
      if (rect != null && rect.overlaps(normalizedSelection)) {
        selected.add(layerId);
      }
    }
    return selected;
  }

  Rect? _normalizedLayerRect(String layerId) {
    if (layerId == 'background') return null;
    if (layerId == 'barcode') {
      final barcode = _cardTemplate.barcode;
      return Rect.fromLTWH(barcode.x, barcode.y, barcode.width, barcode.height);
    }
    final parts = layerId.split(':');
    if (parts.length != 2) return null;
    final index = int.tryParse(parts[1]);
    if (index == null) return null;
    if (parts.first == 'field' &&
        index >= 0 &&
        index < _cardTemplate.fields.length) {
      final field = _cardTemplate.fields[index];
      if (!field.visible) return null;
      return Rect.fromLTWH(field.x, field.y, field.width, field.height);
    }
    if (parts.first == 'image' &&
        index >= 0 &&
        index < _cardTemplate.imageElements.length) {
      final image = _cardTemplate.imageElements[index];
      return Rect.fromLTWH(image.x, image.y, image.width, image.height);
    }
    if (parts.first == 'fixed' &&
        index >= 0 &&
        index < _cardTemplate.fixedTexts.length) {
      final fixed = _cardTemplate.fixedTexts[index];
      return Rect.fromLTWH(fixed.x, fixed.y, fixed.width, fixed.height);
    }
    return null;
  }

  Future<void> _showAdvancedColorPicker({
    required int initialColor,
    required ValueChanged<int> onSelected,
  }) async {
    var hsv = HSVColor.fromColor(Color(initialColor));
    var current = Color(initialColor);
    final hexController = TextEditingController(
      text: _colorToHex(initialColor),
    );
    final rController = TextEditingController(
      text: _colorChannel(current, 'r').toString(),
    );
    final gController = TextEditingController(
      text: _colorChannel(current, 'g').toString(),
    );
    final bController = TextEditingController(
      text: _colorChannel(current, 'b').toString(),
    );

    void syncControllers(Color color) {
      hexController.text = _colorToHex(color.toARGB32());
      rController.text = _colorChannel(color, 'r').toString();
      gController.text = _colorChannel(color, 'g').toString();
      bController.text = _colorChannel(color, 'b').toString();
    }

    final result = await showDialog<int>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            void setColor(Color color) {
              setDialogState(() {
                current = color;
                hsv = HSVColor.fromColor(color);
                syncControllers(color);
              });
            }

            void applyRgb() {
              final r = int.tryParse(rController.text);
              final g = int.tryParse(gController.text);
              final b = int.tryParse(bController.text);
              if (r == null || g == null || b == null) return;
              setColor(
                Color.fromARGB(
                  255,
                  r.clamp(0, 255).toInt(),
                  g.clamp(0, 255).toInt(),
                  b.clamp(0, 255).toInt(),
                ),
              );
            }

            return AlertDialog(
              title: const Text('Color Picker'),
              content: SizedBox(
                width: 560,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 1.35,
                            child: _HueSaturationValueBox(
                              hsv: hsv,
                              onChanged: (next) => setColor(next.toColor()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        SizedBox(
                          width: 34,
                          height: 240,
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Slider(
                              value: hsv.hue,
                              min: 0,
                              max: 360,
                              onChanged: (value) =>
                                  setColor(hsv.withHue(value).toColor()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          children: [
                            Container(
                              width: 74,
                              height: 54,
                              decoration: BoxDecoration(
                                color: current,
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() => _pendingColorPick = onSelected);
                              },
                              icon: const Icon(Icons.colorize),
                              label: const Text('قطارة'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: hexController,
                      decoration: const InputDecoration(
                        labelText: 'HEX',
                        prefixText: '#',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (value) {
                        final parsed = _parseColorInput(value);
                        if (parsed != null) setColor(Color(parsed));
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _rgbField('R', rController, applyRgb)),
                        const SizedBox(width: 8),
                        Expanded(child: _rgbField('G', gController, applyRgb)),
                        const SizedBox(width: 8),
                        Expanded(child: _rgbField('B', bController, applyRgb)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, current.toARGB32()),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        ),
      ),
    );
    hexController.dispose();
    rController.dispose();
    gController.dispose();
    bController.dispose();
    if (result != null) onSelected(result);
  }

  Widget _rgbField(
    String label,
    TextEditingController controller,
    VoidCallback applyRgb,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onSubmitted: (_) => applyRgb(),
    );
  }

  String _colorToHex(int color) {
    return color.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  }

  int _colorChannel(Color color, String channel) {
    return switch (channel) {
      'r' => (color.r * 255).round().clamp(0, 255).toInt(),
      'g' => (color.g * 255).round().clamp(0, 255).toInt(),
      'b' => (color.b * 255).round().clamp(0, 255).toInt(),
      _ => (color.a * 255).round().clamp(0, 255).toInt(),
    };
  }

  int? _parseColorInput(String input) {
    final text = input.trim();
    final rgb = RegExp(
      r'^rgb\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)$',
      caseSensitive: false,
    ).firstMatch(text);
    if (rgb != null) {
      final r = int.parse(rgb.group(1)!).clamp(0, 255).toInt();
      final g = int.parse(rgb.group(2)!).clamp(0, 255).toInt();
      final b = int.parse(rgb.group(3)!).clamp(0, 255).toInt();
      return Color.fromARGB(255, r, g, b).toARGB32();
    }
    final clean = text.replaceFirst('#', '').replaceFirst('0x', '');
    final value = int.tryParse(clean, radix: 16);
    if (value == null) return null;
    if (clean.length <= 6) return 0xFF000000 | value;
    return value;
  }

  Future<void> _handleColorPickPointer(PointerDownEvent event) async {
    final target = _pendingColorPick;
    if (target == null) return;
    final context = _designerPreviewKey.currentContext;
    if (context == null) return;
    final boundary = context.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final local = boundary.globalToLocal(event.position);
    if (local.dx < 0 ||
        local.dy < 0 ||
        local.dx > boundary.size.width ||
        local.dy > boundary.size.height) {
      return;
    }

    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final imageWidth = image.width;
    image.dispose();
    if (data == null) return;

    final x = local.dx.clamp(0, boundary.size.width - 1).round();
    final y = local.dy.clamp(0, boundary.size.height - 1).round();
    final offset = (y * imageWidth + x) * 4;
    final r = data.getUint8(offset);
    final g = data.getUint8(offset + 1);
    final b = data.getUint8(offset + 2);
    final a = data.getUint8(offset + 3);
    final picked = Color.fromARGB(a, r, g, b).toARGB32();
    setState(() => _pendingColorPick = null);
    target(picked);
  }

  void _updateDesignerField(int index, CardDataFieldElement field) {
    final fields = [..._cardTemplate.fields];
    fields[index] = field;
    _replaceDesignerTemplate(_cardTemplate.copyWith(fields: fields));
  }

  void _updateDesignerImage(int index, CardImageElement image) {
    final images = [..._cardTemplate.imageElements];
    images[index] = image;
    _replaceDesignerTemplate(_cardTemplate.copyWith(imageElements: images));
  }

  void _updateFixedText(int index, CardFixedTextElement fixedText) {
    final fixedTexts = [..._cardTemplate.fixedTexts];
    fixedTexts[index] = fixedText;
    _replaceDesignerTemplate(_cardTemplate.copyWith(fixedTexts: fixedTexts));
  }

  void _toggleDesignerLayer(String layerId) {
    if (layerId == 'background') {
      final nextOpacity = _cardTemplate.backgroundOpacity == 0 ? 1.0 : 0.0;
      _replaceDesignerTemplate(
        _cardTemplate.copyWith(backgroundOpacity: nextOpacity),
      );
      return;
    }

    if (layerId == 'barcode') {
      _replaceDesignerTemplate(
        _cardTemplate.copyWith(
          barcode: _cardTemplate.barcode.copyWith(
            visible: !_cardTemplate.barcode.visible,
          ),
        ),
        selectedElementId: layerId,
      );
      return;
    }

    final parts = layerId.split(':');
    if (parts.length != 2) return;
    final index = int.tryParse(parts[1]);
    if (index == null) return;

    if (parts.first == 'field' &&
        index >= 0 &&
        index < _cardTemplate.fields.length) {
      final field = _cardTemplate.fields[index];
      _updateDesignerField(index, field.copyWith(visible: !field.visible));
    } else if (parts.first == 'image' &&
        index >= 0 &&
        index < _cardTemplate.imageElements.length) {
      final image = _cardTemplate.imageElements[index];
      _updateDesignerImage(index, image.copyWith(visible: !image.visible));
    } else if (parts.first == 'fixed' &&
        index >= 0 &&
        index < _cardTemplate.fixedTexts.length) {
      final fixed = _cardTemplate.fixedTexts[index];
      _updateFixedText(index, fixed.copyWith(visible: !fixed.visible));
    }
  }

  void _toggleDesignerLayerLock(String layerId) {
    if (layerId == 'barcode') {
      final nextLocked = !_cardTemplate.barcode.locked;
      _replaceDesignerTemplate(
        _cardTemplate.copyWith(
          barcode: _cardTemplate.barcode.copyWith(locked: nextLocked),
        ),
      );
      if (nextLocked) {
        setState(() {
          _selectedDesignerElementIds.remove(layerId);
          if (_selectedDesignerElementId == layerId) {
            _selectedDesignerElementId = _selectedDesignerElementIds.isEmpty
                ? null
                : _selectedDesignerElementIds.last;
          }
        });
      }
      return;
    }

    final parts = layerId.split(':');
    if (parts.length != 2) return;
    final index = int.tryParse(parts[1]);
    if (index == null) return;

    if (parts.first == 'field' &&
        index >= 0 &&
        index < _cardTemplate.fields.length) {
      final field = _cardTemplate.fields[index];
      _updateDesignerField(index, field.copyWith(locked: !field.locked));
    } else if (parts.first == 'image' &&
        index >= 0 &&
        index < _cardTemplate.imageElements.length) {
      final image = _cardTemplate.imageElements[index];
      _updateDesignerImage(index, image.copyWith(locked: !image.locked));
    } else if (parts.first == 'fixed' &&
        index >= 0 &&
        index < _cardTemplate.fixedTexts.length) {
      final fixed = _cardTemplate.fixedTexts[index];
      _updateFixedText(index, fixed.copyWith(locked: !fixed.locked));
    }

    if (_isDesignerElementLocked(layerId)) {
      setState(() {
        _selectedDesignerElementIds.remove(layerId);
        if (_selectedDesignerElementId == layerId) {
          _selectedDesignerElementId = _selectedDesignerElementIds.isEmpty
              ? null
              : _selectedDesignerElementIds.last;
        }
      });
    }
  }

  void _deleteDesignerLayer(String layerId) {
    final parts = layerId.split(':');
    if (parts.length != 2) return;
    final index = int.tryParse(parts[1]);
    if (index == null) return;

    if (parts.first == 'image' &&
        index >= 0 &&
        index < _cardTemplate.imageElements.length) {
      final images = [..._cardTemplate.imageElements]..removeAt(index);
      setState(() {
        _cardTemplate = _cardTemplate.copyWith(imageElements: images);
        _selectedDesignerElementId = null;
      });
    } else if (parts.first == 'fixed' &&
        index >= 0 &&
        index < _cardTemplate.fixedTexts.length) {
      final fixedTexts = [..._cardTemplate.fixedTexts]..removeAt(index);
      setState(() {
        _cardTemplate = _cardTemplate.copyWith(fixedTexts: fixedTexts);
        _selectedDesignerElementId = null;
      });
    }
  }

  void _moveLayerOrder(String layerId, int direction) {
    if (layerId == 'background') return;
    final order = _cardTemplate.normalizedLayerOrder;
    final index = order.indexOf(layerId);
    if (index < 0) return;
    final newIndex = (index + direction).clamp(0, order.length - 1).toInt();
    if (newIndex == index) return;
    final nextOrder = [...order];
    final item = nextOrder.removeAt(index);
    nextOrder.insert(newIndex, item);
    _replaceDesignerTemplate(
      _cardTemplate.copyWith(layerOrder: nextOrder),
      selectedElementId: layerId,
    );
  }

  void _moveDesignerElement(String elementId, Offset normalizedDelta) {
    final movingIds = _selectedDesignerElementIds.contains(elementId)
        ? _selectedDesignerElementIds
        : <String>{elementId};
    setState(() {
      _selectedDesignerElementId = elementId;
      _cardTemplate = movingIds.fold<CardTemplate>(
        _cardTemplate,
        (template, id) => _isDesignerElementLocked(id)
            ? template
            : _updatedMovedTemplate(id, normalizedDelta, template),
      );
    });
  }

  void _startDesignerDrag(String elementId) {
    if (_captureDragUndo || _isDesignerElementLocked(elementId)) return;
    _pushDesignerUndo();
    _captureDragUndo = true;
  }

  KeyEventResult _handleDesignerKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (FocusManager.instance.primaryFocus != _designerFocusNode) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyZ) {
      _undoDesignerChange();
      return KeyEventResult.handled;
    }
    final selectedIds = _selectedDesignerElementIds.isEmpty
        ? {if (_selectedDesignerElementId != null) _selectedDesignerElementId!}
        : _selectedDesignerElementIds;
    if (selectedIds.isEmpty) return KeyEventResult.ignored;

    final step = HardwareKeyboard.instance.isShiftPressed ? 0.02 : 0.005;
    final key = event.logicalKey;
    final delta = switch (key) {
      LogicalKeyboardKey.arrowLeft => Offset(-step, 0),
      LogicalKeyboardKey.arrowRight => Offset(step, 0),
      LogicalKeyboardKey.arrowUp => Offset(0, -step),
      LogicalKeyboardKey.arrowDown => Offset(0, step),
      _ => Offset.zero,
    };
    if (delta == Offset.zero) return KeyEventResult.ignored;
    _pushDesignerUndo();
    for (final selected in selectedIds) {
      _moveDesignerElement(selected, delta);
    }
    return KeyEventResult.handled;
  }

  void _resizeDesignerElement(String elementId, Offset normalizedDelta) {
    if (!_captureDragUndo) {
      _pushDesignerUndo();
      _captureDragUndo = true;
    }
    setState(() {
      _selectedDesignerElementId = elementId;
      _cardTemplate = _updatedResizedTemplate(elementId, normalizedDelta);
    });
  }

  CardTemplate _updatedMovedTemplate(
    String elementId,
    Offset delta, [
    CardTemplate? source,
  ]) {
    final template = source ?? _cardTemplate;
    if (elementId == 'barcode') {
      final barcode = template.barcode;
      return template.copyWith(
        barcode: barcode.copyWith(
          x: _clampPosition(barcode.x + delta.dx, barcode.width),
          y: _clampPosition(barcode.y + delta.dy, barcode.height),
        ),
      );
    }

    final parts = elementId.split(':');
    if (parts.length != 2) return template;
    final index = int.tryParse(parts[1]);
    if (index == null) return template;

    if (parts[0] == 'field' && index >= 0 && index < template.fields.length) {
      final field = template.fields[index];
      final fields = [...template.fields];
      fields[index] = field.copyWith(
        x: _clampPosition(field.x + delta.dx, field.width),
        y: _clampPosition(field.y + delta.dy, field.height),
      );
      return template.copyWith(fields: fields);
    }
    if (parts[0] == 'image' &&
        index >= 0 &&
        index < template.imageElements.length) {
      final image = template.imageElements[index];
      final images = [...template.imageElements];
      images[index] = image.copyWith(
        x: _clampPosition(image.x + delta.dx, image.width),
        y: _clampPosition(image.y + delta.dy, image.height),
      );
      return template.copyWith(imageElements: images);
    }
    if (parts[0] == 'fixed' &&
        index >= 0 &&
        index < template.fixedTexts.length) {
      final fixed = template.fixedTexts[index];
      final fixedTexts = [...template.fixedTexts];
      fixedTexts[index] = fixed.copyWith(
        x: _clampPosition(fixed.x + delta.dx, fixed.width),
        y: _clampPosition(fixed.y + delta.dy, fixed.height),
      );
      return template.copyWith(fixedTexts: fixedTexts);
    }
    return template;
  }

  CardTemplate _updatedResizedTemplate(String elementId, Offset delta) {
    if (elementId == 'barcode') {
      final barcode = _cardTemplate.barcode;
      return _cardTemplate.copyWith(
        barcode: barcode.copyWith(
          width: _clampSize(barcode.width + delta.dx, barcode.x, min: 0.10),
          height: _clampSize(barcode.height + delta.dy, barcode.y, min: 0.08),
        ),
      );
    }

    final parts = elementId.split(':');
    if (parts.length != 2) return _cardTemplate;
    final index = int.tryParse(parts[1]);
    if (index == null) return _cardTemplate;

    if (parts[0] == 'field' &&
        index >= 0 &&
        index < _cardTemplate.fields.length) {
      final field = _cardTemplate.fields[index];
      final fields = [..._cardTemplate.fields];
      final nextWidth = _clampSize(field.width + delta.dx, field.x, min: 0.08);
      final nextHeight = _clampSize(
        field.height + delta.dy,
        field.y,
        min: 0.05,
      );
      fields[index] = field.copyWith(
        width: nextWidth,
        height: nextHeight,
        fontSize: _fontSizeForResizedBox(
          field.fontSize,
          field.width,
          field.height,
          nextWidth,
          nextHeight,
        ),
      );
      return _cardTemplate.copyWith(fields: fields);
    }
    if (parts[0] == 'image' &&
        index >= 0 &&
        index < _cardTemplate.imageElements.length) {
      final image = _cardTemplate.imageElements[index];
      final images = [..._cardTemplate.imageElements];
      images[index] = image.copyWith(
        width: _clampSize(image.width + delta.dx, image.x, min: 0.08),
        height: _clampSize(image.height + delta.dy, image.y, min: 0.08),
      );
      return _cardTemplate.copyWith(imageElements: images);
    }
    if (parts[0] == 'fixed' &&
        index >= 0 &&
        index < _cardTemplate.fixedTexts.length) {
      final fixed = _cardTemplate.fixedTexts[index];
      final fixedTexts = [..._cardTemplate.fixedTexts];
      final nextWidth = _clampSize(fixed.width + delta.dx, fixed.x, min: 0.10);
      final nextHeight = _clampSize(
        fixed.height + delta.dy,
        fixed.y,
        min: 0.05,
      );
      fixedTexts[index] = fixed.copyWith(
        width: nextWidth,
        height: nextHeight,
        fontSize: _fontSizeForResizedBox(
          fixed.fontSize,
          fixed.width,
          fixed.height,
          nextWidth,
          nextHeight,
        ),
      );
      return _cardTemplate.copyWith(fixedTexts: fixedTexts);
    }
    return _cardTemplate;
  }

  double _clampPosition(double value, double size) {
    return value.clamp(0.0, (1.0 - size).clamp(0.0, 1.0)).toDouble();
  }

  double _clampSize(double value, double position, {required double min}) {
    return value.clamp(min, (1.0 - position).clamp(min, 1.0)).toDouble();
  }

  double _fontSizeForResizedBox(
    double current,
    double oldWidth,
    double oldHeight,
    double newWidth,
    double newHeight,
  ) {
    if (oldWidth <= 0 || oldHeight <= 0) return current;
    final scale = (newWidth / oldWidth + newHeight / oldHeight) / 2;
    return (current * scale)
        .clamp(CardTemplate.minTextSize, CardTemplate.maxTextSize)
        .toDouble();
  }

  Future<void> _addDesignerImageElement() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;
    Uint8List? bytes = result.files.single.bytes;
    final path = result.files.single.path;
    if (bytes == null && path != null) bytes = await File(path).readAsBytes();
    if (bytes == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر قراءة الصورة'),
            backgroundColor: Colors.red,
          ),
        );
      return;
    }
    final images = [
      ..._cardTemplate.imageElements,
      CardImageElement(
        imageBase64: base64Encode(bytes),
        x: 0.10,
        y: 0.10,
        width: 0.20,
        height: 0.20,
      ),
    ];
    _replaceDesignerTemplate(
      _cardTemplate.copyWith(
        imageElements: images,
        layerOrder: [
          ..._cardTemplate.normalizedLayerOrder,
          'image:${images.length - 1}',
        ],
      ),
      selectedElementId: 'image:${images.length - 1}',
    );
  }

  Future<void> _pickDesignerBackground() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;
    Uint8List? bytes = result.files.single.bytes;
    final path = result.files.single.path;
    if (bytes == null && path != null) bytes = await File(path).readAsBytes();
    if (bytes == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر قراءة صورة الخلفية'),
            backgroundColor: Colors.red,
          ),
        );
      return;
    }
    final backgroundImageBase64 = base64Encode(bytes);
    setState(
      () => _cardTemplate = _cardTemplate.copyWith(
        backgroundImageBase64: backgroundImageBase64,
      ),
    );
  }

  void _deleteDesignerBackground() {
    setState(
      () => _cardTemplate = _cardTemplate.copyWith(clearBackgroundImage: true),
    );
  }

  Future<void> _saveDesignerTemplate() async {
    _syncActiveDesignerSide();
    final errors = [
      ..._frontCardTemplate.validate(),
      if (_printBackSide) ..._backCardTemplate.validate(),
    ];
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.first), backgroundColor: Colors.red),
      );
      return;
    }
    await ref
        .read(settingsRepositoryProvider)
        .saveActiveCardTemplate(_frontCardTemplate);
    await ref
        .read(settingsRepositoryProvider)
        .saveSetting('id_card_back_template', _backCardTemplate.toJsonString());
    await _saveSetting('id_card_print_back', _printBackSide.toString());
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ قالب الكارنيه'),
          backgroundColor: Colors.green,
        ),
      );
  }

  Future<void> _resetDesignerTemplate() async {
    final defaultTemplate = _isDesigningBackSide
        ? _defaultBackCardTemplate()
        : CardTemplate.defaults();
    _replaceDesignerTemplate(
      defaultTemplate,
      selectedElementId: defaultTemplate.normalizedLayerOrder.firstOrNull,
    );
    if (_isDesigningBackSide) {
      await ref
          .read(settingsRepositoryProvider)
          .deleteSetting('id_card_back_template');
    } else {
      await ref.read(settingsRepositoryProvider).deleteActiveCardTemplate();
    }
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت استعادة القالب الافتراضي'),
          backgroundColor: Colors.orange,
        ),
      );
  }

  Future<void> _showFixedTextDialog({int? index}) async {
    final existing = index == null ? null : _cardTemplate.fixedTexts[index];
    final textController = TextEditingController(text: existing?.text ?? '');
    double x = existing?.x ?? 0.10;
    double y = existing?.y ?? 0.10;
    double width = existing?.width ?? 0.50;
    double fontSize = existing?.fontSize ?? 12;
    int color = existing?.color ?? 0xFF111111;
    String? errorText;

    final result = await showDialog<CardFixedTextElement>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(index == null ? 'إضافة نص ثابت' : 'تعديل نص ثابت'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      labelText: 'النص',
                      errorText: errorText,
                    ),
                  ),
                  _buildDialogSlider(
                    label: 'الموضع الأفقي',
                    value: x,
                    onChanged: (value) => setDialogState(() => x = value),
                  ),
                  _buildDialogSlider(
                    label: 'الموضع الرأسي',
                    value: y,
                    onChanged: (value) => setDialogState(() => y = value),
                  ),
                  _buildDialogSlider(
                    label: 'العرض',
                    value: width,
                    min: 0.10,
                    onChanged: (value) => setDialogState(() => width = value),
                  ),
                  Slider(
                    value: fontSize,
                    min: CardTemplate.minTextSize,
                    max: CardTemplate.maxTextSize,
                    divisions: 21,
                    label: fontSize.round().toString(),
                    onChanged: (value) =>
                        setDialogState(() => fontSize = value),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('الألوان'),
                  ),
                  const SizedBox(height: 8),
                  _buildColorSwatches(
                    selectedColor: color,
                    onSelected: (swatch) =>
                        setDialogState(() => color = swatch),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  final text = textController.text.trim();
                  if (text.isEmpty) {
                    setDialogState(() => errorText = 'الرجاء إدخال النص');
                    return;
                  }
                  Navigator.pop(
                    context,
                    CardFixedTextElement(
                      text: text,
                      x: x,
                      y: y,
                      width: width,
                      fontSize: fontSize,
                      color: color,
                    ),
                  );
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );
    textController.dispose();

    if (result == null) return;
    final fixedTexts = [..._cardTemplate.fixedTexts];
    if (index == null) {
      fixedTexts.add(result);
    } else {
      fixedTexts[index] = result;
    }
    _replaceDesignerTemplate(
      _cardTemplate.copyWith(
        fixedTexts: fixedTexts,
        layerOrder: index == null
            ? [
                ..._cardTemplate.normalizedLayerOrder,
                'fixed:${fixedTexts.length - 1}',
              ]
            : _cardTemplate.normalizedLayerOrder,
      ),
      selectedElementId: index == null
          ? 'fixed:${fixedTexts.length - 1}'
          : 'fixed:$index',
    );
  }

  Widget _buildDialogSlider({
    required String label,
    required double value,
    double min = 0,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label),
            const Spacer(),
            Text('${(value * 100).round()}%'),
          ],
        ),
        Slider(
          value: value.clamp(min, 1).toDouble(),
          min: min,
          max: 1,
          divisions: 100,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSettingsPanel() {
    if (_isDesignerMode) return _buildDesignerPanel();

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildCardModeSwitch(),
            const SizedBox(height: 12),
            Text(
              'إعدادات الكارنيه',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),

            // Logo Section
            const Text(
              'اللوجو (شعار الخدمة)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _logoBytes != null
                    ? Image.memory(_logoBytes!, fit: BoxFit.contain)
                    : const Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickLogo,
                  icon: const Icon(Icons.upload),
                  label: const Text('اختيار'),
                ),
                if (_logoBytes != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _deleteLogo,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'مسح اللوجو',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),

            const Text(
              'خلفية وجه الكارنيه',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 150,
                height: 90,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: _backgroundBytes == null
                    ? const Icon(Icons.wallpaper, size: 42, color: Colors.grey)
                    : Opacity(
                        opacity: _backgroundOpacity,
                        child: Image.memory(
                          _backgroundBytes!,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickBackground,
                  icon: const Icon(Icons.upload, size: 16),
                  label: const Text('اختيار خلفية'),
                ),
                if (_backgroundBytes != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _deleteBackground,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'مسح الخلفية',
                  ),
                ],
              ],
            ),
            Row(
              children: [
                const Text('الشفافية'),
                Expanded(
                  child: Slider(
                    value: _backgroundOpacity,
                    min: 0,
                    max: 1,
                    divisions: 20,
                    label: '${(_backgroundOpacity * 100).round()}%',
                    onChanged: _backgroundBytes == null
                        ? null
                        : (value) => setState(() => _backgroundOpacity = value),
                    onChangeEnd: (value) => _saveSetting(
                      'id_card_background_opacity',
                      value.toString(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text('${(_backgroundOpacity * 100).round()}%'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),

            // Back Side Section
            SwitchListTile(
              title: const Text(
                'طباعة ظهر الكارنيه',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              value: _printBackSide,
              onChanged: (val) {
                setState(() => _printBackSide = val);
                _saveSetting('id_card_print_back', val.toString());
              },
            ),
            if (_printBackSide) ...[
              const SizedBox(height: 8),
              const Text(
                'لوجو الظهر',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _backLogoBytes != null
                      ? Image.memory(_backLogoBytes!, fit: BoxFit.contain)
                      : const Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickBackLogo,
                    icon: const Icon(Icons.upload, size: 16),
                    label: const Text('اختيار'),
                  ),
                  if (_backLogoBytes != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _deleteBackLogo,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'مسح لوجو الظهر',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'خلفية ظهر الكارنيه',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 150,
                  height: 90,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _backBackgroundBytes == null
                      ? const Icon(
                          Icons.wallpaper,
                          size: 42,
                          color: Colors.grey,
                        )
                      : Opacity(
                          opacity: _backBackgroundOpacity,
                          child: Image.memory(
                            _backBackgroundBytes!,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickBackBackground,
                    icon: const Icon(Icons.upload, size: 16),
                    label: const Text('اختيار خلفية الظهر'),
                  ),
                  if (_backBackgroundBytes != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _deleteBackBackground,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'مسح خلفية الظهر',
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  const Text('شفافية الخلفية'),
                  Expanded(
                    child: Slider(
                      value: _backBackgroundOpacity,
                      min: 0,
                      max: 1,
                      divisions: 20,
                      label: '${(_backBackgroundOpacity * 100).round()}%',
                      onChanged: _backBackgroundBytes == null
                          ? null
                          : (value) =>
                                setState(() => _backBackgroundOpacity = value),
                      onChangeEnd: (value) => _saveSetting(
                        'id_card_back_background_opacity',
                        value.toString(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text('${(_backBackgroundOpacity * 100).round()}%'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _backTopTextController,
                decoration: const InputDecoration(
                  labelText: 'النص العلوي',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _backBottomTextController,
                decoration: const InputDecoration(
                  labelText: 'النص السفلي',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Divider(),

            // Fields Selection
            const Text(
              'البيانات المعروضة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _buildCheckbox(_getLabel('name', 'الاسم'), 'name'),
            _buildCheckbox('الكود', 'code'),
            _buildCheckbox(_getLabel('stage', 'المرحلة'), 'stage'),
            _buildCheckbox(_getLabel('khoros', 'الخورس'), 'khoros'),
            _buildCheckbox(_getLabel('area', 'المنطقة'), 'area'),
            _buildCheckbox(_getLabel('father', 'أب الاعتراف'), 'father'),
            _buildCheckbox(_getLabel('phone', 'تليفون'), 'phone'),
            _buildCheckbox(_getLabel('mobile', 'موبايل'), 'mobile'),
            _buildCheckbox(_getLabel('street', 'العنوان'), 'street'),
            _buildCheckbox('عرض صورة المخدوم', 'photo'),
            _buildCheckbox(_getLabel('rohot', 'الرهط'), 'rohot'),
            const SizedBox(height: 16),
            const Divider(),

            // Code Type Settings
            const Text(
              'نوع الكود',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _codeType,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'barcode',
                  child: Text('باركود شريطي (Barcode)'),
                ),
                DropdownMenuItem(
                  value: 'qr',
                  child: Text('كود مربع (QR Code)'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _codeType = val);
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<CardBarcodeBackgroundMode>(
              value: _simpleCodeBackgroundMode,
              decoration: const InputDecoration(
                labelText: 'خلفية الكود',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: CardBarcodeBackgroundMode.values
                  .map(
                    (mode) => DropdownMenuItem(
                      value: mode,
                      child: Text(mode.arabicLabel),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _simpleCodeBackgroundMode = value);
                _saveSetting('id_card_simple_code_background', value.value);
              },
            ),
            SwitchListTile(
              title: const Text('طباعة أسماء الحقول'),
              value: _simpleShowFieldLabels,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() => _simpleShowFieldLabels = value);
                _saveSetting('id_card_simple_show_labels', value.toString());
              },
            ),
            const SizedBox(height: 16),
            const Divider(),

            // Grid Settings
            const Text(
              'توزيع الصفحة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _colsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'الأعمدة (العدد بالعرض)',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _rowsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'الصفوف (العدد بالطول)',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateCards,
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(
                  _isGenerating ? 'جاري التجهيز...' : 'إصدار الكارنيهات',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(String title, String key) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      value: _visibleFields[key] ?? false,
      dense: true,
      contentPadding: EdgeInsets.zero,
      onChanged: (val) {
        setState(() => _visibleFields[key] = val == true);
        _saveSetting('id_card_show_$key', (val == true).toString());
      },
    );
  }

  Widget _buildSelectionPanel() {
    bool allSelected =
        _allFetchedPersons.isNotEmpty &&
        _selectedPersonIds.length == _allFetchedPersons.length;

    final isNarrow = MediaQuery.of(context).size.width < 800;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isNarrow) ...[
              TextField(
                decoration: const InputDecoration(
                  labelText: 'بحث بالاسم، التليفون، العنوان...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) {
                  _searchQuery = v;
                  _fetchPersons();
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildStageFilter()),
                  const SizedBox(width: 8),
                  Expanded(child: _buildAreaFilter()),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'بحث بالاسم، التليفون، العنوان...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (v) {
                        _searchQuery = v;
                        _fetchPersons();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: _buildStageFilter()),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: _buildAreaFilter()),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: _allFetchedPersons.isEmpty
                  ? const Center(
                      child: Text(
                        'لا يوجد نتائج',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: CheckboxListTile(
                                  title: Text(
                                    'تحديد الكل (${_allFetchedPersons.length} من $_totalCount)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  value: allSelected,
                                  onChanged: (val) {
                                    if (val == true && _hasMore) {
                                      _showSelectAllOptions();
                                    } else {
                                      setState(() {
                                        if (val == true) {
                                          _selectedPersonIds.addAll(
                                            _allFetchedPersons.map((p) => p.id),
                                          );
                                        } else {
                                          _selectedPersonIds.clear();
                                        }
                                      });
                                    }
                                  },
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              if (_hasMore)
                                TextButton.icon(
                                  onPressed: _fetchAllMatching,
                                  icon: const Icon(Icons.download),
                                  label: const Text('تحميل الكل'),
                                ),
                            ],
                          ),
                        ),
                        const Divider(),
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount:
                                _allFetchedPersons.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _allFetchedPersons.length) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: _isLoading
                                        ? const CircularProgressIndicator()
                                        : TextButton.icon(
                                            onPressed: _loadMore,
                                            icon: const Icon(
                                              Icons.arrow_downward,
                                            ),
                                            label: const Text('عرض المزيد'),
                                          ),
                                  ),
                                );
                              }

                              final p = _allFetchedPersons[index];
                              return CheckboxListTile(
                                title: Text(p.name),
                                subtitle: Text(
                                  '${p.id} | ${p.stageName} | ${p.areaName}',
                                ),
                                value: _selectedPersonIds.contains(p.id),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedPersonIds.add(p.id);
                                    } else {
                                      _selectedPersonIds.remove(p.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageFilter() {
    final stagesAsync = ref.watch(stagesRepositoryProvider);
    final stages = stagesAsync.value ?? [];
    return DropdownButtonFormField<int?>(
      decoration: const InputDecoration(
        labelText: 'تصفية بالمرحلة',
        isDense: true,
      ),
      value: _filterStageId,
      items: [
        const DropdownMenuItem(value: null, child: Text('جميع المراحل')),
        ...stages.map(
          (s) => DropdownMenuItem(value: s.id, child: Text(s.name)),
        ),
      ],
      onChanged: (val) {
        _filterStageId = val;
        _fetchPersons();
      },
    );
  }

  Widget _buildAreaFilter() {
    final areasAsync = ref.watch(areasRepositoryProvider);
    final areas = areasAsync.value ?? [];
    return DropdownButtonFormField<int?>(
      decoration: const InputDecoration(
        labelText: 'تصفية بالمنطقة',
        isDense: true,
      ),
      value: _filterAreaId,
      items: [
        const DropdownMenuItem(value: null, child: Text('جميع المناطق')),
        ...areas.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
      ],
      onChanged: (val) {
        _filterAreaId = val;
        _fetchPersons();
      },
    );
  }
}

class _HueSaturationValueBox extends StatelessWidget {
  const _HueSaturationValueBox({required this.hsv, required this.onChanged});

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final selector = Offset(
          hsv.saturation * width,
          (1 - hsv.value) * height,
        );
        return GestureDetector(
          onPanDown: (details) => _update(details.localPosition, width, height),
          onPanUpdate: (details) =>
              _update(details.localPosition, width, height),
          child: CustomPaint(
            painter: _HueSaturationValuePainter(
              hue: hsv.hue,
              selector: selector,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }

  void _update(Offset local, double width, double height) {
    final saturation = (local.dx / width).clamp(0.0, 1.0);
    final value = (1 - local.dy / height).clamp(0.0, 1.0);
    onChanged(hsv.withSaturation(saturation).withValue(value));
  }
}

class _HueSaturationValuePainter extends CustomPainter {
  const _HueSaturationValuePainter({required this.hue, required this.selector});

  final double hue;
  final Offset selector;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, hueColor],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
    canvas.drawCircle(selector, 8, Paint()..color = Colors.white);
    canvas.drawCircle(
      selector,
      8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.black87,
    );
  }

  @override
  bool shouldRepaint(covariant _HueSaturationValuePainter oldDelegate) {
    return oldDelegate.hue != hue || oldDelegate.selector != selector;
  }
}
