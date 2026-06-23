import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../repositories/dashboard_repository.dart';
import '../../utils/storyteller.dart';
import '../../database/database_provider.dart';
import '../../models/person_option.dart';
import '../../repositories/services_repository.dart';

class _PersonData {
  final int? id;
  final String name;
  final int? stageId;
  final int? areaId;
  final String? gender;
  _PersonData({this.id, required this.name, this.stageId, this.areaId, this.gender});
}

class IndividualAttendanceWidget extends ConsumerStatefulWidget {
  const IndividualAttendanceWidget({super.key});

  @override
  ConsumerState<IndividualAttendanceWidget> createState() => _IndividualAttendanceWidgetState();
}

class _IndividualAttendanceWidgetState extends ConsumerState<IndividualAttendanceWidget> {
  final Set<PersonOption> _selectedPersons = {};
  String _groupBy = 'month';
  int? _selectedYear;
  int? _selectedMonth;
  int? _selectedStageId;
  int? _selectedAreaId;
  String? _selectedGender;
  int? _selectedServiceId;
  String? _selectedStatus;
  TextEditingController? _internalAutocompleteController;
  List<_PersonData> _allPersons = [];
  bool _isLoadingPersons = true;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _selectedMonth = DateTime.now().month;
    _loadPersons();
  }

  Future<void> _loadPersons() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final persons = await db.select(db.persons).get();
      if (mounted) {
        setState(() {
          _allPersons = persons.map((p) => _PersonData(
            id: p.personId,
            name: p.personName ?? '',
            stageId: p.stageId,
            areaId: p.areaId,
            gender: p.jenderName,
          )).toList();
          _isLoadingPersons = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPersons = false);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 14 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Builder(builder: (context) {
              final isMobile = MediaQuery.of(context).size.width < 600;
              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.person_pin, color: Theme.of(context).primaryColor, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'الحضور الخاص (فردي)',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_groupBy == 'month' || _groupBy == 'day')
                          _buildBetterDropdown<int?>(
                            value: _selectedYear,
                            hint: 'السنة',
                            items: [
                              const DropdownMenuItem(value: null, child: Text('كل السنوات')),
                              ...List.generate(10, (i) {
                                int y = DateTime.now().year - i;
                                return DropdownMenuItem(value: y, child: Text(y.toString()));
                              }),
                            ],
                            onChanged: (val) => setState(() => _selectedYear = val),
                          ),
                        if (_groupBy == 'day')
                          _buildBetterDropdown<int?>(
                            value: _selectedMonth,
                            hint: 'الشهر',
                            items: [
                              const DropdownMenuItem(value: null, child: Text('كل الشهور')),
                              ...List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('شهر ${i + 1}'))),
                            ],
                            onChanged: (val) => setState(() => _selectedMonth = val),
                          ),
                        _buildBetterDropdown<String>(
                          value: _groupBy,
                          items: const [
                            DropdownMenuItem(value: 'day', child: Text('باليوم')),
                            DropdownMenuItem(value: 'month', child: Text('بالشهر')),
                            DropdownMenuItem(value: 'year', child: Text('بالسنة')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _groupBy = val);
                          },
                        ),
                        _buildBetterDropdown<int?>(
                          value: _selectedServiceId,
                          hint: 'الخدمة',
                          items: [
                            const DropdownMenuItem(value: null, child: Text('كل الخدمات')),
                            ...ref.watch(servicesRepositoryProvider).maybeWhen(
                              data: (services) => services.map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name),
                              )).toList(),
                              orElse: () => [],
                            ),
                          ],
                          onChanged: (val) => setState(() => _selectedServiceId = val),
                        ),
                        _buildBetterDropdown<String?>(
                          value: _selectedStatus,
                          hint: 'الحالة',
                          items: const [
                            DropdownMenuItem(value: null, child: Text('الكل')),
                            DropdownMenuItem(value: 'present', child: Text('الحاضرين')),
                            DropdownMenuItem(value: 'checked_out', child: Text('المنصرفين')),
                            DropdownMenuItem(value: 'complete', child: Text('حضور كامل')),
                          ],
                          onChanged: (val) => setState(() => _selectedStatus = val),
                        ),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.person_pin, color: Theme.of(context).primaryColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'الحضور الخاص (فردي)', 
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900, 
                          letterSpacing: -1,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (_groupBy == 'month' || _groupBy == 'day')
                        _buildBetterDropdown<int?>(
                          value: _selectedYear,
                          hint: 'السنة',
                          items: [
                            const DropdownMenuItem(value: null, child: Text('كل السنوات')),
                            ...List.generate(10, (i) {
                              int y = DateTime.now().year - i;
                              return DropdownMenuItem(value: y, child: Text(y.toString()));
                            }),
                          ],
                          onChanged: (val) => setState(() => _selectedYear = val),
                        ),
                      if (_groupBy == 'day')
                        _buildBetterDropdown<int?>(
                          value: _selectedMonth,
                          hint: 'الشهر',
                          items: [
                            const DropdownMenuItem(value: null, child: Text('كل الشهور')),
                            ...List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('شهر ${i + 1}'))),
                          ],
                          onChanged: (val) => setState(() => _selectedMonth = val),
                        ),
                      _buildBetterDropdown<String>(
                        value: _groupBy,
                        items: const [
                          DropdownMenuItem(value: 'day', child: Text('باليوم')),
                          DropdownMenuItem(value: 'month', child: Text('بالشهر')),
                          DropdownMenuItem(value: 'year', child: Text('بالسنة')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _groupBy = val);
                        },
                      ),
                      _buildBetterDropdown<int?>(
                        value: _selectedServiceId,
                        hint: 'الخدمة',
                        items: [
                          const DropdownMenuItem(value: null, child: Text('كل الخدمات')),
                          ...ref.watch(servicesRepositoryProvider).maybeWhen(
                            data: (services) => services.map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            )).toList(),
                            orElse: () => [],
                          ),
                        ],
                        onChanged: (val) => setState(() => _selectedServiceId = val),
                      ),
                      _buildBetterDropdown<String?>(
                        value: _selectedStatus,
                        hint: 'الحالة',
                        items: const [
                          DropdownMenuItem(value: null, child: Text('الكل')),
                          DropdownMenuItem(value: 'present', child: Text('الحاضرين')),
                          DropdownMenuItem(value: 'checked_out', child: Text('المنصرفين')),
                          DropdownMenuItem(value: 'complete', child: Text('حضور كامل')),
                        ],
                        onChanged: (val) => setState(() => _selectedStatus = val),
                      ),
                    ],
                  ),
                ],
              );
            }),
            const SizedBox(height: 24),
            Builder(builder: (context) {
              final isMobile = MediaQuery.of(context).size.width < 600;
              if (isMobile) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FutureBuilder(
                        future: ref.read(appDatabaseProvider).select(ref.read(appDatabaseProvider).stages).get(),
                        builder: (context, snapshot) {
                          final stages = snapshot.data ?? [];
                          return _buildBetterDropdown<int?>(
                            value: _selectedStageId,
                            hint: 'المرحلة',
                            items: [
                              const DropdownMenuItem(value: null, child: Text('كل المراحل')),
                              ...stages.map((s) => DropdownMenuItem(value: s.stageId, child: Text(s.stageName ?? ''))),
                            ],
                            onChanged: (val) => setState(() => _selectedStageId = val),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FutureBuilder(
                        future: ref.read(appDatabaseProvider).select(ref.read(appDatabaseProvider).areas).get(),
                        builder: (context, snapshot) {
                          final areas = snapshot.data ?? [];
                          return _buildBetterDropdown<int?>(
                            value: _selectedAreaId,
                            hint: 'المنطقة',
                            items: [
                              const DropdownMenuItem(value: null, child: Text('كل المناطق')),
                              ...areas.map((a) => DropdownMenuItem(value: a.areaId, child: Text(a.areaName ?? ''))),
                            ],
                            onChanged: (val) => setState(() => _selectedAreaId = val),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: _buildBetterDropdown<String?>(
                        value: _selectedGender,
                        hint: 'النوع',
                        items: const [
                          DropdownMenuItem(value: null, child: Text('الكل')),
                          DropdownMenuItem(value: 'ذكر', child: Text('ذكر')),
                          DropdownMenuItem(value: 'أنثى', child: Text('أنثى')),
                        ],
                        onChanged: (val) => setState(() => _selectedGender = val),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: FutureBuilder(
                      future: ref.read(appDatabaseProvider).select(ref.read(appDatabaseProvider).stages).get(),
                      builder: (context, snapshot) {
                        final stages = snapshot.data ?? [];
                        return _buildBetterDropdown<int?>(
                          value: _selectedStageId,
                          hint: 'تصفية بالمرحلة',
                          width: 130,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('كل المراحل')),
                            ...stages.map((s) => DropdownMenuItem(value: s.stageId, child: Text(s.stageName ?? ''))),
                          ],
                          onChanged: (val) => setState(() => _selectedStageId = val),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FutureBuilder(
                      future: ref.read(appDatabaseProvider).select(ref.read(appDatabaseProvider).areas).get(),
                      builder: (context, snapshot) {
                        final areas = snapshot.data ?? [];
                        return _buildBetterDropdown<int?>(
                          value: _selectedAreaId,
                          hint: 'تصفية بالمنطقة',
                          width: 130,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('كل المناطق')),
                            ...areas.map((a) => DropdownMenuItem(value: a.areaId, child: Text(a.areaName ?? ''))),
                          ],
                          onChanged: (val) => setState(() => _selectedAreaId = val),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBetterDropdown<String?>(
                      value: _selectedGender,
                      hint: 'تصفية بالنوع',
                      items: const [
                        DropdownMenuItem(value: null, child: Text('الكل')),
                        DropdownMenuItem(value: 'ذكر', child: Text('ذكر')),
                        DropdownMenuItem(value: 'أنثى', child: Text('أنثى')),
                      ],
                      onChanged: (val) => setState(() => _selectedGender = val),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),
            _buildSelectAllAction(context, ref),
            const SizedBox(height: 8),
            _buildPersonAutocomplete(context, ref),
            if (_selectedPersons.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedPersons.map((p) => Chip(
                  label: Text(p.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => _selectedPersons.remove(p)),
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                )).toList(),
              ),
            ],
            const SizedBox(height: 32),
            if (_selectedPersons.isNotEmpty)
               Column(
                 children: _selectedPersons.map((p) => Padding(
                   padding: const EdgeInsets.only(bottom: 40),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         children: [
                           Container(
                             width: 4,
                             height: 24,
                             decoration: BoxDecoration(
                               color: Theme.of(context).primaryColor,
                               borderRadius: BorderRadius.circular(2),
                             ),
                           ),
                           const SizedBox(width: 12),
                           Text(
                             p.name,
                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                           ),
                         ],
                       ),
                       const SizedBox(height: 16),
                       _buildChartSection(context, p.id, p.name),
                     ],
                   ),
                 )).toList(),
               ),
            if (_selectedPersons.isEmpty)
              Container(
                 height: 220,
                 alignment: Alignment.center,
                 decoration: BoxDecoration(
                   color: Colors.grey.withOpacity(0.05),
                   borderRadius: BorderRadius.circular(20),
                   border: Border.all(color: Colors.grey.withOpacity(0.1), style: BorderStyle.solid),
                 ),
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: Icon(Icons.person_search, size: 48, color: Theme.of(context).primaryColor.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'ابحث عن شخص لعرض تقرير حضوره', 
                        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 15)
                      ),
                   ],
                 ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBetterDropdown<T>({required T value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged, String? hint, double? width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: hint != null ? Text(hint, style: const TextStyle(fontSize: 13)) : null,
          items: items,
          onChanged: onChanged,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
        ),
      ),
    );
  }

  Widget _buildPersonAutocomplete(BuildContext context, WidgetRef ref) {
    if (_isLoadingPersons) return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)));
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Autocomplete<PersonOption>(
        displayStringForOption: (option) => option.name,
        optionsBuilder: (textEditingValue) {
          final query = textEditingValue.text.toLowerCase();
          
          final matches = _allPersons.where((p) {
            // Apply strict filters first
            final stageMatch = _selectedStageId == null || p.stageId == _selectedStageId;
            final areaMatch = _selectedAreaId == null || p.areaId == _selectedAreaId;
            final genderMatch = _selectedGender == null || p.gender == _selectedGender;
            if (!(stageMatch && areaMatch && genderMatch)) return false;

            // Then apply search query if not empty
            if (query.isEmpty) return true;
            
            final name = p.name.toLowerCase();
            final id = p.id.toString();
            return name.contains(query) || id.contains(query);
          }).toList();

          // Sort by relevance: startsWith comes first
          if (query.isNotEmpty) {
            matches.sort((a, b) {
              final aStarts = a.name.toLowerCase().startsWith(query) || a.id.toString().startsWith(query);
              final bStarts = b.name.toLowerCase().startsWith(query) || b.id.toString().startsWith(query);
              if (aStarts && !bStarts) return -1;
              if (!aStarts && bStarts) return 1;
              return 0;
            });
          }

          return matches.map((p) => PersonOption(id: p.id, name: '${p.id} - ${p.name}')).take(50).toList();
        },
        onSelected: (selection) {
          setState(() {
            _selectedPersons.add(selection);
            // Delay clear slightly to ensure Autocomplete internal state is updated
            Future.delayed(Duration.zero, () {
              _internalAutocompleteController?.clear();
            });
          });
        },
        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
          _internalAutocompleteController = controller;
          
          if (!focusNode.hasListeners) {
            focusNode.addListener(() {
              if (focusNode.hasFocus && controller.text.isEmpty) {
                // Trigger options list on focus
                controller.text = ' ';
                controller.text = '';
              }
            });
          }

          return TextField(
            controller: controller,
            focusNode: focusNode,
            onTap: () {
              if (controller.text.isEmpty) {
                controller.text = ' ';
                controller.text = '';
              }
            },
            decoration: InputDecoration(
              labelText: 'بحث بالاسم أو الكود',
              labelStyle: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
              prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.grey.shade100,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectAllAction(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(appDatabaseProvider).select(ref.read(appDatabaseProvider).persons).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final persons = snapshot.data!;
        
        final filteredCount = persons.where((p) {
          final stageMatch = _selectedStageId == null || p.stageId == _selectedStageId;
          final areaMatch = _selectedAreaId == null || p.areaId == _selectedAreaId;
          final genderMatch = _selectedGender == null || p.jenderName == _selectedGender;
          return stageMatch && areaMatch && genderMatch;
        }).length;

        final allFilteredSelected = filteredCount > 0 && persons.where((p) {
          final stageMatch = _selectedStageId == null || p.stageId == _selectedStageId;
          final areaMatch = _selectedAreaId == null || p.areaId == _selectedAreaId;
          final genderMatch = _selectedGender == null || p.jenderName == _selectedGender;
          return stageMatch && areaMatch && genderMatch;
        }).every((p) => _selectedPersons.any((sp) => sp.id == p.personId));

        return Row(
          children: [
            Checkbox(
              value: allFilteredSelected,
              onChanged: (val) {
                final filtered = persons.where((p) {
                  final stageMatch = _selectedStageId == null || p.stageId == _selectedStageId;
                  final areaMatch = _selectedAreaId == null || p.areaId == _selectedAreaId;
                  final genderMatch = _selectedGender == null || p.jenderName == _selectedGender;
                  return stageMatch && areaMatch && genderMatch;
                }).map((p) => PersonOption(id: p.personId, name: '${p.personId} - ${p.personName ?? ''}')).toList();

                setState(() {
                  if (val == true) {
                    _selectedPersons.addAll(filtered);
                  } else {
                    for (var item in filtered) {
                      _selectedPersons.removeWhere((sp) => sp.id == item.id);
                    }
                  }
                });
              },
              activeColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            const Text('اختيار الكل بناءً على الفلاتر', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            if (filteredCount > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text('($filteredCount مخدوم)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ),
          ],
        );
      },
    );
  }

  Widget _buildChartSection(BuildContext context, int? personId, String personName) {
    if (personId == null) return const SizedBox.shrink();
    final trendAsync = ref.watch(individualAttendanceTrendProvider(
        personId: personId,
        groupBy: _groupBy,
        filterYear: _groupBy == 'month' || _groupBy == 'day' ? _selectedYear : null,
        filterMonth: _groupBy == 'day' ? _selectedMonth : null,
        serviceId: _selectedServiceId,
        status: _selectedStatus,
      ));
    return trendAsync.when(
      data: (data) {
        if (data.isEmpty) return const SizedBox(height: 200, child: Center(child: Text('لا توجد بيانات حضور لهذا الشخص')));
        return Column(
          children: [
            SizedBox(
              height: 320,
              child: _buildChart(data),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(color: Colors.amber.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                    child: const Icon(Icons.insights, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      Storyteller.analyzeIndividualTrend(data, personName, _groupBy),
                      style: TextStyle(
                        fontWeight: FontWeight.w700, 
                        height: 1.6, 
                        fontSize: 15,
                        color: Colors.blueGrey.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
      error: (e, st) => Center(child: Text('خطأ: $e')),
    );
  }

  Widget _buildChart(List<AttendanceTrendData> data) {
    final displayData = data.length > 30 ? data.sublist(data.length - 30) : data;
    
    double maxY = 0;
    for(var d in data) {
      if (d.count > maxY) maxY = d.count.toDouble();
    }
    if (maxY < 5) maxY = 5;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY + 1,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(displayData.length, (index) {
              return FlSpot(index.toDouble(), displayData[index].count.toDouble());
            }),
            isCurved: true,
            color: Theme.of(context).primaryColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).primaryColor.withOpacity(0.2),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < displayData.length) {
                  final date = displayData[index].date;
                  String text;
                  if (_groupBy == 'day') {
                    text = '${date.day}';
                  } else if (_groupBy == 'month') {
                    text = '${date.month}';
                  } else {
                    text = '${date.year}';
                  }
                  return SideTitleWidget(
                    meta: meta,
                    space: 12,
                    child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 32,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
             getTooltipColor: (_) => Theme.of(context).primaryColor,
             getTooltipItems: (touchedSpots) {
               return touchedSpots.map((spot) => LineTooltipItem(
                 '${spot.y.toInt()} مرات',
                 const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
               )).toList();
             }
          ),
        ),
      ),
    );
  }
}
