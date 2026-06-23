import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:printing/printing.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../database/database.dart';
import '../database/database_provider.dart';
import '../models/person_option.dart';
import '../repositories/tayo_repository.dart';
import '../repositories/services_repository.dart';
import '../services/tayo_card_pdf_generator.dart';
import '../services/tayo_report_pdf_generator.dart';
import '../ui/dialogs/sorting_dialog.dart';
import '../services/auth_service.dart';

// ─── Main Tayo Screen ──────────────────────────────────

class TayoScreen extends ConsumerStatefulWidget {
  const TayoScreen({super.key});
  @override
  ConsumerState<TayoScreen> createState() => _TayoScreenState();
}

class _TayoScreenState extends ConsumerState<TayoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          // ─ Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withOpacity(0.85)],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.card_giftcard, color: cs.onPrimary, size: 28),
                    const SizedBox(width: 10),
                    Text('الطايو', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onPrimary)),
                  ],
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  tabs: const [
                    Tab(icon: Icon(Icons.credit_card), text: 'إدارة الكروت'),
                    Tab(icon: Icon(Icons.add_circle_outline), text: 'إضافة نقاط'),
                    Tab(icon: Icon(Icons.assessment), text: 'التقارير'),
                  ],
                ),
              ],
            ),
          ),
          // ─ Body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _CardsManagementTab(),
                _PointsEntryTab(),
                _ReportsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// TAB 1: Cards Management
// ═══════════════════════════════════════════════════════

class _CardsManagementTab extends ConsumerStatefulWidget {
  const _CardsManagementTab();
  @override
  ConsumerState<_CardsManagementTab> createState() => _CardsManagementTabState();
}

class _CardsManagementTabState extends ConsumerState<_CardsManagementTab> {
  String _printCodeType = 'qr';
  final _colsController = TextEditingController(text: '3');
  final _rowsController = TextEditingController(text: '4');

  bool _printBackSide = false;
  final _backTopTextController = TextEditingController();
  final _backBottomTextController = TextEditingController();
  Uint8List? _backLogoBytes;

  @override
  void initState() {
    super.initState();
    _loadPrintSettings();
  }

