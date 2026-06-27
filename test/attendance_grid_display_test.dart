import 'package:flutter_test/flutter_test.dart';
import 'package:petros_pols_flutter/services/attendance_grid_pdf_generator.dart';

void main() {
  test('selected points render in attendance date cells instead of a visible column', () {
    final columns = [
      {'id': 'name', 'title': 'Name'},
      {'id': 'points', 'title': 'Points'},
    ];
    final dates = ['2026-06-11|Service'];

    expect(
      AttendanceGridPdfGenerator.shouldRenderPointsInAttendanceCells(
        columns,
        dates,
      ),
      isTrue,
    );
    expect(
      AttendanceGridPdfGenerator.attendanceCellLabel(
        attended: true,
        points: 2,
        showPoints: true,
      ),
      'check (2)',
    );
  });

  test('points are hidden when attendance date cells are not available', () {
    final columns = [
      {'id': 'points', 'title': 'Points'},
    ];

    expect(
      AttendanceGridPdfGenerator.shouldRenderPointsInAttendanceCells(
        columns,
        const [],
      ),
      isFalse,
    );
  });
}
