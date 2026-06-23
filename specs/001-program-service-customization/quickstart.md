# Quickstart: Planning Verification

This feature must be implemented in phases. Stop after each phase and report tests, screenshots/manual checks, and risks before continuing.

## Baseline Commands

```powershell
flutter analyze
flutter test
```

If generated providers or Drift artifacts change:

```powershell
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

## Phase Verification Checklist

## Phase 1 Implementation Notes

- Identity consumers found and updated: `lib/main.dart`, `lib/screens/login_screen.dart`, `lib/screens/main_shell.dart`, and `lib/screens/services_management_screen.dart`.
- Settings storage uses `Settings.program_name` through `SettingsRepository`, with fallback to `برنامج مدارس الأحد`.
- Existing test entry points inspected: `test/widget_test.dart`, `test/print_progress_dialog_test.dart`, `test/print_generators_test.dart`, `test/pdf_test.dart`; focused Phase 1 tests are `test/program_identity_test.dart` and `test/program_identity_widget_test.dart`.
- Automated validation commands were intentionally not run because this implementation was invoked with a request to skip `dart format`, `dart analyze`, `flutter analyze`, and `flutter test`.

## Phase 2 Implementation Notes

- Added `CardTemplate` JSON model and Settings persistence under `id_card_active_template`.
- Added `CardDesignerPreview` with fixed aspect ratio, RTL field rendering, khoros field support, fixed text rendering, photo placeholder, and background fit modes.
- Added a designer mode inside `IdCardScreen`; the existing simple card-print settings and person-selection flow remain available.
- Added focused tests: `test/card_template_test.dart` and `test/card_designer_widget_test.dart`.
- Automated validation commands were intentionally not run because this implementation was invoked with a request to skip `dart format`, `dart analyze`, `flutter analyze`, and `flutter test`.

## Phase 3 Implementation Notes

- Extended `CardTemplate` with barcode/QR options, barcode background mode, and free image elements.
- Added designer controls for barcode/QR type, position, size, white/transparent background, image add/remove, image positioning, and image fit.
- Added template PDF rendering to `IdCardPdfGenerator` while preserving the legacy simple-card path when no template is supplied.
- Added a designer print action that uses the existing progress dialog and print handoff.
- Added focused tests in `test/card_template_test.dart` and `test/print_generators_test.dart`.
- Automated validation commands were intentionally not run because this implementation was invoked with a request to skip `dart format`, `dart analyze`, `flutter analyze`, and `flutter test`.
- Manual Code128/QR scan verification and visual PDF review are still required.

## Phase 4 Implementation Notes

- Added `PdfExportOptions` for auto/portrait/landscape orientation, stretch-to-fit sizing, and grouped export mode.
- Updated attendance list/grid PDF generation to accept export options and preserve default auto-orientation behavior.
- Updated attendance grid PDF cells so selecting points renders the point value beside the attendance mark and hides the points-only generated columns.
- Added grouped PDF writing with Arabic-safe file names and destination-folder selection for attendance list/grid exports.
- Added option controls in the sorting/export dialog for page orientation, stretch-to-fit, and single-PDF vs separate-PDF grouped output.
- Added focused tests in `test/attendance_grid_display_test.dart`, `test/group_export_test.dart`, and `test/print_generators_test.dart`.
- Automated validation commands were intentionally not run because this implementation was invoked with a request to skip `dart format`, `dart analyze`, `flutter analyze`, and `flutter test`.
- Manual portrait/landscape PDF inspection, wide-grid review, and separate-group export smoke testing are still required.

## Phase 5 Implementation Notes

- Added service link tables for `Khoros_Services` and `Stage_Services` while preserving legacy `Service_ID` columns.
- Added raw startup/migration repair so existing version-32 databases still create and seed the new link tables without requiring generated Drift getters.
- Updated khoros/stage repositories to read and write multiple service links and preserve legacy single-service reads.
- Added `ServiceEligibilityRepository` checks for direct person services plus stage and khoros service unions.
- Added attendance UI/repository rejection for invalid person/service pairs, including scanner-driven attendance through the same submit path.
- Added focused tests: `test/service_links_migration_test.dart`, `test/service_eligibility_test.dart`, and `test/attendance_service_restriction_test.dart`.
- `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze`, and targeted tests were intentionally not run per the request to skip long Dart/Flutter commands.
- Manual multi-service group/stage edit, invalid attendance, scanner, upgraded database, and backup/restore smoke checks are still required.

### Phase 1

- Program name defaults to `برنامج مدارس الأحد`.
- Services Management can save and clear `اسم البرنامج`.
- Login and shell identity update after restart.
- Existing church name/logo still work.

### Phase 2

- Card designer opens from Card tab.
- Preview shows existing fields plus `الخورس`.
- Label visibility works with global default and per-field override.
- Fixed text and background fit modes visibly update preview.
- Legacy card print flow still opens and generates a PDF.

### Phase 3

- Barcode/QR position, size, and background mode update preview.
- Code128 and QR still encode person ID.
- White and transparent backgrounds print.
- Manual scan test succeeds for allowed sizes.

### Phase 4

- Attendance grid shows check mark and points in the same visible cell.
- No points-only visible column appears.
- Attendance save/load unchanged.
- PDF exports support portrait/landscape and stretch-to-fit.
- Separate group PDFs generate one file per group in a chosen folder.

### Phase 5

- Existing single-service khoros/stage assignments migrate into multi-service selections.
- Khoros/stage can select multiple services.
- Members get union eligibility from explicit services, khoros, and stage.
- Invalid service attendance is rejected before save and during save.
- Existing valid attendance still saves.

### Phase 6

- Behavior tab supports multiple services.
- Default score is 5.
- Missing behavior counts as 5 in term closing and analysis.
- Explicit 0 remains 0.
- Old behavior records remain valid.

### Phase 7

- Arabic RTL polish pass on all changed screens.
- Desktop and mobile responsive pass.
- Long Arabic names do not overflow.
- Manual PDF visual pass with representative data.
- Backup/restore sanity check after migration.

## Manual Print/PDF Data Set

Use test data with:

- Long Arabic person names.
- Empty optional phone/street/father/khoros fields.
- Multiple services on different weekdays.
- Khoros and stage linked to different services.
- A person with explicit service, inherited khoros service, inherited stage service, and no service.
- Behavior records: missing, null, 0, 5, and 7.
- Wide attendance date range with many date/service columns.
- Group names with Arabic and unsafe filename characters.
