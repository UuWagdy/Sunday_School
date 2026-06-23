# Implementation Plan: Configurable Program Identity, Card Designer, Exports, Services, and Behavior Scoring

**Branch**: `001-program-service-customization` | **Date**: 2026-06-18 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-program-service-customization/spec.md`

## Summary

Extend the existing Arabic RTL Flutter application without rebuilding it. The work will add a global configurable program name, a richer ID card preview/designer, barcode/QR customization, attendance grid display fixes, PDF export controls, separate grouped PDF export, multi-service Khoros/stage service eligibility, and behavior scoring fixes where missing behavior counts as 5. The implementation must reuse the existing Flutter Material/Riverpod/Drift/PDF stack, current Settings pattern, current repository/screen/service boundaries, and existing phased delivery rule.

## Technical Context

**Language/Version**: Dart SDK `^3.11.0`, Flutter app from `pubspec.yaml`
**Primary Dependencies**: Flutter Material/localizations, `flutter_riverpod`/`riverpod_annotation`, Drift/SQLite (`drift`, `sqlite3`, `sqlite3_flutter_libs`), `pdf`, `printing`, `barcode`, `mobile_scanner`, `file_picker`, `image_picker`, `excel`, `shared_preferences`, `url_launcher`, `fl_chart`
**Storage**: Drift/SQLite database copied from `assets/database/Betros_Bols.db` into app documents; `Settings` table for app/card settings; BLOB columns for service/khoros/person images; some existing Tayo print settings use `shared_preferences`
**Testing**: Existing `flutter_test` suite, PDF generation tests, widget tests, `flutter analyze`; manual verification required for native print dialogs, scanning, and PDF visual layout
**Target Platform**: Existing Flutter targets in `android/`, `ios/`, `web/`, `windows/`; current app is desktop-first with responsive mobile branches
**Project Type**: Existing Arabic Sunday School management Flutter application with no separate backend server
**Performance Goals**: Preserve responsive admin workflows; avoid blocking UI during PDF generation; keep large PDF generation in existing isolate/progress pattern; avoid attendance save latency noticeable to users
**Constraints**: Arabic RTL UI and output, no rewrite, no major new framework, preserve data, safe Drift migrations, no PDF/table overflow, explicit Arabic validation and feedback, phased implementation with review stop after each phase
**Scale/Scope**: Seven phases, each limited to one or two related areas; implementation tasks must not combine unrelated phases into one pass

## Existing Project Discovery

### Stack and App Shell

- `lib/main.dart`: Flutter `MaterialApp`, Arabic locale, global `ProviderScope`, `MainShell` as home, static app title currently `Sunday School`.
- `lib/theme/app_theme.dart`: Material 3 visual system, deep blue primary `0xFF1A237E`, gold secondary `0xFFC5A059`, white cards, rounded 12-16px controls/cards, Arial app font.
- `lib/screens/main_shell.dart`: login routing, permissions-based navigation, desktop `NavigationRail`, mobile app bar/drawer, hardcoded app identity text.
- No backend framework was found. Persistence and business logic are local app code over Drift/SQLite.

### State, Routing, Data, and Migration

- State management: Riverpod providers and generated providers in repositories/services, e.g. `servicesRepositoryProvider`, `personsRepositoryProvider`, `attendanceRepositoryProvider`, `khorosRepositoryProvider`, `stagesRepositoryProvider`.
- Navigation/routing: direct `MaterialPageRoute` only where needed; main navigation is in `MainShell`, not `go_router`.
- Database schema: `lib/database/tables.dart` and generated `database.g.dart`.
- Migration strategy: `lib/database/database.dart`, `AppDatabase.schemaVersion == 31`, `MigrationStrategy.onUpgrade`, `_createTableSafely`, `_addColumnSafely`, `_ensureAllColumnsAndTablesExist`, `_repairPassTableRaw`, `_repairBrokenIds`. Any schema change must increment schema version and use these helpers.
- Seed database: `assets/database/Betros_Bols.db` copied by `_openConnection`.

### Current Affected Modules

- Login/program identity: `lib/screens/login_screen.dart`, `lib/screens/main_shell.dart`, `lib/main.dart`.
- Services/settings: `lib/screens/services_management_screen.dart`, `lib/repositories/settings_repository.dart`, `lib/repositories/services_repository.dart`, `Settings` table.
- Card tab/printing: `lib/screens/id_card_screen.dart`, `lib/services/id_card_pdf_generator.dart`, `lib/widgets/print_progress_dialog.dart`, `test/print_generators_test.dart`.
- Barcode/QR: `barcode` package in `id_card_pdf_generator.dart`; `Barcode.code128()` and `Barcode.qrCode()`; scanner in `lib/screens/qr_scanner_screen.dart` using `mobile_scanner`.
- Attendance: `lib/screens/attendance_screen.dart`, `lib/repositories/attendance_repository.dart`, `lib/ui/dialogs/print_period_services_dialog.dart`, `lib/ui/dialogs/sorting_dialog.dart`.
- PDF exports: `lib/services/attendance_report_service.dart`, `lib/services/attendance_grid_pdf_generator.dart`, `lib/services/person_report_service.dart`, `lib/services/term_attendance_pdf_service.dart`, `lib/services/family_report_pdf_generator.dart`, `lib/services/tayo_report_pdf_generator.dart`, `lib/services/report_generator.dart`.
- Grouped exports: `SortingDialog._separatePages`, `AttendanceReportService` and `AttendanceGridPdfGenerator` `separatePages`.
- Choruses/groups: `lib/screens/khoros_screen.dart`, `lib/repositories/khoros_repository.dart`, `Khoroses` table.
- Stages/classes: `lib/screens/stages_screen.dart`, `lib/repositories/stages_repository.dart`, `Stages` table.
- People/service eligibility: `lib/repositories/persons_repository.dart`, `PersonServices` table, person dialog service selection in `lib/screens/person_dialog.dart`.
- Behavior and analysis: `lib/screens/behavior_screen.dart`, `lib/repositories/attendance_repository.dart`, `lib/repositories/term_attendance_repository.dart`, `lib/widgets/dashboard/term_attendance_closure_widget.dart`, `lib/screens/reports_screen.dart`, `lib/repositories/reports_repository.dart`, `lib/repositories/period_comparison_repository.dart`.

### Current Domain Behavior

- Program identity is hardcoded in login and shell UI. Services Management already manages global `church_name` and `church_logo` through `SettingsRepository`, making it the natural location for global program name configuration.
- Card printing currently supports one active set of card settings stored in `Settings` keys prefixed with `id_card_`, encoded image bytes for logo/backgrounds, fixed front/back layout, visible field toggles, and code type `barcode` or `qr`.
- Current card fields are `name`, `code`, `stage`, `area`, `street`, `phone`, `mobile`, `father`, `photo`; `PersonListDTO` already has `khorosName` and `khorosId` but card UI/generator do not expose it.
- Current card code data is `person.id.toString()`. Code128 barcode uses width `width * 0.8`, height `35`; QR uses `50 x 50`.
- Services, stages, and khoroses each have single service relationship fields today: `Stages.Service_ID`, `Khoroses.Service_ID`; people have many services through `Person_Services`.
- Person add/update resolves service eligibility as the union of explicit person services, stage service, and khoros service. Stage/khoros repository updates also sync existing members and remove old inherited service if no other assignment still needs it.
- Attendance save currently validates selected person, selected service, and service weekday before calling `AttendanceRepository.addAttendance`; it does not validate whether the selected person is eligible for the selected service.
- Behavior score is integer 0-7 in `BehaviorScreen`; default displayed value is 5; `Coming.Behavior` defaults to 5. `TermAttendanceRepository` treats null behavior on existing rows as 5 but uses average 0 when a person has no behavior rows for possible meetings.

## Constitution Check

*GATE: PASS before Phase 0 research. Re-check after Phase 1 design.*

- **Existing Project First**: PASS. Inspected app shell, theme, database/migration, repositories, affected screens, PDF services, barcode/scanner, settings, tests, and export dialogs listed above.
- **Product vs Technical Separation**: PASS. Product requirements remain in `spec.md`; this plan documents how the existing implementation will be extended.
- **Arabic RTL Product**: PASS. All new controls/messages/print/PDF/export strings must be Arabic and wrapped in existing RTL patterns; generated PDFs must use existing Amiri/Arabic-capable font loading.
- **Backward Compatibility**: PASS. Existing login, permissions, card printing, attendance save/load, scanning, services, khoros/stage management, reports, grouped new-page export, behavior records, analysis, backup/restore, and maintenance must remain functional after each phase.
- **Data and Migration Safety**: PASS. Schema changes will use Drift table definitions and `database.dart` migration helpers, increment schema version, preserve old `Service_ID` data into new link tables, and keep old columns during migration for compatibility until code fully reads new links.
- **UI/UX Quality**: PASS. UI must follow existing Material 3 blue/gold theme and responsive Card/form/dialog patterns while improving card designer and export option polish with clear sections, icon buttons, segmented controls, sliders, color controls, validation states, and no overflow.
- **Validation and Safety**: PASS. Program name, image files, template JSON/settings, sizes/positions, barcode background/readability, PDF options, destination folder/file names, service eligibility, behavior score range, and empty exports all need Arabic feedback.
- **Printing and Export Reliability**: PASS. Card, barcode, table export, orientation, stretch-to-fit, group splitting, Arabic fonts, and long Arabic names require PDF/manual visual checks with representative data.
- **Incremental Delivery**: PASS. This plan defines seven stop-and-review phases; tasks must preserve the stop point after each phase.

## Project Structure

### Documentation (this feature)

```text
specs/001-program-service-customization/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   |-- ui-contracts.md
|   \-- export-contracts.md
\-- tasks.md
```

### Source Code (repository root)

```text
lib/
|-- database/       # Drift database, tables, migrations, generated artifacts
|-- repositories/   # Drift-backed query and persistence boundaries
|-- screens/        # Arabic RTL Material screens and dialogs
|-- services/       # Auth, PDF, printing, export, backup, and domain services
|-- theme/          # Existing visual identity and shared theme
|-- ui/dialogs/     # Shared option dialogs
|-- widgets/        # Shared and dashboard widgets
\-- models/         # Existing lightweight DTOs/value models