  Future<void> _loadPrintSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
       _printCodeType = prefs.getString('tayo_print_code_type') ?? 'qr';
       _colsController.text = prefs.getString('tayo_print_cols') ?? '3';
       _rowsController.text = prefs.getString('tayo_print_rows') ?? '4';
       _printBackSide = prefs.getBool('tayo_print_back_side') ?? false;
       _backTopTextController.text = prefs.getString('tayo_back_top_text') ?? '';
       _backBottomTextController.text = prefs.getString('tayo_back_bottom_text') ?? '';
       final logoBase64 = prefs.getString('tayo_back_logo_base64');
       if (logoBase64 != null) {
         _backLogoBytes = base64Decode(logoBase64);
       }
    });
    
    _backTopTextController.addListener(_savePrintSettings);
    _backBottomTextController.addListener(_savePrintSettings);
    _colsController.addListener(_savePrintSettings);
    _rowsController.addListener(_savePrintSettings);
  }

  Future<void> _savePrintSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tayo_print_code_type', _printCodeType);
    await prefs.setString('tayo_print_cols', _colsController.text);
    await prefs.setString('tayo_print_rows', _rowsController.text);
    await prefs.setBool('tayo_print_back_side', _printBackSide);
    await prefs.setString('tayo_back_top_text', _backTopTextController.text);
    await prefs.setString('tayo_back_bottom_text', _backBottomTextController.text);
    if (_backLogoBytes != null) {
      await prefs.setString('tayo_back_logo_base64', base64Encode(_backLogoBytes!));
    } else {
      await prefs.remove('tayo_back_logo_base64');
    }
  }

  @override
  void dispose() {
    _colsController.dispose();
    _rowsController.dispose();
    _backTopTextController.dispose();
    _backBottomTextController.dispose();
    super.dispose();
  }

  Future<void> _pickBackLogo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.bytes != null) {
      setState(() => _backLogoBytes = result.files.single.bytes!);
      _savePrintSettings();
    } else if (result != null && result.files.single.path != null) {
       try {
         final file = File(result.files.single.path!);
         final bytes = await file.readAsBytes();
         setState(() => _backLogoBytes = bytes);
         _savePrintSettings();
       } catch(_) {}
    }
  }

  void _deleteBackLogo() {
    setState(() => _backLogoBytes = null);
    _savePrintSettings();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).value;
    final canAdd = user == null || !user.isAdvanced || (user.granularPermissions['tayo']?['add'] ?? false);
    final canEdit = user == null || !user.isAdvanced || (user.granularPermissions['tayo']?['edit'] ?? false);
    final canDelete = user == null || !user.isAdvanced || (user.granularPermissions['tayo']?['delete'] ?? false);

    final cardsAsync = ref.watch(tayoRepositoryProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (cards) => Column(
          children: [
            // Action bar
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: [
                  if (canAdd) FilledButton.icon(
                    onPressed: () => _showCardDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة كارت'),
                  ),
                  if (cards.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => _printCards(cards),
                      icon: const Icon(Icons.print),
                      label: const Text('طباعة الكروت'),
                    ),
                  if (cards.isNotEmpty) ...[
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'qr', label: Text('QR')),
                        ButtonSegment(value: 'barcode', label: Text('باركود')),
                      ],
                      selected: {_printCodeType},
                      onSelectionChanged: (v) {
                        setState(() => _printCodeType = v.first);
                        _savePrintSettings();
                      },
                    ),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _colsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'الأعمدة', isDense: true, border: OutlineInputBorder()),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _rowsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'الصفوف', isDense: true, border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (cards.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: const Text('طباعة ظهر الكارنيه', style: TextStyle(fontWeight: FontWeight.bold)),
                      value: _printBackSide,
                      onChanged: (val) {
                        setState(() => _printBackSide = val ?? false);
                        _savePrintSettings();
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    if (_printBackSide) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _backTopTextController,
                              decoration: const InputDecoration(labelText: 'النص العلوي', isDense: true, border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _backBottomTextController,
                              decoration: const InputDecoration(labelText: 'النص السفلي', isDense: true, border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_backLogoBytes != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.memory(
                                _backLogoBytes!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          ElevatedButton.icon(
                            onPressed: _pickBackLogo,
                            icon: const Icon(Icons.upload, size: 16),
                            label: const Text('لوجو الظهر'),
                          ),
                          if (_backLogoBytes != null)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: _deleteBackLogo,
                              tooltip: 'حذف اللوجو',
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            // Cards grid
            Expanded(
              child: cards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.credit_card_off, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('لا توجد كروت بعد', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (ctx, constraints) {
                        final crossCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);
                        return GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossCount,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: cards.length,
                          itemBuilder: (ctx, i) => _buildCardTile(cards[i], canEdit: canEdit, canDelete: canDelete),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTile(TayoCardDTO card, {required bool canEdit, required bool canDelete}) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showCardDialog(context, card: card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image area
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.3),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: card.cardImage != null && card.cardImage!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        child: Image.memory(Uint8List.fromList(card.cardImage!), fit: BoxFit.cover),
                      )
                    : Center(
                        child: Icon(Icons.image_outlined, size: 48, color: cs.primary.withOpacity(0.4)),
                      ),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${card.cardName} (كود: ${card.cardId})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${card.cardPoints} نقطة',
                        style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (canEdit) IconButton(
                          icon: Icon(Icons.edit, size: 18, color: cs.primary),
                          onPressed: () => _showCardDialog(context, card: card),
                          tooltip: 'تعديل',
                          visualDensity: VisualDensity.compact,
                        ),
                        if (canDelete) IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () => _deleteCard(card),
                          tooltip: 'حذف',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardDialog(BuildContext context, {TayoCardDTO? card}) {
    final nameCtrl = TextEditingController(text: card?.cardName ?? '');
    final pointsCtrl = TextEditingController(text: card?.cardPoints.toString() ?? '');
    Uint8List? imageBytes = card?.cardImage != null ? Uint8List.fromList(card!.cardImage!) : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text(card == null ? 'إضافة كارت جديد' : 'تعديل الكارت'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (card != null) ...[
                      TextField(
                        controller: TextEditingController(text: card.cardId.toString()),
                        readOnly: true,
                        decoration: const InputDecoration(labelText: 'كود الكارت', border: OutlineInputBorder(), filled: true),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'اسم الكارت', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pointsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'عدد النقاط', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    // Image preview + picker
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade100,
                      ),
                      child: imageBytes != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.memory(imageBytes!, fit: BoxFit.contain),
                                ),
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.red,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, size: 14, color: Colors.white),
                                      onPressed: () => setDialogState(() => imageBytes = null),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: TextButton.icon(
                                onPressed: () async {
                                  final picker = ImagePicker();
                                  final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
                                  if (file != null) {
                                    final bytes = await file.readAsBytes();
                                    setDialogState(() => imageBytes = bytes);
                                  }
                                },
                                icon: const Icon(Icons.add_photo_alternate),
                                label: const Text('اختر صورة'),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                FilledButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final pts = int.tryParse(pointsCtrl.text) ?? 0;
                    if (name.isEmpty) return;

                    final repo = ref.read(tayoRepositoryProvider.notifier);
                    if (card == null) {
                      await repo.addCard(name: name, points: pts, image: imageBytes);
                    } else {
                      await repo.updateCard(
                        cardId: card.cardId,
                        name: name,
                        points: pts,
                        image: imageBytes,
                        clearImage: imageBytes == null,
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('حفظ'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _deleteCard(TayoCardDTO card) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل تريد حذف كارت "${card.cardName}"؟\nسيتم حذف جميع سجلات النقاط المرتبطة.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await ref.read(tayoRepositoryProvider.notifier).deleteCard(card.cardId);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  void _printCards(List<TayoCardDTO> cards) async {
    final cols = int.tryParse(_colsController.text) ?? 3;
    final rows = int.tryParse(_rowsController.text) ?? 4;

    try {
      final pdfBytes = await TayoCardPdfGenerator.generateCards(
        cards: cards,
        codeType: _printCodeType,
        cardsPerRow: cols,
        cardsPerCol: rows,
        printBackSide: _printBackSide,
        backLogoBytes: _backLogoBytes,
        backTopText: _backTopTextController.text,
        backBottomText: _backBottomTextController.text,
      );
      if (!mounted) return;
      await Printing.layoutPdf(onLayout: (_) => pdfBytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الطباعة: $e')));
      }
    }
  }
}

// ═══════════════════════════════════════════════════════
// TAB 2: Points Entry
// ═══════════════════════════════════════════════════════

class _PointsEntryTab extends ConsumerStatefulWidget {
  const _PointsEntryTab();
  @override
  ConsumerState<_PointsEntryTab> createState() => _PointsEntryTabState();
}

class _PointsEntryTabState extends ConsumerState<_PointsEntryTab> {
  // Person search
  final _personSearchCtrl = TextEditingController();
  PersonOption? _selectedPerson;
  List<PersonOption> _personOptions = [];

  // Card search
  final _cardSearchCtrl = TextEditingController();
  TayoCardDTO? _selectedCard;
  int _cardQuantity = 1;
  final TextEditingController _cardQuantityCtrl = TextEditingController(text: '1');
  FocusNode? _cardFieldFocus;
  List<TayoCardDTO> _cardOptions = [];

  // Date
  DateTime _selectedDate = DateTime.now();

  // Extra Points toggle
  bool _addExtraPoints = false;
  int _extraPointsAmount = 1;
  final _extraPointsNameCtrl = TextEditingController();

  // Filter controls
  int? _filterStageId;
  int? _filterAreaId;
  DateTime? _filterDateFrom;
  DateTime? _filterDateTo;
  bool _showLogFilters = false;

  // Recent logs
  List<PointLogDTO> _recentLogs = [];

  // Person balance
  int _personBalance = 0;

  // Controllers captured from Autocomplete fieldViewBuilder
  TextEditingController? _personFieldCtrl;
  TextEditingController? _cardFieldCtrl;

  // Processing flag
  bool _isProcessingAward = false;

  @override
  void initState() {
    super.initState();
    _loadPersonOptions();
    _loadRecentLogs();
  }

  @override
  void dispose() {
    _personSearchCtrl.dispose();
    _cardSearchCtrl.dispose();
    _extraPointsNameCtrl.dispose();
    _cardQuantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPersonOptions() async {
    final db = ref.read(appDatabaseProvider);
    final rows = await db.select(db.persons).get();
    setState(() {
      _personOptions = rows
          .map((r) => PersonOption(id: r.personId, name: r.personName ?? ''))
          .toList();
    });
  }

  Future<void> _loadRecentLogs() async {
    final logs = await ref.read(tayoRepositoryProvider.notifier).getPointLogs(
          limit: 50,
          stageId: _filterStageId,
          areaId: _filterAreaId,
          dateFrom: _filterDateFrom,
          dateTo: _filterDateTo,
        );
    setState(() => _recentLogs = logs);
  }

  Future<void> _deleteLog(PointLogDTO log) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف النقاط الخاصة بـ ${log.personName}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(tayoRepositoryProvider.notifier).deletePointLog(log.id);
    _loadRecentLogs();
    if (_selectedPerson?.id == log.personId) {
      _loadPersonBalance();
    }
  }

  Future<void> _editLog(PointLogDTO log, List<TayoCardDTO> allCards) async {
    DateTime editedDate = DateTime.tryParse(log.date) ?? DateTime.now();
    int? editedCardId;
    String editedNotes = log.notes ?? '';
    int editedPoints = log.points;
    
    if (log.cardName != null) {
      try {
        editedCardId = allCards.firstWhere((c) => c.cardName == log.cardName).cardId;
      } catch (_) {}
    } else if (!log.isAttendance) {
      editedCardId = null; 
    }
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
         return StatefulBuilder(builder: (c, setLocalState) {
            final isCustom = (editedCardId == null);
            return AlertDialog(
              title: const Text('تعديل النقاط'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('التاريخ'),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(editedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                         final d = await showDatePicker(
                           context: ctx,
                           initialDate: editedDate,
                           firstDate: DateTime(2020),
                           lastDate: DateTime(2030),
                         );
                         if (d != null) setLocalState(() => editedDate = d);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (!log.isAttendance) ...[
                      DropdownButtonFormField<int?>(
                        value: editedCardId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'الكارت', border: OutlineInputBorder(), isDense: true),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('نقاط مخصصة (إضافية / محددة مسبقاً)')),
                          ...allCards.map((c) => DropdownMenuItem(value: c.cardId, child: Text('${c.cardName} (${c.cardPoints} نقطة)', overflow: TextOverflow.ellipsis))),
                        ],
                        onChanged: (v) {
                          setLocalState(() {
                            editedCardId = v;
                            if (v != null) {
                              try {
                                editedPoints = allCards.firstWhere((c) => c.cardId == v).cardPoints;
                              } catch (_) {}
                            }
                          });
                        },
                      ),
                      if (isCustom) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: editedNotes,
                          decoration: const InputDecoration(labelText: 'البند (السبب)', border: OutlineInputBorder(), isDense: true),
                          onChanged: (v) => editedNotes = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: editedPoints.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'النقاط', border: OutlineInputBorder(), isDense: true),
                          onChanged: (v) => editedPoints = int.tryParse(v) ?? 1,
                        ),
                      ]
                    ]
                  ]
                )
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                FilledButton(
                  onPressed: () {
                    if (isCustom && editedNotes.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('الرجاء كتابة البند / الملاحظة')));
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                  child: const Text('تحديث'),
                ),
              ],
            );
         });
      },
    );

    if (confirm != true) return;
    
    // Check if switching off specific custom notes by switching to a card
    final isNowCustom = (editedCardId == null);
    
    await ref.read(tayoRepositoryProvider.notifier).updatePointLog(
      logId: log.id,
      date: DateFormat('yyyy-MM-dd').format(editedDate),
      cardId: editedCardId,
      points: editedPoints,
      notes: isNowCustom ? editedNotes.trim() : null,
      clearNotes: !isNowCustom, 
    );
    _loadRecentLogs();
    if (_selectedPerson?.id == log.personId) {
      _loadPersonBalance();
    }
  }

  Future<void> _loadPersonBalance() async {
    if (_selectedPerson == null) return;
    final bal = await ref.read(tayoRepositoryProvider.notifier).getPersonTotalPoints(_selectedPerson!.id ?? 0);
    setState(() => _personBalance = bal);
  }

  Future<void> _awardPoints() async {
    if (_isProcessingAward) return;
    _isProcessingAward = true;

    try {
      if (_selectedPerson == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر مخدوم أولاً')));
        return;
      }
      if (_selectedCard == null && !_addExtraPoints) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر كارت أو فعّل إضافة نقاط إضافية')));
        return;
      }

      final repo = ref.read(tayoRepositoryProvider.notifier);
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // Add card points
      if (_selectedCard != null) {
        final err = await repo.addPointsToPerson(
          personId: _selectedPerson!.id ?? 0,
          cardId: _selectedCard!.cardId,
          points: _selectedCard!.cardPoints * _cardQuantity,
          date: dateStr,
          notes: _cardQuantity > 1 ? 'الكمية: $_cardQuantity' : null,
        );
        if (err != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
          return;
        }
      }

      // Add Extra points
      if (_addExtraPoints) {
        final reason = _extraPointsNameCtrl.text.trim();
        if (reason.isEmpty) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء كتابة البند / الملاحظة للـ نقاط الإضافية')));
          return;
        }
        // Use cardId = 0 for extra points
        await repo.addPointsToPerson(
          personId: _selectedPerson!.id ?? 0,
          cardId: 0,
          points: _extraPointsAmount,
          date: dateStr,
          isAttendance: false,
          notes: reason,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ تم إضافة النقاط لـ ${_selectedPerson!.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 1000),
          ),
        );
      }

      // Reset
      setState(() {
        _selectedCard = null;
        _cardQuantity = 1;
        _cardQuantityCtrl.text = '1';
        _cardSearchCtrl.clear();
        
        // Force Autocomplete widget internal state to reset fully
        _cardFieldCtrl?.text = ' '; 
        _cardFieldCtrl?.clear();
        
        _extraPointsNameCtrl.clear();
        _addExtraPoints = false;
      });

      // Refocus on card field
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
           _cardFieldFocus?.unfocus();
           Future.delayed(const Duration(milliseconds: 50), () {
             if (mounted) {
               _cardFieldFocus?.requestFocus();
             }
           });
        }
      });

      _loadPersonBalance();
      _loadRecentLogs();
    } finally {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _isProcessingAward = false;
        });
      } else {
        _isProcessingAward = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).value;
    final canAdd = user == null || !user.isAdvanced || (user.granularPermissions['tayo']?['add'] ?? false);
    final canEdit = user == null || !user.isAdvanced || (user.granularPermissions['tayo']?['edit'] ?? false);
    final canDelete = user == null || !user.isAdvanced || (user.granularPermissions['tayo']?['delete'] ?? false);

    final cs = Theme.of(context).colorScheme;
    final cardsAsync = ref.watch(tayoRepositoryProvider);
    final allCards = cardsAsync.asData?.value ?? [];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final isWide = constraints.maxWidth > 700;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Entry Form ──
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('إضافة نقاط لمخدوم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.primary)),
                        const Divider(),
                        // Person search
                        Autocomplete<PersonOption>(
                          optionsBuilder: (textEditVal) {
                            if (textEditVal.text.isEmpty) return const Iterable.empty();
                            final q = textEditVal.text.toLowerCase().trim();
                            final intQ = int.tryParse(q);
                            return _personOptions.where((p) {
                              final idMatch = p.id.toString() == q || (intQ != null && p.id == intQ);
                              return p.name.toLowerCase().contains(q) || idMatch;
                            });
                          },
                          displayStringForOption: (p) => '${p.name} (${p.id})',
                          fieldViewBuilder: (ctx, ctrl, fn, onSubmit) {
                            _personFieldCtrl = ctrl;
                            return TextField(
                              controller: ctrl,
                              focusNode: fn,
                              onTap: () {
                                if (!fn.hasFocus) fn.requestFocus();
                                ctrl.text = ctrl.text; 
                              },
                              decoration: InputDecoration(
                                labelText: 'بحث بالاسم أو الكود',
                                prefixIcon: const Icon(Icons.person_search),
                                border: const OutlineInputBorder(),
                                suffixIcon: ctrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          ctrl.clear();
                                          setState(() {
                                            _selectedPerson = null;
                                            _personBalance = 0;
                                          });
                                        },
                                      )
                                    : null,
                              ),
                            );
                          },
                          onSelected: (p) {
                            setState(() => _selectedPerson = p);
                            _loadPersonBalance();
                          },
                        ),
                        if (_selectedPerson != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.person, color: cs.primary),
                                const SizedBox(width: 8),
                                Text('${_selectedPerson!.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: cs.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'الرصيد: $_personBalance',
                                    style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Card search
                        Autocomplete<TayoCardDTO>(
                          optionsBuilder: (textEditVal) {
                            if (textEditVal.text.isEmpty) return allCards;
                            final q = textEditVal.text.toLowerCase().trim();
                            final intQ = int.tryParse(q);
                            return allCards.where((c) =>
                                c.cardName.toLowerCase().contains(q) ||
                                c.cardId.toString() == q ||
                                (intQ != null && c.cardId == intQ));
                          },
                          displayStringForOption: (c) => '${c.cardName} (${c.cardPoints} نقطة)',
                          fieldViewBuilder: (ctx, ctrl, fn, onSubmit) {
                            _cardFieldCtrl = ctrl;
                            _cardFieldFocus = fn;
                            return TextField(
                              controller: ctrl,
                              focusNode: fn,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) {
                                if (_selectedCard == null) {
                                  final q = ctrl.text.toLowerCase().trim();
                                  final intQ = int.tryParse(q);
                                  try {
                                    final exactMatch = allCards.firstWhere((c) => 
                                        c.cardId.toString() == q || 
                                        c.cardName.toLowerCase() == q ||
                                        (intQ != null && c.cardId == intQ));
                                    setState(() => _selectedCard = exactMatch);
                                  } catch (_) {}
                                }
                                onSubmit();
                                Future.delayed(const Duration(milliseconds: 100), () => _awardPoints());
                              },
                              onTap: () {
                                if (!fn.hasFocus) fn.requestFocus();
                                ctrl.text = ctrl.text;
                              },
                              decoration: const InputDecoration(
                                labelText: 'اسم الكارت أو الكود',
                                prefixIcon: Icon(Icons.credit_card),
                                border: OutlineInputBorder(),
                              ),
                            );
                          },
                          onSelected: (c) {
                            if (_selectedCard?.cardId == c.cardId) {
                               setState(() {
                                 _cardQuantity++;
                                 _cardQuantityCtrl.text = _cardQuantity.toString();
                               });
                            } else {
                               setState(() {
                                 _selectedCard = c;
                                 _cardQuantity = 1;
                                 _cardQuantityCtrl.text = '1';
                               });
                            }
                            // Auto trigger submit when card selected via Enter or tap
                            Future.delayed(const Duration(milliseconds: 100), () => _awardPoints());
                          },
                        ),
                        if (_selectedCard != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Chip(
                                  avatar: Icon(Icons.stars, color: Colors.amber.shade700, size: 18),
                                  label: Text('${_selectedCard!.cardName} — ${_selectedCard!.cardPoints} نقطة'),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () => setState(() {
                                    _selectedCard = null;
                                    _cardQuantity = 1;
                                    _cardQuantityCtrl.text = '1';
                                  }),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 18),
                                      onPressed: () {
                                        if (_cardQuantity > 1) {
                                          setState(() {
                                            _cardQuantity--;
                                            _cardQuantityCtrl.text = _cardQuantity.toString();
                                          });
                                        }
                                      },
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      padding: EdgeInsets.zero,
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: TextField(
                                        controller: _cardQuantityCtrl,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                                        ),
                                        onChanged: (v) {
                                          final val = int.tryParse(v);
                                          if (val != null && val > 0) {
                                            _cardQuantity = val;
                                          }
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _cardQuantity++;
                                          _cardQuantityCtrl.text = _cardQuantity.toString();
                                        });
                                      },
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Date & Attendance row
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Date picker
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) setState(() => _selectedDate = picked);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16),
                                    const SizedBox(width: 6),
                                    Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                                  ],
                                ),
                              ),
                            ),
                            // Extra points toggle
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: _addExtraPoints,
                                  onChanged: (v) => setState(() => _addExtraPoints = v),
                                ),
                                const Text('إضافة نقاط إضافية'),
                              ],
                            ),
                            if (_addExtraPoints) ...[
                              SizedBox(
                                width: 140,
                                child: TextField(
                                  controller: _extraPointsNameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'البند (السبب)',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'النقاط',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  controller: TextEditingController(text: '$_extraPointsAmount'),
                                  onChanged: (v) => _extraPointsAmount = int.tryParse(v) ?? 1,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Save button
                        if (canAdd) SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _awardPoints,
                            icon: const Icon(Icons.add_task),
                            label: const Text('إضافة النقاط', style: TextStyle(fontSize: 15)),
                            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // ── Filters for log ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => setState(() => _showLogFilters = !_showLogFilters),
                          child: Row(
                            children: [
                              Icon(Icons.filter_list, color: cs.primary, size: 20),
                              const SizedBox(width: 8),
                              Text('تصفية وعرض السجلات (بحث)', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
                              const Spacer(),
                              Icon(_showLogFilters ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: cs.primary),
                            ],
                          ),
                        ),
                        if (_showLogFilters) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildStageFilter(),
                              _buildAreaFilter(),
                              _buildDateFilter('تاريخ البداية', _filterDateFrom, (d) => setState(() => _filterDateFrom = d)),
                              _buildDateFilter('تاريخ النهاية', _filterDateTo, (d) => setState(() => _filterDateTo = d)),
                              FilledButton.tonalIcon(
                                onPressed: _loadRecentLogs,
                                icon: const Icon(Icons.search, size: 18),
                                label: const Text('عرض'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // ── Recent log list ──
                if (_recentLogs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text('لا توجد سجلات', style: TextStyle(color: Colors.grey.shade500)),
                    ),
                  )
                else
                  ..._recentLogs.map((log) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: log.isAttendance ? Colors.green.shade100 : cs.primaryContainer,
                            child: Icon(
                              log.isAttendance ? Icons.check_circle : Icons.card_giftcard,
                              color: log.isAttendance ? Colors.green : cs.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(log.personName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(log.isAttendance ? 'نقاط حضور' : (log.cardName ?? log.notes ?? 'نقاط إضافية')),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('+${log.points}', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary, fontSize: 16)),
                                  Text(log.date, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(width: 8),
                              if (canEdit) IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                onPressed: () => _editLog(log, allCards),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                              ),
                              if (canDelete) IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => _deleteLog(log),
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                              ),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStageFilter() {
    final db = ref.watch(appDatabaseProvider);
    return FutureBuilder<List<Stage>>(
      future: db.select(db.stages).get(),
      builder: (ctx, snap) {
        final stages = snap.data ?? [];
        return SizedBox(
          width: 150,
          child: DropdownButtonFormField<int?>(
            value: _filterStageId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'المرحلة', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
            items: [
              const DropdownMenuItem(value: null, child: Text('الكل')),
              ...stages.map((s) => DropdownMenuItem(value: s.stageId, child: Text(s.stageName ?? '', overflow: TextOverflow.ellipsis))),
            ],
            onChanged: (v) => setState(() => _filterStageId = v),
          ),
        );
      },
    );
  }

  Widget _buildAreaFilter() {
    final db = ref.watch(appDatabaseProvider);
    return FutureBuilder<List<Area>>(
      future: db.select(db.areas).get(),
      builder: (ctx, snap) {
        final areas = snap.data ?? [];
        return SizedBox(
          width: 150,
          child: DropdownButtonFormField<int?>(
            value: _filterAreaId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'المنطقة', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
            items: [
              const DropdownMenuItem(value: null, child: Text('الكل')),
              ...areas.map((a) => DropdownMenuItem(value: a.areaId, child: Text(a.areaName ?? '', overflow: TextOverflow.ellipsis))),
            ],
            onChanged: (v) => setState(() => _filterAreaId = v),
          ),
        );
      },
    );
  }

  Widget _buildDateFilter(String label, DateTime? current, ValueChanged<DateTime?> onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: current ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event, size: 16),
            const SizedBox(width: 4),
            Text(current != null ? DateFormat('yyyy-MM-dd').format(current) : label),
            if (current != null)
              InkWell(
                onTap: () => onChanged(null),
                child: const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.close, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// TAB 3: Reports
// ═══════════════════════════════════════════════════════

class _ReportsTab extends ConsumerStatefulWidget {
  const _ReportsTab();
  @override
  ConsumerState<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends ConsumerState<_ReportsTab> {
  int? _stageId;
  int? _areaId;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _ascending = false;
  bool _includeAttendancePoints = false;
  List<int> _selectedServiceIds = [];
  List<PersonPointsDTO> _results = [];
  bool _loading = false;
  String _presetLabel = '';

  void _setPreset(String label, DateTime from, DateTime to) {
    setState(() {
      _presetLabel = label;
      _dateFrom = from;
      _dateTo = to;
    });
  }

  void _search() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(tayoRepositoryProvider.notifier).getPointsReport(
            stageId: _stageId,
            areaId: _areaId,
            dateFrom: _dateFrom,
            dateTo: _dateTo,
            ascending: _ascending,
            includeAttendance: _includeAttendancePoints,
            attendanceServiceIds: _selectedServiceIds.isNotEmpty ? _selectedServiceIds : null,
          );
      setState(() => _results = data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
    setState(() => _loading = false);
  }

  void _exportPdf() async {
    if (_results.isEmpty) return;

    final uniqueCards = <String>{};
    for (final r in _results) {
      uniqueCards.addAll(r.cardPoints.keys);
    }
    
    final initialColumns = [
      ReportColumn(id: '#', title: '#'),
      ReportColumn(id: 'الاسم', title: 'الاسم'),
      ReportColumn(id: 'المرحلة', title: 'المرحلة'),
      ReportColumn(id: 'المنطقة', title: 'المنطقة'),
      ReportColumn(id: 'إجمالي النقاط', title: 'إجمالي النقاط'),
      ReportColumn(id: 'نقاط الحضور', title: 'نقاط الحضور', isSelected: false),
      ReportColumn(id: 'نقاط الطايو', title: 'نقاط الطايو', isSelected: false),
    ];
    for (final c in uniqueCards) {
      initialColumns.add(ReportColumn(id: c, title: c, isSelected: false));
    }

    final selectedCols = await showDialog<List<String>>(
      context: context,
      builder: (c) => _TayoColumnsDialog(columns: initialColumns),
    );

    if (selectedCols == null || selectedCols.isEmpty) return;

    final dateRange = _dateFrom != null && _dateTo != null
        ? 'من ${DateFormat('yyyy-MM-dd').format(_dateFrom!)} إلى ${DateFormat('yyyy-MM-dd').format(_dateTo!)}'
        : null;
    final pdfBytes = await TayoReportPdfGenerator.generateReport(
      data: _results,
      title: 'تقرير نقاط الطايو',
      dateRange: dateRange,
      columns: selectedCols,
    );
    if (!mounted) return;
    await Printing.layoutPdf(onLayout: (_) => pdfBytes);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Filters ──
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الفلاتر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cs.primary)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildStageDropdown(),
                        _buildAreaDropdown(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Date range
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _buildDateBtn('من', _dateFrom, (d) => setState(() => _dateFrom = d)),
                        _buildDateBtn('إلى', _dateTo, (d) => setState(() => _dateTo = d)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Presets
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _presetChip('هذا الأسبوع', () {
                          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                          _setPreset('هذا الأسبوع', startOfWeek, now);
                        }),
                        _presetChip('هذا الشهر', () {
                          _setPreset('هذا الشهر', DateTime(now.year, now.month, 1), now);
                        }),
                        _presetChip('هذه السنة', () {
                          _setPreset('هذه السنة', DateTime(now.year, 1, 1), now);
                        }),
                        _presetChip('الكل', () {
                          setState(() {
                            _presetLabel = 'الكل';
                            _dateFrom = null;
                            _dateTo = null;
                          });
                        }),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: const Text('إضافة نقاط الحضور في هذه الفترة إلى التقرير', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      value: _includeAttendancePoints,
                      onChanged: (val) => setState(() {
                        _includeAttendancePoints = val;
                        if (!val) _selectedServiceIds.clear();
                      }),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    if (_includeAttendancePoints)
                      _buildServiceSelector(),
                    const Divider(),
                    // Sort toggle + search
                    Row(
                      children: [
                        const Text('الترتيب: '),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text('تنازلي ↓')),
                            ButtonSegment(value: true, label: Text('تصاعدي ↑')),
                          ],
                          selected: {_ascending},
                          onSelectionChanged: (v) => setState(() => _ascending = v.first),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: _search,
                          icon: const Icon(Icons.search),
                          label: const Text('بحث'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Action bar
            if (_results.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text('${_results.length} نتيجة', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _exportPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('تصدير PDF'),
                    ),
                  ],
                ),
              ),
            // ── Results ──
            if (_loading)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else if (_results.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.assessment_outlined, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('اضغط بحث لعرض النتائج', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(_results.length, (i) {
                final r = _results[i];
                final rank = i + 1;
                Color? rankColor;
                if (rank == 1) rankColor = Colors.amber.shade700;
                if (rank == 2) rankColor = Colors.grey.shade600;
                if (rank == 3) rankColor = Colors.brown.shade400;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: rankColor?.withOpacity(0.2) ?? cs.primaryContainer,
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: rankColor ?? cs.primary,
                        ),
                      ),
                    ),
                    title: Text(r.personName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text([r.stageName, r.areaName].where((s) => s != null && s.isNotEmpty).join(' • ')),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${r.totalPoints}',
                        style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSelector() {
    final servicesAsync = ref.watch(servicesRepositoryProvider);
    final services = servicesAsync.asData?.value ?? [];
    if (services.isEmpty) return const Text('لا توجد خدمات معرّفة بعد', style: TextStyle(color: Colors.grey, fontSize: 12));
    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('اختر الخدمات:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        Wrap(spacing: 8, children: services.map((s) => FilterChip(
          label: Text('${s.name} (${s.dayName})', style: const TextStyle(fontSize: 11)),
          selected: _selectedServiceIds.contains(s.id),
          onSelected: (v) => setState(() { if (v) _selectedServiceIds.add(s.id); else _selectedServiceIds.remove(s.id); }),
        )).toList()),
      ]),
    );
  }

  Widget _buildStageDropdown() {
    final db = ref.watch(appDatabaseProvider);
    return FutureBuilder<List<Stage>>(
      future: db.select(db.stages).get(),
      builder: (ctx, snap) {
        final stages = snap.data ?? [];
        return SizedBox(
          width: 160,
          child: DropdownButtonFormField<int?>(
            value: _stageId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'المرحلة', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
            items: [
              const DropdownMenuItem(value: null, child: Text('الكل')),
              ...stages.map((s) => DropdownMenuItem(value: s.stageId, child: Text(s.stageName ?? '', overflow: TextOverflow.ellipsis))),
            ],
            onChanged: (v) => setState(() => _stageId = v),
          ),
        );
      },
    );
  }

  Widget _buildAreaDropdown() {
    final db = ref.watch(appDatabaseProvider);
    return FutureBuilder<List<Area>>(
      future: db.select(db.areas).get(),
      builder: (ctx, snap) {
        final areas = snap.data ?? [];
        return SizedBox(
          width: 160,
          child: DropdownButtonFormField<int?>(
            value: _areaId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'المنطقة', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
            items: [
              const DropdownMenuItem(value: null, child: Text('الكل')),
              ...areas.map((a) => DropdownMenuItem(value: a.areaId, child: Text(a.areaName ?? '', overflow: TextOverflow.ellipsis))),
            ],
            onChanged: (v) => setState(() => _areaId = v),
          ),
        );
      },
    );
  }

  Widget _buildDateBtn(String label, DateTime? current, ValueChanged<DateTime?> onPicked) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: current ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 14),
            const SizedBox(width: 4),
            Text(current != null ? '$label: ${DateFormat('yyyy-MM-dd').format(current)}' : label),
            if (current != null)
              InkWell(
                onTap: () => onPicked(null),
                child: const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.close, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(String label, VoidCallback onTap) {
    final isActive = _presetLabel == label;
    return ActionChip(
      label: Text(label),
      backgroundColor: isActive ? Theme.of(context).colorScheme.primary.withOpacity(0.15) : null,
      side: isActive ? BorderSide(color: Theme.of(context).colorScheme.primary) : null,
      onPressed: onTap,
    );
  }
}

class _TayoColumnsDialog extends StatefulWidget {
  final List<ReportColumn> columns;
  const _TayoColumnsDialog({required this.columns});

  @override
  State<_TayoColumnsDialog> createState() => _TayoColumnsDialogState();
}

class _TayoColumnsDialogState extends State<_TayoColumnsDialog> {
  late List<ReportColumn> _columns;

  @override
  void initState() {
    super.initState();
    _columns = List.from(widget.columns);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('اختيار وترتيب الأعمدة للطباعة'),
        content: SizedBox(
          width: 400,
          height: 450,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('اختر الأعمدة واسحبها لترتيبها من اليمين لليسار في التقرير:', style: TextStyle(color: Colors.grey)),
              ),
              Expanded(
                child: ReorderableListView(
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _columns.removeAt(oldIndex);
                      _columns.insert(newIndex, item);
                    });
                  },
                  children: [
                    for (final col in _columns)
                      CheckboxListTile(
                        key: ValueKey('col_${col.id}'),
                        secondary: const Icon(Icons.drag_handle),
                        title: Text(col.title),
                        value: col.isSelected,
                        onChanged: (val) {
                          setState(() => col.isSelected = val ?? false);
                        },
                        controlAffinity: ListTileControlAffinity.trailing,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final result = _columns.where((c) => c.isSelected).map((c) => c.id).toList();
              Navigator.pop(context, result);
            },
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}
