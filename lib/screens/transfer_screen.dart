import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database_provider.dart';
import '../database/database.dart';
import '../repositories/persons_repository.dart';
import '../repositories/service_eligibility_repository.dart';
import '../repositories/stages_repository.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  String _selectedFieldType = 'stage'; // 'stage', 'area', 'father'
  int? _fromValueId;
  int? _toValueId;

  List<PersonListDTO> _matchingPersons = [];
  Set<int> _selectedPersonIds = {};
  bool _isLoading = false;

  void _onFieldTypeChanged(String? newValue) {
    if (newValue != null && newValue != _selectedFieldType) {
      setState(() {
        _selectedFieldType = newValue;
        _fromValueId = null;
        _toValueId = null;
        _matchingPersons = [];
        _selectedPersonIds.clear();
      });
    }
  }

  void _onFromValueChanged(int? newValue) async {
    setState(() {
      _fromValueId = newValue;
      _isLoading = true;
      _matchingPersons = [];
      _selectedPersonIds.clear();
    });

    if (newValue != null) {
      final repo = ref.read(personsRepositoryProvider.notifier);
      final allPersons = await repo.fetchPersons(limit: 10000);

      setState(() {
        _matchingPersons = allPersons.where((p) {
          if (_selectedFieldType == 'stage') return p.stageId == newValue;
          if (_selectedFieldType == 'khoros') return p.khorosId == newValue;
          if (_selectedFieldType == 'area') return p.areaId == newValue;
          if (_selectedFieldType == 'father') return p.fatherId == newValue;
          return false;
        }).toList();

        _selectedPersonIds = _matchingPersons.map((p) => p.id).toSet();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _transfer() async {
    if (_selectedPersonIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تحديد شخص واحد على الأقل')),
      );
      return;
    }
    if (_toValueId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار المكان المنقول إليه')),
      );
      return;
    }

    if (_fromValueId == _toValueId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('المكان المنقول منه هو نفس المكان المنقول إليه'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد النقل'),
          content: Text(
            'هل أنت متأكد من نقل ${_selectedPersonIds.length} شخص؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'تأكيد النقل',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final repo = ref.read(personsRepositoryProvider.notifier);
    final success = await repo.bulkTransfer(
      _selectedPersonIds.toList(),
      _selectedFieldType,
      _toValueId!,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم النقل بنجاح!')));
        _onFromValueChanged(_fromValueId);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء النقل')));
      }
    }
  }

  void _runAutomaticPromotion(AppDatabase db) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الترقية التلقائية'),
          content: const Text(
            'تنبيه: سيتم ترحيل جميع المخدومين في كافة المراحل إلى مراحلهم التالية وتخريج طلاب المرحلة النهائية. هل تريد الاستمرار؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'نعم، ترقية الكل',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final stages = await db.select(db.stages).get();
      if (stages.isEmpty) {
        throw Exception('لا توجد مراحل مسجلة لترقيتها.');
      }

      // Build topological sort
      final Map<int, Stage> stageMap = {for (var s in stages) s.stageId: s};
      final List<int> orderedIds = [];
      final Set<int> visited = {};
      final Set<int> temp = {};

      void visit(int stageId) {
        if (visited.contains(stageId)) return;
        if (temp.contains(stageId)) {
          // Cycle detected!
          return;
        }
        temp.add(stageId);
        final stage = stageMap[stageId];
        if (stage != null && stage.nextStageId != null) {
          visit(stage.nextStageId!);
        }
        temp.remove(stageId);
        visited.add(stageId);
        orderedIds.add(stageId);
      }

      for (final s in stages) {
        visit(s.stageId);
      }

      // Run promotion inside a transaction
      await db.transaction(() async {
        for (final id in orderedIds) {
          final stage = stageMap[id]!;
          final nextId = stage.nextStageId;

          // 1. Fetch student IDs currently in this stage
          final studentIds =
              await (db.select(db.persons)..where((t) => t.stageId.equals(id)))
                  .get()
                  .then((rows) => rows.map((r) => r.personId).toList());

          if (studentIds.isEmpty) continue;

          // 2. Perform the stage update for students in this stage
          await (db.update(db.persons)..where((t) => t.stageId.equals(id)))
              .write(PersonsCompanion(stageId: drift.Value(nextId)));

          final eligibility = ServiceEligibilityRepository(db);
          await eligibility.syncResolvedServicesForPeople(studentIds);
        }
      });

      // Refresh persons repository
      ref.invalidate(personsRepositoryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت عملية الترقية التلقائية للمراحل بنجاح!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('فشلت العملية: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _fromValueId = null;
          _toValueId = null;
          _matchingPersons = [];
          _selectedPersonIds.clear();
        });
      }
    }
  }

  Widget _buildAutomaticPromotionCard(
    AppDatabase db,
    List<StageModel> stagesList,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'الترقية التلقائية للمراحل الدراسية',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'تقوم هذه الميزة بترتيب المراحل تلقائياً وترقية جميع المخدومين دفعة واحدة إلى مراحلهم التالية. يمكنك ترتيب تسلسل المراحل بالضغط على زر تحديد التسلسل.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _showDefineSequenceDialog(db),
                      icon: const Icon(Icons.sort),
                      label: const Text('تحديد التسلسل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _runAutomaticPromotion(db),
                      icon: const Icon(Icons.rocket_launch),
                      label: const Text('نقل تلقائي'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            _buildSequencePreview(stagesList),
          ],
        ),
      ),
    );
  }

  Widget _buildSequencePreview(List<StageModel> stagesList) {
    if (stagesList.isEmpty) return const SizedBox.shrink();

    final Map<int, StageModel> stageMap = {for (var s in stagesList) s.id: s};
    final Set<int> referencedIds = stagesList
        .map((s) => s.nextStageId)
        .whereType<int>()
        .toSet();
    final List<StageModel> starts = stagesList
        .where((s) => !referencedIds.contains(s.id))
        .toList();

    final List<List<StageModel>> chains = [];
    final Set<int> visited = {};

    for (final start in starts) {
      final List<StageModel> chain = [];
      StageModel? current = start;
      while (current != null && !visited.contains(current.id)) {
        visited.add(current.id);
        chain.add(current);
        if (current.nextStageId != null) {
          current = stageMap[current.nextStageId];
        } else {
          current = null;
        }
      }
      if (chain.isNotEmpty) {
        chains.add(chain);
      }
    }

    for (final s in stagesList) {
      if (!visited.contains(s.id)) {
        final List<StageModel> chain = [];
        StageModel? current = s;
        while (current != null && !visited.contains(current.id)) {
          visited.add(current.id);
          chain.add(current);
          if (current.nextStageId != null) {
            current = stageMap[current.nextStageId];
          } else {
            current = null;
          }
        }
        if (chain.isNotEmpty) {
          chains.add(chain);
        }
      }
    }

    if (chains.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 4),
          const Text(
            'تسلسل الترقية الحالي (من اليمين لليسار):',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: chains.map((chain) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    for (int i = 0; i < chain.length; i++) ...[
                      Chip(
                        label: Text(
                          chain[i].name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: Colors.white,
                      ),
                      if (i < chain.length - 1)
                        const Icon(
                          Icons.keyboard_arrow_left_rounded,
                          size: 18,
                          color: Colors.grey,
                        )
                      else
                        const Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(
                              Icons.keyboard_arrow_left_rounded,
                              size: 18,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4),
                            Chip(
                              label: Text(
                                'تخرج',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: Colors.red,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<StageModel> _getFlatInitialStages(List<StageModel> stagesList) {
    final Map<int, StageModel> stageMap = {for (var s in stagesList) s.id: s};
    final Set<int> referencedIds = stagesList
        .map((s) => s.nextStageId)
        .whereType<int>()
        .toSet();
    final List<StageModel> starts = stagesList
        .where((s) => !referencedIds.contains(s.id))
        .toList();
    final List<StageModel> flat = [];
    final Set<int> visited = {};

    void addChain(StageModel start) {
      StageModel? current = start;
      while (current != null && !visited.contains(current.id)) {
        visited.add(current.id);
        flat.add(current);
        if (current.nextStageId != null) {
          current = stageMap[current.nextStageId];
        } else {
          current = null;
        }
      }
    }

    for (final start in starts) {
      addChain(start);
    }
    for (final s in stagesList) {
      if (!visited.contains(s.id)) {
        addChain(s);
      }
    }
    return flat;
  }

  void _showDefineSequenceDialog(AppDatabase db) async {
    final stages = await db.select(db.stages).get();
    if (stages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد مراحل مسجلة لتحديد تسلسها')),
      );
      return;
    }

    final List<StageModel> stagesList = stages
        .map(
          (s) => StageModel(
            id: s.stageId ?? 0,
            name: s.stageName ?? '',
            serviceId: s.serviceId,
            nextStageId: s.nextStageId,
          ),
        )
        .toList();

    List<StageModel> dialogStages = _getFlatInitialStages(stagesList);
    final bool hasExistingSequence = stagesList.any(
      (s) => s.nextStageId != null,
    );
    final Set<int> endSequenceIds = hasExistingSequence
        ? stagesList
              .where((s) => s.nextStageId == null)
              .map((s) => s.id)
              .toSet()
        : <int>{};

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.sort, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    const Text('تحديد تسلسل الترقية للمراحل'),
                  ],
                ),
                content: SizedBox(
                  width: 500,
                  height: 450,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'قم بسحب وإفلات المراحل لترتيبها من الأقل للأعلى. المراحل المرتبة ستسلم بعضها البعض بالتوالي. فَعّل خيار "تخرج هنا" لفصل التسلسل (مثال: نهاية مرحلة إعدادي وبداية مرحلة ثانوي).',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ReorderableListView.builder(
                          itemCount: dialogStages.length,
                          itemBuilder: (context, index) {
                            final stage = dialogStages[index];
                            final isLast = index == dialogStages.length - 1;
                            final isEnd =
                                endSequenceIds.contains(stage.id) || isLast;

                            return Card(
                              key: ValueKey(stage.id),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: Icon(
                                  Icons.drag_handle,
                                  color: Colors.grey[400],
                                ),
                                title: Text(
                                  stage.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  isEnd
                                      ? 'تأثير الترقية: تخرج (إزالة المرحلة)'
                                      : 'ترقية إلى: ${index + 1 < dialogStages.length ? dialogStages[index + 1].name : ""}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isEnd
                                        ? Colors.red
                                        : Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: isLast
                                    ? const Chip(
                                        label: Text(
                                          'تخرج تلقائي',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                          ),
                                        ),
                                        backgroundColor: Colors.red,
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'تخرج هنا؟',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          Checkbox(
                                            value: isEnd,
                                            onChanged: (val) {
                                              setStateDialog(() {
                                                if (val == true) {
                                                  endSequenceIds.add(stage.id);
                                                } else {
                                                  endSequenceIds.remove(
                                                    stage.id,
                                                  );
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          },
                          onReorder: (oldIndex, newIndex) {
                            setStateDialog(() {
                              if (oldIndex < newIndex) {
                                newIndex -= 1;
                              }
                              final item = dialogStages.removeAt(oldIndex);
                              dialogStages.insert(newIndex, item);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      await _saveStagesSequence(
                        dialogStages,
                        endSequenceIds,
                        db,
                      );
                    },
                    child: const Text('حفظ التسلسل'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveStagesSequence(
    List<StageModel> reorderedStages,
    Set<int> endSequenceIds,
    AppDatabase db,
  ) async {
    setState(() => _isLoading = true);
    try {
      await db.transaction(() async {
        for (int i = 0; i < reorderedStages.length; i++) {
          final current = reorderedStages[i];
          final isEnd =
              endSequenceIds.contains(current.id) ||
              (i == reorderedStages.length - 1);
          final nextId = isEnd ? null : reorderedStages[i + 1].id;

          await (db.update(db.stages)
                ..where((t) => t.stageId.equals(current.id)))
              .write(StagesCompanion(nextStageId: drift.Value(nextId)));
        }
      });
      ref.invalidate(stagesRepositoryProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ تسلسل المراحل بنجاح!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ أثناء حفظ التسلسل: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(appDatabaseProvider);
    final stagesAsync = ref.watch(stagesRepositoryProvider);
    final stagesList = stagesAsync.value ?? [];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildFilterCard(db),
              const SizedBox(height: 16),
              _buildAutomaticPromotionCard(db, stagesList),
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'الأشخاص (${_matchingPersons.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            if (_matchingPersons.isNotEmpty)
                              TextButton.icon(
                                icon: Icon(
                                  _selectedPersonIds.length ==
                                          _matchingPersons.length
                                      ? Icons.deselect
                                      : Icons.select_all,
                                ),
                                label: Text(
                                  _selectedPersonIds.length ==
                                          _matchingPersons.length
                                      ? 'إلغاء التحديد'
                                      : 'تحديد الكل',
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (_selectedPersonIds.length ==
                                        _matchingPersons.length) {
                                      _selectedPersonIds.clear();
                                    } else {
                                      _selectedPersonIds = _matchingPersons
                                          .map((p) => p.id)
                                          .toSet();
                                    }
                                  });
                                },
                              ),
                          ],
                        ),
                        const Divider(),
                        Expanded(child: _buildPersonsList()),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'شاشة النقل',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          'نقل مجموعة أشخاص دفعة واحدة بين المراحل أو المناطق أو الآباء',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildFilterCard(AppDatabase db) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<String>(
                value: _selectedFieldType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'نوع النقل',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'stage', child: Text('المرحلة')),
                  DropdownMenuItem(value: 'khoros', child: Text('الخورس')),
                  DropdownMenuItem(value: 'area', child: Text('المنطقة')),
                  DropdownMenuItem(value: 'father', child: Text('أب الاعتراف')),
                ],
                onChanged: _onFieldTypeChanged,
              ),
            ),
            SizedBox(
              width: 200,
              child: _buildDynamicDropdown(
                db: db,
                value: _fromValueId,
                label: 'من',
                icon: Icons.exit_to_app,
                onChanged: _onFromValueChanged,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Icon(Icons.arrow_back, color: Colors.grey),
            ),
            SizedBox(
              width: 200,
              child: _buildDynamicDropdown(
                db: db,
                value: _toValueId,
                label: 'إلى',
                icon: Icons.input,
                onChanged: (v) => setState(() => _toValueId = v),
              ),
            ),
            SizedBox(
              width: 120,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _transfer,
                icon: const Icon(Icons.drive_file_move_outline),
                label: const Text('نقل'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicDropdown({
    required AppDatabase db,
    required int? value,
    required String label,
    required IconData icon,
    required ValueChanged<int?> onChanged,
  }) {
    Future<List<dynamic>> itemsFuture;
    if (_selectedFieldType == 'stage') {
      itemsFuture = db.select(db.stages).get();
    } else if (_selectedFieldType == 'khoros') {
      itemsFuture = db.select(db.khoroses).get();
    } else if (_selectedFieldType == 'area') {
      itemsFuture = db.select(db.areas).get();
    } else {
      itemsFuture = db.select(db.fathers).get();
    }

    return FutureBuilder<List<dynamic>>(
      future: itemsFuture,
      builder: (_, snap) {
        final data = snap.data ?? [];
        return DropdownButtonFormField<int?>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
          items: [
            const DropdownMenuItem(value: null, child: Text('اختر')),
            ...data.map((item) {
              int id;
              String name;
              if (item is Stage) {
                id = item.stageId;
                name = item.stageName ?? '';
              } else if (item is Khorose) {
                id = item.khorosId;
                name = item.khorosName ?? '';
              } else if (item is Area) {
                id = item.areaId;
                name = item.areaName ?? '';
              } else if (item is Father) {
                id = item.fatherId;
                name = item.fatherName ?? '';
              } else {
                id = 0;
                name = '';
              }
              return DropdownMenuItem(value: id, child: Text(name));
            }),
          ],
          onChanged: onChanged,
        );
      },
    );
  }

  Widget _buildPersonsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_fromValueId == null) {
      return const Center(child: Text('الرجاء اختيار "من" لعرض الأشخاص'));
    }

    if (_matchingPersons.isEmpty) {
      return const Center(child: Text('لا يوجد أشخاص في هذا الاختيار'));
    }

    return ListView.builder(
      itemCount: _matchingPersons.length,
      itemBuilder: (context, index) {
        final person = _matchingPersons[index];
        final isSelected = _selectedPersonIds.contains(person.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (bool? checked) {
              setState(() {
                if (checked == true) {
                  _selectedPersonIds.add(person.id);
                } else {
                  _selectedPersonIds.remove(person.id);
                }
              });
            },
            title: Text(
              person.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('الموبايل: ${person.mobile} | كود: ${person.id}'),
            secondary: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: const Icon(Icons.person, color: Colors.blue, size: 20),
            ),
            activeColor: Theme.of(context).primaryColor,
            selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.05),
            selected: isSelected,
          ),
        );
      },
    );
  }
}
