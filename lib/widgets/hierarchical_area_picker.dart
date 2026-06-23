import 'package:flutter/material.dart';
import '../database/database.dart'; // Drift Area class

class HierarchicalAreaPicker extends StatefulWidget {
  final List<Area> allAreas;
  final int? initialAreaId;
  final String? rootLabel;
  final ValueChanged<int?> onChanged;

  const HierarchicalAreaPicker({
    super.key,
    required this.allAreas,
    this.initialAreaId,
    this.rootLabel,
    required this.onChanged,
  });

  @override
  State<HierarchicalAreaPicker> createState() => _HierarchicalAreaPickerState();
}

class _HierarchicalAreaPickerState extends State<HierarchicalAreaPicker> {
  // Ordered selection of area IDs from root to the deepest selected child
  List<int?> _selectedPath = [];
  late Map<int, Area> _areaMap;

  @override
  void initState() {
    super.initState();
    _areaMap = {for (var a in widget.allAreas) a.areaId: a};
    _buildInitialPath();
  }

  @override
  void didUpdateWidget(covariant HierarchicalAreaPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.allAreas != oldWidget.allAreas || widget.initialAreaId != oldWidget.initialAreaId) {
      _areaMap = {for (var a in widget.allAreas) a.areaId: a};
      if (widget.initialAreaId != _getFinalSelectedId()) {
         _buildInitialPath();
      }
    }
  }

  void _buildInitialPath() {
    _selectedPath.clear();
    int? currentId = widget.initialAreaId;
    while (currentId != null) {
      _selectedPath.insert(0, currentId);
      final currentArea = _areaMap[currentId];
      currentId = currentArea?.parentId;
    }
    // ensure at least one dropdown for root is shown if nothing selected
    if (_selectedPath.isEmpty) {
      _selectedPath = [null];
    } else {
      // Check if the deepest selected has children. If so, add a null for the next unselected level
      final deepestId = _selectedPath.last;
      if (deepestId != null) {
        final hasChildren = widget.allAreas.any((a) => a.parentId == deepestId);
        if (hasChildren) {
          _selectedPath.add(null);
        }
      }
    }
  }

  int? _getFinalSelectedId() {
    // Return the deepest non-null ID
    for (int i = _selectedPath.length - 1; i >= 0; i--) {
      if (_selectedPath[i] != null) return _selectedPath[i];
    }
    return null;
  }

  void _onDropdownChanged(int index, int? newValue) {
    setState(() {
      _selectedPath[index] = newValue;
      // Truncate any paths after this index because the parent changed
      _selectedPath.length = index + 1;
      
      if (newValue != null) {
        // If this new value has children, expand with a new null selection
        final hasChildren = widget.allAreas.any((a) => a.parentId == newValue);
        if (hasChildren) {
          _selectedPath.add(null);
        }
      } else if (index > 0) {
        // If they select "Choose..." on a sub-level, the final selection becomes the parent
        // We do nothing else here, final selection will be recalculated correctly.
      }
    });

    widget.onChanged(_getFinalSelectedId());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_selectedPath.length, (index) {
        final parentId = index == 0 ? null : _selectedPath[index - 1];
        
        // Options for this level are areas that have this parentId
        final options = widget.allAreas.where((a) => a.parentId == parentId).toList();
        
        // If no options (should rarely happen due to logic, but just in case), return nothing
        if (options.isEmpty) return const SizedBox.shrink();

        final label = index == 0 
            ? (widget.rootLabel ?? 'المحافظة / المنطقة الرئيسية') 
            : 'فرع / منطقة فرعية (المستوى ${index + 1})';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: DropdownButtonFormField<int?>(
            value: _selectedPath[index],
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(index == 0 ? Icons.map_outlined : Icons.subdirectory_arrow_left),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            isExpanded: true,
            items: [
              DropdownMenuItem<int?>(
                value: null,
                child: Text('--- اختر $label ---', style: const TextStyle(color: Colors.grey)),
              ),
              ...options.map((a) {
                return DropdownMenuItem<int?>(
                  value: a.areaId,
                  child: Text(a.areaName ?? ''),
                );
              }),
            ],
            onChanged: (val) => _onDropdownChanged(index, val),
          ),
        );
      }),
    );
  }
}