test/               # Flutter widget/unit/PDF tests
assets/             # Seed database, fonts, logos, print assets
```

**Structure Decision**: Reuse existing feature-first screens plus repository/service boundaries. Add small focused models/helpers where needed under existing folders, for example card designer model helpers near card code, PDF export option helpers near PDF services, and service eligibility helpers near repositories. Do not add a new architecture layer or routing framework.

## Technical Design by Feature Area

### 1. Discovery Plan

Phase 1 starts with a no-code audit that records exact current behavior and affected lines before edits. Required files/modules:

- Identity: `main.dart`, `login_screen.dart`, `main_shell.dart`, `services_management_screen.dart`, `settings_repository.dart`.
- Cards: `id_card_screen.dart`, `id_card_pdf_generator.dart`, `persons_repository.dart`, `fields_repository.dart`, `print_progress_dialog.dart`, card PDF tests.
- Barcode/scanner: `id_card_pdf_generator.dart`, `qr_scanner_screen.dart`, attendance scanner flow in `attendance_screen.dart`.
- Attendance/export: `attendance_screen.dart`, `attendance_repository.dart`, `sorting_dialog.dart`, `print_period_services_dialog.dart`, `attendance_report_service.dart`, `attendance_grid_pdf_generator.dart`.
- Reports/analysis: `reports_screen.dart`, `report_generator.dart`, `person_report_service.dart`, `family_report_pdf_generator.dart`, `term_attendance_repository.dart`, `term_attendance_pdf_service.dart`, `term_attendance_excel_service.dart`, dashboard widgets.
- Services/groups/stages: `services_repository.dart`, `khoros_repository.dart`, `stages_repository.dart`, `person_dialog.dart`, `persons_repository.dart`, `transfer_screen.dart`.
- Database: `tables.dart`, `database.dart`, generated Drift files, backup/restore service.
- Tests: all files in `test/`, plus manual print/PDF/scanner checklist in `quickstart.md`.

### 2. Configurable Program Name

- Store a single global setting in the existing `Settings` table through `SettingsRepository`, using a new key such as `program_name`.
- Default fallback is `برنامج مدارس الأحد` when the value is null, empty, or whitespace.
- Add a small read helper in `SettingsRepository` or a focused provider/helper so `login_screen.dart`, `main_shell.dart`, and `main.dart` can consume the same value without duplicate fallback logic.
- Place edit controls near existing church identity controls in `services_management_screen.dart` because that screen already edits `church_name` and `church_logo`.
- Update current hardcoded references in login title, shell app bars/drawer/account text/about dialog, and app title where appropriate. Preserve unrelated labels such as service names and church name.
- Validate trimmed Arabic/free-text names: reject empty, clamp/display long values gracefully in headings, and show Arabic SnackBar/dialog feedback.

### 3. Card Preview / Designer

- Add a new page/screen under the Card tab by extending `IdCardScreen` with a tab/segmented mode or child screen; keep existing print form as the simple/legacy flow.
- Introduce one active card template first, persisted through existing storage conventions. Use the `Settings` table with encoded structured template data and image bytes, because current ID card settings already use `Settings` keys and base64 images.
- Add a template model for:
  - Card size/layout units.
  - Data fields: existing fields plus `khorosName`/`khoros`.
  - Field label mode: global default plus per-field override.
  - Text style: color, size, and position.
  - Fixed custom text elements.
  - Image elements and background image.
  - Background fit: shrink-to-fit, zoom-to-fit, actual-size.
  - Barcode/QR element type, size, position, and background mode.
- Preview should render in the app before PDF print. Use the same template data to render both preview and PDF to prevent divergent layouts.
- Existing `IdCardPdfGenerator.generateCards/startCardGeneration` should gain optional template input while preserving the current parameter-based flow for legacy printing.
- Position and size controls should use constrained numeric inputs/sliders and responsive preview bounds. Store values in normalized card coordinates to survive preview scaling.
- Validate image selection, oversized images, empty fixed text, text size, off-card positions, barcode minimum size, and unreadable barcode background. All feedback in Arabic.

### 4. Barcode Customization

- Preserve current encoded data: `person.id.toString()`.
- Preserve current user choice between Code128 barcode and QR code.
- Reduce default code element size in the new designer relative to current fixed barcode; do not alter legacy simple print defaults unless the phase explicitly updates them after review.
- Add template controls for size, x/y position, white/transparent background.
- Scannability safeguards:
  - Enforce minimum module/visual size per code type.
  - Warn when transparent background is placed over a busy/dark image.
  - Keep optional quiet-zone padding in white-background mode.
  - Require manual scan verification in Phase 3 before sign-off.

### 5. Attendance Grid Points Display

- Locate current grid cell rendering in `attendance_screen.dart` and PDF grid rendering in `attendance_grid_pdf_generator.dart`.
- In UI grid view, combine check mark and points in the same date/service cell when points display is enabled.
- Do not change `Coming.Point`, save/load queries, attendance DTOs, or attendance persistence.
- Preserve current table readability by using compact RTL cell content such as `✓ 5` or Arabic-friendly equivalent, with consistent alignment and no separate points-only visible column.
- Confirm matching behavior in PDF grid only if the existing PDF grid currently separates check/points; otherwise keep PDF changes scoped to stretch-to-fit.

### 6. PDF Table Export Improvements

- Add a reusable export option model/contract for orientation and stretch-to-fit. Integrate first into attendance list/grid and term attendance because those are the widest/most critical table exports.
- Extend `SortingDialog` and/or `PrintPeriodServicesDialog` carefully so existing callers can opt into export options without breaking non-attendance report flows.
- Use current `pdf`/`printing` services and Amiri font loading. No new PDF framework.
- Scaling strategy:
  - Determine page format from explicit user orientation.
  - Compute available page width/height after margins and headers.
  - Use column count/row count to choose font size within readable bounds.
  - For wide tables, prefer landscape and smaller font; for tall tables, paginate chunks.
  - Stretch-to-fit disabled preserves existing auto-orientation behavior.
- Apply in phases:
  - Phase 4 required: `AttendanceReportService`, `AttendanceGridPdfGenerator`, `TermAttendancePdfService`.
  - Later follow-up after review: `PersonReportService`, `FamilyReportPdfGenerator`, `TayoReportPdfGenerator`, `ReportGenerator` if the same option is accepted broadly.

### 7. Grouping Export Separate PDFs

- Current grouped export has one-PDF "new page per group" via `SortingDialog._separatePages` and generator `separatePages`.
- Add an export grouping mode with Arabic choices:
  - كل مجموعة تبدأ في صفحة جديدة
  - كل مجموعة في ملف PDF منفصل
- Output destination should use `FilePicker.platform.getDirectoryPath` or the closest existing platform-supported folder picker. If unavailable on a platform, fall back to a clear Arabic error or existing print flow.
- Generate one PDF per top-level selected grouping key, using the same filtered data and selected columns.
- Use Arabic-safe file names by sanitizing path-unsafe characters, preserving readable Arabic text, adding service/date suffixes, and de-duplicating duplicate group names.
- Empty groups should be reported in Arabic; do not silently create confusing empty files unless the user explicitly chooses that behavior later.

### 8. Multi-Service Choruses/Groups and Stages

- Add many-to-many link tables:
  - `Khoros_Services` with `Khoros_ID`, `Service_ID`.
  - `Stage_Services` with `Stage_ID`, `Service_ID`.
- Preserve old `Khoroses.Service_ID` and `Stages.Service_ID` during migration and initial compatibility; migrate existing non-null values into the new link tables.
- Increment `schemaVersion` and update `tables.dart`, `database.dart`, generated Drift files, and `_ensureAllColumnsAndTablesExist`.
- Update `KhorosModel` and `StageModel` to carry service ID lists while preserving single `serviceId` compatibility where needed during transition.
- Update `khoros_screen.dart` and `stages_screen.dart` service controls from single dropdowns to RTL multi-select controls matching existing filter UX.
- Eligibility rule: union of explicit person services, khoros services, and stage services. If khoros and stage services differ, the person is eligible for all linked services.
- When a khoros/stage service list changes, sync existing members:
  - Add newly linked services to `Person_Services`.
  - Remove services inherited only from that khoros/stage when no explicit person service or other inheritance source still requires them.
  - Avoid duplicates through primary keys/upserts.
- Add a repository/helper that computes person eligibility consistently for person save/update, bulk transfer, attendance validation, term reports, and visibility filters where applicable.

### 9. Attendance Restriction

- Validate in UI before save:
  - When a person is selected by autocomplete, submitted code, or QR scan, check current selected service eligibility and show Arabic rejection before calling save.
- Validate again in `AttendanceRepository.addAttendance` to protect all callers and bulk/checkout paths.
- Suggested message: `هذا الشخص غير مرتبط بالخدمة المحددة ولا يمكن تسجيل حضوره فيها.`
- Preserve existing day-of-week validation and duplicate-attendance messages.
- Record no invalid `Coming` row on rejection.

### 10. Behavior Multi-Service Scoring

- Update `BehaviorScreen` service selector from single service to multi-select using current multi-select/filter style.
- Save behavior for each selected service/person/date combination through existing `Coming` behavior records or a focused extension to `saveBehaviorScores`.
- Keep valid score range 0-7 and default displayed score 5.
- Treat missing record as 5 in calculations. Explicit stored `0` remains `0`.
- Update `TermAttendanceRepository` so `averageBehavior` uses possible person/service meetings, adding 5 when no behavior row exists for a possible meeting.
- Update relevant analysis/report outputs that show behavior, including `reports_repository.dart`, `reports_screen.dart`, `report_generator.dart`, and term attendance PDF/Excel services if they derive behavior display.
- Preserve old `Coming.Behavior` records and avoid creating rows just to represent default 5 unless the user explicitly saves behavior.

## Phase Plan

### Phase 1: Discovery, Program Name, and Safe Plumbing

- Confirm all hardcoded app identity strings and settings consumers.
- Add global program name settings helper/provider using `SettingsRepository`.
- Add Services Management edit/delete UI near church identity card.
- Update login/shell/app title consumers.
- Tests: widget test for login fallback/custom name; repository/helper test for fallback; `flutter analyze`.
- Stop point: program name works and no other feature behavior changed.

### Phase 2: Card Designer Foundation

- Add card designer page/mode under Card tab.
- Add active template model stored in Settings.
- Add preview for existing person fields plus khoros field, label modes, fixed text, background image, background fit modes, text size/color/position.
- Keep legacy print flow unchanged.
- Tests: template parse/validation unit tests; widget smoke test for designer; manual responsive preview.
- Stop point: preview-only designer foundation reviewed before print integration.

### Phase 3: Barcode, Images, Template Persistence, and Card Print Integration

- Add image elements, barcode/QR position/size/background controls, scannability warnings.
- Integrate template rendering into PDF generator while preserving legacy generator behavior.
- Add reduced default barcode size for designer template.
- Tests: PDF generation with template, barcode data preservation, image/background modes; manual print and scan checklist.
- Stop point: designed cards can print; legacy cards still print.

### Phase 4: Attendance Grid and PDF Export Improvements

- Render check mark and points in one visible attendance grid cell.
- Add PDF export options for orientation/stretch-to-fit for attendance list/grid and term attendance.
- Add grouped export mode for separate PDFs per top-level group with safe folder output and file names.
- Tests: attendance grid widget/rendering checks, PDF generation tests for orientation/stretch options, manual grouped output check.
- Stop point: export changes reviewed before database-heavy service changes.

### Phase 5: Multi-Service Khoros/Stage Relationships and Attendance Rules

- Add Drift tables and migration for `Khoros_Services` and `Stage_Services`.
- Migrate existing single-service assignments into new link tables.
- Update repositories/screens/person sync/transfer sync for union eligibility.
- Add UI/service validation and repository-level attendance rejection.
- Tests: migration tests, repository eligibility tests, attendance rejection tests, manual old data upgrade.
- Stop point: multi-service eligibility stable before behavior changes.

### Phase 6: Behavior Multi-Service and Default 5 Corrections

- Add multi-service selection to Behavior tab.
- Save behavior across selected services.
- Correct term closing and analysis behavior missing-value handling.
- Preserve explicit `0` behavior if recorded.
- Tests: behavior repository tests, term report calculation tests, old behavior data regression tests.
- Stop point: scoring verified before final polish.

### Phase 7: Final Regression, UI Polish, Accessibility, and Documentation

- Full Arabic RTL pass across changed screens/dialogs.
- Responsive desktop/mobile pass.
- Accessibility semantics where controls are custom.
- Regression checklist for login, services, cards, scanning, attendance, exports, groups/stages, behavior, analysis, backup/restore.
- Final docs/checklists and manual PDF/print artifacts.

## Data and Migration Plan

- Phase 1-4 should avoid schema changes unless card template size makes Settings JSON impractical. Prefer `Settings` keys for program name and active card template to align with current card settings.
- Phase 5 requires schema version increment from 31 to 32 or next available version.
- New tables:
  - `Khoros_Services(Khoros_ID, Service_ID)` primary key on both columns.
  - `Stage_Services(Stage_ID, Service_ID)` primary key on both columns.
- Migration steps:
  - Create new tables safely.
  - Insert one link for each non-null `Khoroses.Service_ID`.
  - Insert one link for each non-null `Stages.Service_ID`.
  - Preserve old columns during the transition.
  - Ensure all tables exist in `_ensureAllColumnsAndTablesExist`.
  - Regenerate Drift artifacts.
- Backup/restore: inspect `database_backup_service.dart` before Phase 5 to ensure restored older databases get the new tables and migrated links.

## Testing and Regression Strategy

- Always run `flutter analyze` after each phase.
- Add focused unit/repository tests for settings fallback, card template validation, service eligibility, attendance rejection, and behavior default calculations.
- Extend existing PDF tests in `test/print_generators_test.dart` for card template rendering and export options.
- Add widget tests where provider overrides can isolate UI: login program name, behavior default score/multi-service selector, attendance rejection UI, card designer smoke test.
- Native print dialogs and camera scanning remain manual due current test limitations and skipped native printing tests.
- Manual print/PDF checklist must cover Arabic long names, empty fields, many columns, many rows, transparent barcode background, white barcode background, QR and Code128, portrait/landscape, stretch disabled/enabled, separate grouped files, empty groups.

## Post-Design Constitution Check

- **Existing Project First**: PASS. Design reuses current app modules and names concrete files.
- **Product vs Technical Separation**: PASS. No product requirement changes introduced here.
- **Arabic RTL Product**: PASS. All new UI/output strings are required Arabic/RTL.
- **Backward Compatibility**: PASS. Each phase has explicit legacy-flow preservation and review stop.
- **Data and Migration Safety**: PASS. Only Phase 5 changes schema and follows existing Drift migration path.
- **UI/UX Quality**: PASS. Design follows existing Material 3 theme while requiring responsive, accessible, polished controls.
- **Validation and Safety**: PASS. Validation points are identified for all risky inputs and outputs.
- **Printing and Export Reliability**: PASS. PDF/card/export work includes automated generation tests plus manual visual/scanning checks.
- **Incremental Delivery**: PASS. Seven phases with bounded stop points.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |
