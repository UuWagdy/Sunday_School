import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../repositories/persons_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/stages_repository.dart';
import '../ui/widgets/multi_select_filter.dart';

class RohotScreen extends ConsumerStatefulWidget {
  const RohotScreen({super.key});

  @override
  ConsumerState<RohotScreen> createState() => _RohotScreenState();
}

class _RohotGroup {
  const _RohotGroup({
    required this.name,
    required this.leader,
    required this.members,
    required this.arifId,
  });

  final String name;
  final String leader;
  final List<PersonListDTO> members;
  final int? arifId;

  Map<String, dynamic> toJson() => {
    'name': name,
    'leader': leader,
    'arifId': arifId,
    'members': members
        .map(
          (person) => {
            'id': person.id,
            'name': person.name,
            'stageName': person.stageName,
            'day': person.day,
            'month': person.month,
            'year': person.year,
          },
        )
        .toList(),
  };

  factory _RohotGroup.fromJson(Map<String, dynamic> json) {
    return _RohotGroup(
      name: json['name'] as String? ?? '',
      leader: json['leader'] as String? ?? '',
      arifId: json['arifId'] as int?,
      members: (json['members'] as List? ?? const []).whereType<Map>().map((
        item,
      ) {
        final map = Map<String, dynamic>.from(item);
        return PersonListDTO(
          id: map['id'] as int? ?? 0,
          name: map['name'] as String? ?? '',
          stageName: map['stageName'] as String? ?? '',
          khorosName: '',
          areaName: '',
          phone: '',
          mobile: '',
          streetName: '',
          fatherName: '',
          day: map['day'] as int?,
          month: map['month'] as int?,
          year: map['year'] as int?,
        );
      }).toList(),
    );
  }
}

class _RohotScreenState extends ConsumerState<RohotScreen> {
  static const _storageKey = 'rohot_groups_json';

  final _groupsCountController = TextEditingController(text: '10');
  final _groupSizeController = TextEditingController(text: '10');
  final _leaderController = TextEditingController();
  final _random = Random();

