import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../database/database.dart';
import '../database/database_provider.dart';
import '../repositories/persons_repository.dart';
import '../repositories/fields_repository.dart';
import '../repositories/stages_repository.dart';
import '../repositories/khoros_repository.dart';
import '../repositories/areas_repository.dart';
import '../repositories/fathers_repository.dart';
import '../ui/widgets/multi_select_filter.dart';
import 'package:drift/drift.dart' as drift;
import '../repositories/settings_repository.dart';
import '../services/family_report_pdf_generator.dart';
import '../ui/dialogs/sorting_dialog.dart';

class FamilyRelationshipsView extends ConsumerStatefulWidget {
  const FamilyRelationshipsView({super.key});

  @override
  ConsumerState<FamilyRelationshipsView> createState() => _FamilyRelationshipsViewState();
}

class _FamilyRelationshipsViewState extends ConsumerState<FamilyRelationshipsView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _displayGroups = [];
  bool _showFilters = false;

  Future<void> _printReport() async {
    if (_displayGroups.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد بيانات لطباعتها'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const SortingDialog(isAttendance: false),
    );

    if (result == null) return;

    try {
      final List<String> sorting = (result['sorting'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final List<String> headerIds = (result['header'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final List<ReportColumn> cols = result['columns'] as List<ReportColumn>;
      
      final db = ref.read(appDatabaseProvider);
      final Map<String, String> headerData = {};
      
      if (headerIds.contains('church_name')) {
        final cn = await ref.read(settingsRepositoryProvider).getSetting('church_name');
        if (cn != null && cn.isNotEmpty) headerData['اسم الكنيسة'] = cn;
      }

      // Add other header fields as in PersonReport
      for (var id in headerIds) {
        if (id == 'stage' && _filterStageIds.isNotEmpty) {
           final items = await (db.select(db.stages)..where((t) => t.stageId.isIn(_filterStageIds))).get();
           headerData['المرحلة'] = items.map((e) => e.stageName).join('، ');
        } else if (id == 'area' && _filterAreaIds.isNotEmpty) {
           final items = await (db.select(db.areas)..where((t) => t.areaId.isIn(_filterAreaIds))).get();
           headerData['المنطقة'] = items.map((e) => e.areaName).join('، ');
        } else if (id == 'khoros' && _filterKhorosIds.isNotEmpty) {
           final items = await (db.select(db.khoroses)..where((t) => t.khorosId.isIn(_filterKhorosIds))).get();
           headerData['الخورس'] = items.map((e) => e.khorosName).join('، ');
        } else if (id == 'father' && _filterFatherIds.isNotEmpty) {
           final items = await (db.select(db.fathers)..where((t) => t.fatherId.isIn(_filterFatherIds))).get();
           headerData['أب الاعتراف'] = items.map((e) => e.fatherName).join('، ');
        }
      }

      final settingsRepo = ref.read(settingsRepositoryProvider);
      final churchLogo = await settingsRepo.getChurchLogo();
      final churchName = await settingsRepo.getSetting('church_name');

      await FamilyReportPdfGenerator.generateAndPrint(
        groups: _displayGroups,
        title: 'تقرير صلات القرابة والترابط العائلي',
        churchName: churchName,
        churchLogo: churchLogo,
        headerData: headerData,
        selectedColumns: cols.map((c) => c.id).toList(), 
        sortingCriteria: sorting,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء الطباعة: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _searchQuery = '';
  List<int> _filterStageIds = [];
  List<int> _filterKhorosIds = [];
  List<int> _filterAreaIds = [];
  List<int> _filterFatherIds = [];
  List<String> _filterGenders = [];
  List<int> _filterBirthdayDay = [];
  List<int> _filterBirthdayMonth = [];
  List<int> _filterBirthdayYear = [];
  
  // Display Modes: 'person', 'family', 'nuclear'
  String _displayMode = 'family';

  @override
  void initState() {
    super.initState();
    _loadAllRelationships();
  }

  Future<void> _loadAllRelationships() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final db = ref.read(appDatabaseProvider);
    final repo = ref.read(personsRepositoryProvider.notifier);

    // 1. Fetch filtered Persons (the participants in the view)
    final participants = await repo.fetchPersons(
      search: _searchQuery,
      limit: 1500,
      offset: 0,
      stageIds: _filterStageIds,
      khorosIds: _filterKhorosIds,
      areaIds: _filterAreaIds,
      fatherIds: _filterFatherIds,
      genders: _filterGenders,
      birthdayDay: _filterBirthdayDay,
      birthdayMonth: _filterBirthdayMonth,
      birthdayYear: _filterBirthdayYear,
      includeServices: false,
    );

    if (participants.isEmpty) {
      if (mounted) setState(() { _displayGroups = []; _isLoading = false; });
      return;
    }

    final participantIds = participants.map((p) => p.id).toSet();

    // 2. Fetch all unique relationships involving ANY of these participants
    final allRels = await (db.select(db.familyRelationships)
      ..where((t) {
        final ids = participantIds.toList();
        return drift.Expression.or([
          t.personId.isIn(ids),
          t.relatedPersonId.isIn(ids),
        ]);
      })).get();

    // 3. Map participant names and genders for quick lookup
    final Map<int, String> names = {for (var p in participants) p.id: p.name};
    final Map<int, String> genders = {for (var p in participants) p.id: p.jenderName ?? 'ذكر'};

    // For related persons who might NOT be in the filtered list, we need their names and genders too
    final missingIds = allRels
        .expand((r) => [r.personId, r.relatedPersonId])
        .where((id) => !names.containsKey(id))
        .toSet();
    
    if (missingIds.isNotEmpty) {
      final missingNamesRows = await (db.select(db.persons)..where((t) => t.personId.isIn(missingIds.toList()))).get();
      for (var r in missingNamesRows) {
        names[r.personId] = r.personName ?? 'غير معروف';
        genders[r.personId] = r.jenderName ?? 'ذكر';
      }
    }

    // 4. Grouping Logic Based on Mode
    List<Map<String, dynamic>> groups = [];

    if (_displayMode == 'person') {
      for (var p in participants) {
        final rels = allRels.where((r) => r.personId == p.id).toList();
        if (rels.isEmpty) continue;
        
        groups.add({
          'headName': p.name,
          'headId': p.id,
          'personData': p, // Store head's data
          'children': rels.map((r) => {
            'id': r.relatedPersonId,
            'name': names[r.relatedPersonId] ?? 'غير معروف',
            'code': _translateCode(r.relationshipCode, r.customLabel, genders[r.relatedPersonId]),
            'parentName': '',
            'children': <Map<String, dynamic>>[],
            'personData': participants.firstWhereOrNull((per) => per.id == r.relatedPersonId) ?? 
                         (names.containsKey(r.relatedPersonId) ? PersonListDTO(
                            id: r.relatedPersonId, 
                            name: names[r.relatedPersonId]!, 
                            stageName: '', khorosName: '', areaName: '', phone: '', mobile: '', streetName: '', fatherName: '',
                            jenderName: genders[r.relatedPersonId]
                          ) : null),
          }).toList(),
        });
      }
    } else if (_displayMode == 'family' || _displayMode == 'nuclear') {
      final isNuclear = _displayMode == 'nuclear';
      final nuclearCodes = {'HUSBAND', 'WIFE', 'FATHER', 'MOTHER', 'SON', 'DAUGHTER'};
      
      final Map<int, int> parentDSU = {};
      int find(int i) {
        if (parentDSU[i] == null || parentDSU[i] == i) return parentDSU[i] = i;
        return parentDSU[i] = find(parentDSU[i]!);
      }
      void union(int i, int j) {
        int rootI = find(i);
        int rootJ = find(j);
        if (rootI != rootJ) parentDSU[rootI] = rootJ;
      }

      final filteredRels = isNuclear 
          ? allRels.where((r) => nuclearCodes.contains(r.relationshipCode)).toList()
          : allRels;

      for (var r in filteredRels) {
        union(r.personId, r.relatedPersonId);
      }

      Map<int, Set<int>> clusters = {};
      for (var id in names.keys) {
        int root = find(id);
        clusters.putIfAbsent(root, () => {}).add(id);
      }

      for (var clusterIds in clusters.values) {
        if (clusterIds.length <= 1) continue;
        
        final sortedIds = clusterIds.toList()..sort(); 
        final headId = sortedIds.first;

        // Build Tree from Adjacency List within cluster using BFS
        final Map<int, List<FamilyRelationship>> adj = {};
        for (var r in filteredRels) {
          if (clusterIds.contains(r.personId) && clusterIds.contains(r.relatedPersonId)) {
            adj.putIfAbsent(r.personId, () => []).add(r);
            // Reverse relationship for bidirectional traversal
            adj.putIfAbsent(r.relatedPersonId, () => []).add(FamilyRelationship(
              id: -1, // Dummy ID
              personId: r.relatedPersonId,
              relatedPersonId: r.personId,
              relationshipCode: r.relationshipCode, // Will be inversed during tree build
              category: r.category,
              customLabel: r.customLabel,
              createdAt: DateTime.now(),
            ));
          }
        }

        Map<int, Map<String, dynamic>> nodes = {};
        for (var id in clusterIds) {
          nodes[id] = {
            'id': id,
            'name': names[id] ?? 'غير معروف',
            'code': '',
            'parentName': '',
            'children': <Map<String, dynamic>>[],
            // Store person details for possible report columns
            'personData': participants.firstWhereOrNull((p) => p.id == id) ?? 
                         (names.containsKey(id) ? PersonListDTO(
                            id: id, 
                            name: names[id]!, 
                            stageName: '', khorosName: '', areaName: '', phone: '', mobile: '', streetName: '', fatherName: '',
                            jenderName: genders[id]
                          ) : null), 
          };
        }

        final Set<int> visited = {headId};
        final List<int> queue = [headId];

        while (queue.isNotEmpty) {
          final currentId = queue.removeAt(0);
          final currentRels = adj[currentId] ?? [];
          
          for (var rel in currentRels) {
            final childId = rel.relatedPersonId;
            if (!visited.contains(childId)) {
              visited.add(childId);
              queue.add(childId);

              String label;
              final childGender = genders[childId];
              
              // Priority: Find the SPECIFIC relationship as stored in the database
              // If currentId is the 'personId' and childId is 'relatedPersonId', use direct code.
              final directRel = allRels.firstWhereOrNull(
                (r) => r.personId == currentId && r.relatedPersonId == childId
              );
              
              if (directRel != null) {
                label = _translateCode(directRel.relationshipCode, directRel.customLabel, childGender);
              } else {
                // If not found, look for the inverse (childId linked to currentId)
                final inverseRel = allRels.firstWhereOrNull(
                  (r) => r.personId == childId && r.relatedPersonId == currentId
                );
                if (inverseRel != null) {
                  label = _translateInverseCode(inverseRel.relationshipCode, childGender);
                } else {
                  label = childGender == 'أنثى' ? 'قريبة' : 'قريب';
                }
              }

              nodes[childId]!['code'] = label;
              nodes[childId]!['parentName'] = names[currentId];
              nodes[currentId]!['children'].add(nodes[childId]);
            }
          }
        }

        groups.add({
          'headName': names[headId] ?? 'غير معروف',
          'headId': headId,
          'children': nodes[headId]!['children'],
          'personData': nodes[headId]!['personData'],
        });
      }
    }

    if (mounted) {
      setState(() {
        _displayGroups = groups;
        _isLoading = false;
      });
    }
  }

  String _translateCategory(String cat) {
    switch (cat) {
      case 'marriage': return 'زواج';
      case 'first_degree': return 'درجة أولى';
      case 'second_degree': return 'درجة ثانية';
      case 'third_degree': return 'درجة ثالثة';
      default: return 'أخرى';
    }
  }

  String _translateCode(String code, String? custom, String? gender) {
    if (code == 'OTHER' && custom != null) return custom;
    final isFemale = gender == 'أنثى';
    
    const map = {
      'HUSBAND': 'زوج', 'WIFE': 'زوجة', 'FATHER': 'أب', 'MOTHER': 'أم',
      'SON': 'ابن', 'DAUGHTER': 'ابنة', 'BROTHER': 'أخ', 'SISTER': 'أخت',
      'UNCLE_PATERNAL': 'عم', 'AUNT_PATERNAL': 'عمة', 
      'UNCLE_MATERNAL': 'خال', 'AUNT_MATERNAL': 'خالة',
      'NEPHEW_PATERNAL': 'ابن أخ', 'NIECE_PATERNAL': 'ابنة أخ',
      'NEPHEW_MATERNAL': 'ابن أخت', 'NIECE_MATERNAL': 'ابنة أخت',
      'COUSIN_PATERNAL': 'ابن عم', 'COUSIN_PATERNAL_F': 'ابنة عم',
      'COUSIN_AMMA': 'ابن عمة', 'COUSIN_AMMA_F': 'ابنة عمة',
      'COUSIN_MATERNAL': 'ابن خال', 'COUSIN_MATERNAL_F': 'ابنة خال',
      'COUSIN_KHALA': 'ابن خالة', 'COUSIN_KHALA_F': 'ابنة خالة',
      'GRANDFATHER': 'جد', 'GRANDMOTHER': 'جدة',
    };
    
    if (map.containsKey(code)) return map[code]!;

    // Dynamic handling for gender-neutral codes stored by accident
    if (code == 'PARENT') return isFemale ? 'أم' : 'أب';
    if (code == 'CHILD') return isFemale ? 'ابنة' : 'ابن';
    if (code == 'SIBLING') return isFemale ? 'أخت' : 'أخ';

    return code;
  }

  String _translateInverseCode(String code, String? gender) {
    final isFemale = gender == 'أنثى';
    
    switch (code) {
      case 'HUSBAND': return 'زوجة';
      case 'WIFE': return 'زوج';
      case 'FATHER':
      case 'MOTHER': return isFemale ? 'ابنة' : 'ابن';
      case 'SON':
      case 'DAUGHTER': return isFemale ? 'أم' : 'أب';
      case 'BROTHER':
      case 'SISTER': return isFemale ? 'أخت' : 'أخ';
      case 'UNCLE_PATERNAL':
      case 'AUNT_PATERNAL': return isFemale ? 'ابنة أخ/أخت' : 'ابن أخ/أخت';
      case 'UNCLE_MATERNAL':
      case 'AUNT_MATERNAL': return isFemale ? 'ابنة أخ/أخت' : 'ابن أخ/أخت';
      case 'NEPHEW_PATERNAL':
      case 'NIECE_PATERNAL': return isFemale ? 'عمة' : 'عم';
      case 'NEPHEW_MATERNAL':
      case 'NIECE_MATERNAL': return isFemale ? 'خالة' : 'خال';
      case 'GRANDFATHER':
      case 'GRANDMOTHER': return isFemale ? 'حفيدة' : 'حفيد';
      default: return isFemale ? 'قريبة' : 'قريب';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('صلات القرابة والتجميع العائلي'),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt, 
                    color: _showFilters ? Colors.orange : Colors.white),
              onPressed: () => setState(() => _showFilters = !_showFilters),
              tooltip: 'تصفية النتائج',
            ),
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printReport,
              tooltip: 'طباعة التقرير الشجري',
            ),
          ],
        ),
        body: Column(
          children: [
            _buildTopControls(),
            if (_showFilters) _buildFilterPanel(),
            Expanded(
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _displayGroups.isEmpty
                      ? Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.family_restroom_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text('لا توجد نتائج مطابقة للبحث أو الفلترة.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _displayGroups.length,
                          itemBuilder: (context, index) {
                            final group = _displayGroups[index];
                            final children = group['children'] as List<dynamic>;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.blue.withOpacity(0.1)),
                              ),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[50],
                                  child: Icon(Icons.family_restroom, color: Colors.blue[700], size: 20),
                                ),
                                title: Text(group['headName'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                subtitle: Text('كود: ${group['headId']}', 
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                childrenPadding: const EdgeInsets.only(bottom: 8),
                                children: children.map((rel) => _buildTreeBranch(rel, 0)).toList(),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeBranch(Map<String, dynamic> node, int level) {
    final children = node['children'] as List<dynamic>;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final indentPerLevel = isMobile ? 8.0 : 16.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(
            right: indentPerLevel * level + 12, 
            left: 12, 
            top: 4, 
            bottom: 4
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Tree Connecting Line Visual
                if (level >= 0)
                  Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: level == 0 ? Colors.blue.withOpacity(0.04) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: level == 0 ? Colors.blue.withOpacity(0.1) : Colors.grey[200]!,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: level == 0 ? Colors.blue[100] : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          level == 0 ? Icons.person : Icons.subdirectory_arrow_left, 
                          size: 16, 
                          color: level == 0 ? Colors.blue[700] : Colors.grey[600]
                        ),
                      ),
                      title: Text(
                        node['name'], 
                        style: TextStyle(
                          fontWeight: level == 0 ? FontWeight.bold : FontWeight.w600, 
                          fontSize: 14,
                          color: Colors.grey[850]
                        )
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                node['code'],
                                style: TextStyle(fontSize: 10, color: Colors.blue[800], fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (node['parentName'] != null && node['parentName'].isNotEmpty)
                              Text(
                                "(${node['parentName']})",
                                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                              ),
                          ],
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text(
                          "#${node['id']}", 
                          style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.bold)
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (children.isNotEmpty)
          ...children.map((child) => _buildTreeBranch(child, level + 1)).toList(),
      ],
    );
  }

  Widget _buildTopControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) {
                    setState(() => _searchQuery = v);
                    _loadAllRelationships();
                  },
                  decoration: InputDecoration(
                    hintText: 'بحث بالاسم أو الكود...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: DropdownButton<String>(
                  value: _displayMode,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.blue),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _displayMode = v);
                      _loadAllRelationships();
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 'person', child: Text('عرض كأفراد', style: TextStyle(fontSize: 13))),
                    DropdownMenuItem(value: 'family', child: Text('تجميع عائلات', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                    DropdownMenuItem(value: 'nuclear', child: Text('تجميع أسر', style: TextStyle(fontSize: 13))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 450),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.filter_list_alt, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text('تصفية النتائج', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _filterStageIds = [];
                        _filterKhorosIds = [];
                        _filterAreaIds = [];
                        _filterFatherIds = [];
                        _filterGenders = [];
                        _filterBirthdayDay = [];
                        _filterBirthdayMonth = [];
                        _filterBirthdayYear = [];
                      });
                      _loadAllRelationships();
                    },
                    child: const Text('تصفير البحث والفلترة', style: TextStyle(color: Colors.red, fontSize: 12)),
                  )
                ],
              ),
              const Divider(),
              _buildStageFilter(),
              const SizedBox(height: 12),
              _buildKhorosFilter(),
              const SizedBox(height: 12),
              _buildAreaFilter(),
              const SizedBox(height: 12),
              _buildFatherFilter(),
              const SizedBox(height: 12),
              _buildGenderFilter(),
              const SizedBox(height: 12),
              _buildBirthdayDayFilter(),
              const SizedBox(height: 12),
              _buildBirthdayMonthFilter(),
              const SizedBox(height: 12),
              _buildBirthdayYearFilter(),
            ],
          ),
        ),
      ),
    );
  }

  String _getLabel(String key, String fallback) {
    if (!mounted) return fallback;
    final fields = ref.watch(fieldsRepositoryProvider).asData?.value ?? [];
    final f = fields.where((f) => f.fieldKey == key).firstOrNull;
    return f?.name ?? fallback;
  }

  Widget _buildStageFilter() {
    return ref.watch(stagesRepositoryProvider).maybeWhen(
      data: (stages) => MultiSelectFilter(
        label: _getLabel('stage', 'المرحلة'),
        selectedIds: _filterStageIds,
        allItems: stages.map((s) => SelectableItem(id: s.id, name: s.name)).toList(),
        onChanged: (ids) {
          setState(() => _filterStageIds = List<int>.from(ids));
          _loadAllRelationships();
        },
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildKhorosFilter() {
    return ref.watch(khorosRepositoryProvider).maybeWhen(
      data: (k) => MultiSelectFilter(
        label: _getLabel('khoros', 'الخورس/الفريق'),
        selectedIds: _filterKhorosIds,
        allItems: k.map((it) => SelectableItem(id: it.id, name: it.name)).toList(),
        onChanged: (ids) {
          setState(() => _filterKhorosIds = List<int>.from(ids));
          _loadAllRelationships();
        },
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildAreaFilter() {
    return ref.watch(areasRepositoryProvider).maybeWhen(
      data: (areas) => MultiSelectFilter(
        label: _getLabel('area', 'المنطقة'),
        selectedIds: _filterAreaIds,
        allItems: areas.map((a) => SelectableItem(id: a.id, name: a.name)).toList(),
        onChanged: (ids) {
          setState(() => _filterAreaIds = List<int>.from(ids));
          _loadAllRelationships();
        },
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildFatherFilter() {
    return ref.watch(fathersRepositoryProvider).maybeWhen(
      data: (fathers) => MultiSelectFilter(
        label: _getLabel('father', 'أب الاعتراف'),
        selectedIds: _filterFatherIds,
        allItems: fathers.map((f) => SelectableItem(id: f.id, name: f.name)).toList(),
        onChanged: (ids) {
          setState(() => _filterFatherIds = List<int>.from(ids));
          _loadAllRelationships();
        },
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildGenderFilter() {
    return MultiSelectFilter(
      label: _getLabel('gender', 'النوع'),
      selectedIds: _filterGenders,
      allItems: [
        SelectableItem(id: 'ذكر', name: 'ذكر'),
        SelectableItem(id: 'أنثى', name: 'أنثى'),
      ],
      onChanged: (ids) {
        setState(() => _filterGenders = List<String>.from(ids));
        _loadAllRelationships();
      },
    );
  }

  Widget _buildBirthdayDayFilter() {
    return MultiSelectFilter(
      label: 'يوم (${_getLabel('birthday', 'الميلاد')})',
      selectedIds: _filterBirthdayDay,
      allItems: List.generate(31, (i) => SelectableItem(id: i + 1, name: '${i + 1}')),
      onChanged: (ids) {
        setState(() => _filterBirthdayDay = List<int>.from(ids));
        _loadAllRelationships();
      },
    );
  }

  Widget _buildBirthdayMonthFilter() {
    return MultiSelectFilter(
      label: 'شهر (${_getLabel('birthday', 'الميلاد')})',
      selectedIds: _filterBirthdayMonth,
      allItems: List.generate(12, (i) => SelectableItem(id: i + 1, name: '${i + 1}')),
      onChanged: (ids) {
        setState(() => _filterBirthdayMonth = List<int>.from(ids));
        _loadAllRelationships();
      },
    );
  }

  Widget _buildBirthdayYearFilter() {
    return MultiSelectFilter(
      label: 'سنة (${_getLabel('birthday', 'الميلاد')})',
      selectedIds: _filterBirthdayYear,
      allItems: List.generate(80, (i) {
        final y = DateTime.now().year - i;
        return SelectableItem(id: y, name: '$y');
      }),
      onChanged: (ids) {
        setState(() => _filterBirthdayYear = List<int>.from(ids));
        _loadAllRelationships();
      },
    );
  }
}