  List<int> _selectedStageIds = [];
  List<String> _leaders = [];
  List<_RohotGroup> _groups = [];
  bool _loading = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _loadSavedGroups();
  }

  @override
  void dispose() {
    _groupsCountController.dispose();
    _groupSizeController.dispose();
    _leaderController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedGroups() async {
    final raw = await ref
        .read(settingsRepositoryProvider)
        .getSetting(_storageKey);
    if (raw != null && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _groups = decoded
            .whereType<Map>()
            .map(
              (item) => _RohotGroup.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }
    }
    final rawLeaders = await ref
        .read(settingsRepositoryProvider)
        .getSetting('rohot_leaders_json');
    if (rawLeaders != null && rawLeaders.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawLeaders);
        if (decoded is List) {
          _leaders = decoded.cast<String>();
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _persistGroups() async {
    await ref
        .read(settingsRepositoryProvider)
        .saveSetting(
          _storageKey,
          jsonEncode(_groups.map((group) => group.toJson()).toList()),
        );
  }

  Future<void> _persistLeaders() async {
    await ref
        .read(settingsRepositoryProvider)
        .saveSetting(
          'rohot_leaders_json',
          jsonEncode(_leaders),
        );
  }

  void _addLeader() {
    final name = _leaderController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _leaders.add(name);
      _leaderController.clear();
    });
    _persistLeaders();
  }

  int _ageSortValue(PersonListDTO person) {
    final year = person.year ?? 9999;
    final month = person.month ?? 12;
    final day = person.day ?? 31;
    return year * 10000 + month * 100 + day;
  }

  Future<void> _generateGroups() async {
    if (_selectedStageIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر مرحلة واحدة على الأقل')),
      );
      return;
    }
    if (_leaders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف قائدًا واحدًا على الأقل')),
      );
      return;
    }

    setState(() => _generating = true);
    try {
      final persons = await ref
          .read(personsRepositoryProvider.notifier)
          .fetchPersons(
            stageIds: _selectedStageIds,
            limit: null,
            offset: 0,
            includeServices: false,
          );
      if (persons.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يوجد مخدومون في المراحل المختارة')),
        );
        return;
      }

      final requestedCount = int.tryParse(_groupsCountController.text) ?? 1;
      final requestedSize =
          int.tryParse(_groupSizeController.text) ?? persons.length;
      final groupCount = max(
        1,
        min(
          persons.length,
          max(requestedCount, (persons.length / max(1, requestedSize)).ceil()),
        ),
      );

      final shuffled = [...persons]..shuffle(_random);
      final buckets = List.generate(groupCount, (_) => <PersonListDTO>[]);
      for (var i = 0; i < shuffled.length; i++) {
        buckets[i % groupCount].add(shuffled[i]);
      }

      final groups = <_RohotGroup>[];
      for (var i = 0; i < buckets.length; i++) {
        final members = buckets[i]..sort((a, b) => a.name.compareTo(b.name));
        final oldest = [...members]
          ..sort((a, b) => _ageSortValue(a).compareTo(_ageSortValue(b)));
        groups.add(
          _RohotGroup(
            name: 'مجموعة ${i + 1}',
            leader: _leaders[i % _leaders.length],
            members: members,
            arifId: oldest.isEmpty ? null : oldest.first.id,
          ),
        );
      }

      setState(() => _groups = groups);
      await _persistGroups();
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _changeArif(int groupIndex, int? personId) async {
    final group = _groups[groupIndex];
    setState(() {
      _groups[groupIndex] = _RohotGroup(
        name: group.name,
        leader: group.leader,
        members: group.members,
        arifId: personId,
      );
    });
    await _persistGroups();
  }

  Future<void> _swapMembers({
    required int fromGroup,
    required int personId,
    required int toGroup,
  }) async {
    if (fromGroup == toGroup) return;
    final source = _groups[fromGroup];
    final target = _groups[toGroup];
    PersonListDTO? person;
    for (final member in source.members) {
      if (member.id == personId) {
        person = member;
        break;
      }
    }
    if (person == null) return;

    final next = [..._groups];
    final sourceMembers = [...source.members]
      ..removeWhere((p) => p.id == personId);
    final targetMembers = [...target.members, person]
      ..sort((a, b) => a.name.compareTo(b.name));
    next[fromGroup] = _RohotGroup(
      name: source.name,
      leader: source.leader,
      members: sourceMembers,
      arifId: source.arifId == personId ? null : source.arifId,
    );
    next[toGroup] = _RohotGroup(
      name: target.name,
      leader: target.leader,
      members: targetMembers,
      arifId: target.arifId,
    );
    setState(() => _groups = next);
    await _persistGroups();
  }

  Future<void> _renameGroup(int index) async {
    final controller = TextEditingController(text: _groups[index].name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل اسم الرهط'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'اسم الرهط الجديد'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      final oldGroup = _groups[index];
      setState(() {
        _groups[index] = _RohotGroup(
          name: newName,
          leader: oldGroup.leader,
          members: oldGroup.members,
          arifId: oldGroup.arifId,
        );
      });
      await _persistGroups();
    }
  }

  Future<void> _saveRohotToDatabase() async {
    if (_groups.isEmpty) return;

    final stageIds = _groups
        .expand((g) => g.members)
        .map((p) => p.stageId)
        .whereType<int>()
        .toSet()
        .toList();

    final rohotMap = <int, String?>{};
    final leaderMap = <int, String?>{};
    for (final group in _groups) {
      for (final person in group.members) {
        rohotMap[person.id] = group.name;
        leaderMap[person.id] = group.leader;
      }
    }

    setState(() => _generating = true);
    try {
      await ref
          .read(personsRepositoryProvider.notifier)
          .updatePersonsRohot(rohotMap, leaderMap, stageIds);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التقسيم بنجاح في بيانات المخدومين')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _exportPdf() async {
    if (_groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد تقسيم محفوظ للتصدير')),
      );
      return;
    }
    final bytes = await _buildPdf();
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'rohot_groups.pdf',
    );
  }

  Future<Uint8List> _buildPdf() async {
    final regular = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    final bold = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
    final regularFont = pw.Font.ttf(regular);
    final boldFont = pw.Font.ttf(bold);
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          pw.Text(
            'تقسيم الرهوط',
            style: pw.TextStyle(font: boldFont, fontSize: 22),
          ),
          pw.SizedBox(height: 14),
          for (final group in _groups) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              color: const PdfColor.fromInt(0xFFE8EAF6),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      group.name,
                      style: pw.TextStyle(font: boldFont),
                    ),
                  ),
                  pw.Text(
                    'القائد: ${group.leader}',
                    style: pw.TextStyle(font: boldFont),
                  ),
                ],
              ),
            ),
            pw.TableHelper.fromTextArray(
              headers: const ['الكود', 'الاسم', 'الدور', 'المرحلة'],
              data: group.members
                  .map(
                    (person) => [
                      person.id.toString(),
                      person.name,
                      person.id == group.arifId ? 'عريف' : 'مخدوم',
                      person.stageName,
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(font: boldFont),
              cellStyle: pw.TextStyle(font: regularFont, fontSize: 11),
              cellAlignment: pw.Alignment.centerRight,
            ),
            pw.SizedBox(height: 12),
          ],
        ],
      ),
    );
    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    final stagesAsync = ref.watch(stagesRepositoryProvider);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 12),
                    _buildControls(stagesAsync),
                    const SizedBox(height: 12),
                    Expanded(child: _buildGroups()),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final headerText = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الرهوط',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            Text(
              'تقسيم عشوائي محفوظ مع قائد وعريف لكل مجموعة',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        );

        final buttons = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _groups.isEmpty ? null : _saveRohotToDatabase,
              icon: const Icon(Icons.save),
              label: const Text('حفظ التقسيم'),
            ),
            OutlinedButton.icon(
              onPressed: _exportPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('تصدير PDF'),
            ),
          ],
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              headerText,
              const SizedBox(height: 12),
              buttons,
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(child: headerText),
              buttons,
            ],
          );
        }
      },
    );
  }

  Widget _buildControls(AsyncValue<List<StageModel>> stagesAsync) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isMobile = width < 600;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: isMobile ? width : 320,
                      child: stagesAsync.when(
                        data: (stages) => MultiSelectFilter(
                          label: 'المراحل',
                          selectedIds: _selectedStageIds,
                          allItems: stages
                              .map(
                                (stage) =>
                                    SelectableItem(id: stage.id, name: stage.name),
                              )
                              .toList(),
                          hintText: 'اختر المراحل',
                          onChanged: (ids) =>
                              setState(() => _selectedStageIds = ids.cast<int>()),
                        ),
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('تعذر تحميل المراحل: $e'),
                      ),
                    ),
                    SizedBox(
                      width: isMobile ? (width - 12) / 2 : 130,
                      child: TextField(
                        controller: _groupsCountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'عدد المجموعات'),
                      ),
                    ),
                    SizedBox(
                      width: isMobile ? (width - 12) / 2 : 130,
                      child: TextField(
                        controller: _groupSizeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'حجم المجموعة'),
                      ),
                    ),
                    SizedBox(
                      width: isMobile ? width : 220,
                      child: TextField(
                        controller: _leaderController,
                        decoration: const InputDecoration(labelText: 'اسم قائد'),
                        onSubmitted: (_) => _addLeader(),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _addLeader,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('إضافة قائد'),
                    ),
                    FilledButton.icon(
                      onPressed: _generating ? null : _generateGroups,
                      icon: _generating
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.shuffle),
                      label: const Text('تقسيم عشوائي'),
                    ),
                  ],
                ),
                if (_leaders.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final leader in _leaders)
                        Chip(
                          label: Text(leader),
                          onDeleted: () {
                            setState(() => _leaders.remove(leader));
                            _persistLeaders();
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroups() {
    if (_groups.isEmpty) {
      return const Card(child: Center(child: Text('لم يتم إنشاء تقسيم بعد')));
    }
    return ListView.separated(
      itemCount: _groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final group = _groups[index];
        return Card(
          child: ExpansionTile(
            initiallyExpanded: index < 2,
            title: Row(
              children: [
                Expanded(
                  child: Text('${group.name} - القائد: ${group.leader}'),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _renameGroup(index),
                ),
              ],
            ),
            subtitle: Text('عدد المخدومين: ${group.members.length}'),
            childrenPadding: const EdgeInsets.all(12),
            children: [
              DropdownButtonFormField<int?>(
                value: group.arifId,
                decoration: const InputDecoration(labelText: 'العريف'),
                items: [
                  for (final person in group.members)
                    DropdownMenuItem(
                      value: person.id,
                      child: Text('${person.name} (${person.id})'),
                    ),
                ],
                onChanged: (value) => _changeArif(index, value),
              ),
              const SizedBox(height: 10),
              for (final person in group.members)
                ListTile(
                  dense: true,
                  leading: person.id == group.arifId
                      ? const Icon(Icons.star, color: Colors.amber)
                      : const Icon(Icons.person_outline),
                  title: Text(person.name),
                  subtitle: Text('كود: ${person.id} - ${person.stageName}'),
                  trailing: DropdownButton<int>(
                    hint: const Text('نقل'),
                    items: [
                      for (var target = 0; target < _groups.length; target++)
                        if (target != index)
                          DropdownMenuItem(
                            value: target,
                            child: Text(_groups[target].name),
                          ),
                    ],
                    onChanged: (target) {
                      if (target != null) {
                        _swapMembers(
                          fromGroup: index,
                          personId: person.id,
                          toGroup: target,
                        );
                      }
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
