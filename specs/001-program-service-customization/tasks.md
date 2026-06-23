# Tasks: Configurable Program Identity, Card Designer, Export Improvements, Service Rules, and Behavior Scoring

**Input**: Design documents from `specs/001-program-service-customization/`
**Prerequisites**: `specs/001-program-service-customization/spec.md`, `specs/001-program-service-customization/plan.md`, `specs/001-program-service-customization/research.md`, `specs/001-program-service-customization/data-model.md`, `specs/001-program-service-customization/contracts/`

**Stack confirmed by discovery**: Flutter/Dart, Material 3 RTL Arabic UI, Riverpod, Drift/SQLite, `pdf`/`printing`, `barcode`, `file_picker`/`image_picker`, existing migrations in `lib/database/database.dart`.

**Testing note**: Add tests before or alongside risky changes where practical. Run `dart run build_runner build --delete-conflicting-outputs` only after Drift/Riverpod generated-source changes.

**Task format**: `- [ ] T### [P?] [US?] Goal: ...; Files: ...; Dependencies: ...; Validation: ...; Risk: ...`

## Phase 1: Discovery + Configurable Program Name (US1)

**Goal**: Establish a safe baseline, then make the current hardcoded program identity configurable with fallback to `برنامج مدارس الأحد`.
**Independent review**: A reviewer can change the program name, restart the app, and confirm login/internal title text updates without unrelated label changes.

### Discovery and Safety Baseline

- [X] T001 Goal: Capture the exact baseline locations for identity text, settings, login, services, and shell navigation before editing; Files: `lib/screens/login_screen.dart`, `lib/screens/services_management_screen.dart`, `lib/main.dart`, `lib/repositories/settings_repository.dart`; Dependencies: none; Validation: findings recorded in `quickstart.md`; Risk: Low, discovery only.
- [X] T002 [P] Goal: Inventory current tests and identify the smallest test entry points for settings and login title behavior; Files: `test/widget_test.dart`, `test/print_progress_dialog_test.dart`, `test/print_generators_test.dart`, `test/pdf_test.dart`; Dependencies: none; Validation: test entry points identified; execution skipped per user instruction; Risk: Low, discovery only.
- [X] T003 [P] Goal: Run static baseline to expose pre-existing analyzer issues before feature work; Files: `analysis_options.yaml`, `pubspec.yaml`; Dependencies: none; Validation: `flutter analyze` skipped per user instruction; Risk: Low, command only.

### Tests for User Story 1

- [X] T004 [P] [US1] Goal: Add repository-level coverage for program name fallback, persistence, trimming, and empty-value rejection; Files: `test/program_identity_test.dart`, `lib/repositories/settings_repository.dart`; Dependencies: T001; Validation: `flutter test test/program_identity_test.dart` skipped per user instruction; Risk: Low, test-only.
- [X] T005 [P] [US1] Goal: Add widget coverage that login and shell/service areas render the configured Arabic program name and default fallback; Files: `test/program_identity_widget_test.dart`, `lib/screens/login_screen.dart`, `lib/screens/services_management_screen.dart`, `lib/screens/main_shell.dart`; Dependencies: T001; Validation: `flutter test test/program_identity_widget_test.dart` skipped per user instruction; Risk: Medium, guards visible Arabic labels.

### Implementation for User Story 1

- [X] T006 [US1] Goal: Add a settings repository API for `program_name` using the existing `Settings` table and default `برنامج مدارس الأحد`; Files: `lib/repositories/settings_repository.dart`, `lib/database/database.dart`; Dependencies: T004; Validation: repository tests authored, execution skipped per user instruction; Risk: Medium, must preserve existing settings keys.
- [X] T007 [US1] Goal: Add Arabic validation and save/load controls for the program name in the existing services/settings management area; Files: `lib/screens/services_management_screen.dart`; Dependencies: T006; Validation: widget test authored and manual check documented; Risk: Medium, this screen already manages service configuration.
- [X] T008 [US1] Goal: Replace hardcoded login title usage with the configurable program name provider/helper while preserving default text when unset; Files: `lib/screens/login_screen.dart`, `lib/repositories/settings_repository.dart`; Dependencies: T006; Validation: widget test authored, execution skipped per user instruction; Risk: Medium, login is a critical entry flow.
- [X] T009 [US1] Goal: Replace internal hardcoded program-name usage in shell/services surfaces without changing unrelated Arabic labels; Files: `lib/screens/main_shell.dart`, `lib/screens/services_management_screen.dart`, `lib/main.dart`; Dependencies: T006; Validation: widget test authored and visual RTL check remains manual; Risk: Medium, visible app identity changes.
- [X] T010 [US1] Goal: Ensure empty, whitespace-only, and overly long program names show clear Arabic errors and do not overwrite the stored valid name; Files: `lib/screens/services_management_screen.dart`, `lib/repositories/settings_repository.dart`; Dependencies: T007; Validation: tests authored, execution skipped per user instruction; Risk: Low, validation only.

### Phase 1 Checkpoint

- [X] T011 Goal: Review Phase 1 independently and stop before card-designer work; Files: `specs/001-program-service-customization/tasks.md`, `specs/001-program-service-customization/quickstart.md`; Dependencies: T001-T010; Validation: `flutter analyze` and targeted US1 tests skipped per user instruction; Risk: Low, checkpoint only.

## Phase 2: Card Designer Foundation (US2)

**Goal**: Add a polished RTL card preview/designer foundation under the existing Card tab without replacing the old simple print flow.
**Independent review**: A reviewer can open the Card tab designer, preview existing person fields plus chorus/group, move/resize text, toggle labels, add fixed text, and test background fit modes.

### Tests for User Story 2

- [X] T012 [P] [US2] Goal: Add model/serialization tests for one active card template, field label modes, text size bounds, color values, and background fit modes; Files: `test/card_template_test.dart`, `lib/models/card_template.dart`; Dependencies: T011; Validation: `flutter test test/card_template_test.dart` skipped per user instruction; Risk: Low, test-first model coverage.
- [X] T013 [P] [US2] Goal: Add RTL widget smoke coverage for the new designer page controls and preview updates; Files: `test/card_designer_widget_test.dart`, `lib/screens/id_card_screen.dart`, `lib/widgets/card_designer_preview.dart`; Dependencies: T011; Validation: `flutter test test/card_designer_widget_test.dart` skipped per user instruction; Risk: Medium, guards Card tab UX.

### Implementation for User Story 2

- [X] T014 [US2] Goal: Define the active card template model with existing person fields, `khorosName`, fixed text elements, background image metadata, fit modes, text color, text size, and position; Files: `lib/models/card_template.dart`, `lib/repositories/persons_repository.dart`; Dependencies: T012; Validation: model tests authored, execution skipped per user instruction; Risk: Medium, template must map current card fields accurately.
- [X] T015 [US2] Goal: Add template load/save helpers using existing settings storage conventions without introducing a new storage system; Files: `lib/repositories/settings_repository.dart`, `lib/models/card_template.dart`; Dependencies: T014; Validation: `flutter test test/card_template_test.dart` skipped per user instruction; Risk: Medium, settings key compatibility.
- [X] T016 [US2] Goal: Add a new Arabic RTL designer/preview page inside the existing Card tab navigation while leaving current simple printing reachable; Files: `lib/screens/id_card_screen.dart`; Dependencies: T013, T015; Validation: designer widget test authored and manual Card tab navigation remains required; Risk: High, this screen owns existing ID card workflows.
- [X] T017 [US2] Goal: Build the preview surface with stable card dimensions, RTL text rendering, draggable or numeric position controls, and live updates; Files: `lib/widgets/card_designer_preview.dart`, `lib/screens/id_card_screen.dart`; Dependencies: T016; Validation: `flutter test test/card_designer_widget_test.dart` skipped per user instruction; Risk: Medium, visual layout can regress on small screens.
- [X] T018 [US2] Goal: Add editable controls for existing data fields and the chorus/group field with Arabic labels and per-field label visibility where feasible; Files: `lib/screens/id_card_screen.dart`, `lib/models/card_template.dart`, `lib/repositories/persons_repository.dart`; Dependencies: T017; Validation: manual preview with a person containing `khorosName` remains required; Risk: Medium, field names must match existing DTO data.
- [X] T019 [US2] Goal: Add fixed custom text elements with color, text size, and position controls in the designer; Files: `lib/screens/id_card_screen.dart`, `lib/widgets/card_designer_preview.dart`, `lib/models/card_template.dart`; Dependencies: T017; Validation: widget test authored, execution skipped per user instruction; Risk: Low, additive designer behavior.
- [X] T020 [US2] Goal: Add background image selection metadata and fit mode controls for shrink-to-fit, zoom-to-fit, and actual size in preview only; Files: `lib/screens/id_card_screen.dart`, `lib/widgets/card_designer_preview.dart`, `lib/models/card_template.dart`; Dependencies: T017; Validation: manual preview with each background fit mode remains required; Risk: Medium, image path handling must follow existing app conventions.
- [X] T021 [US2] Goal: Add Arabic validation for card element bounds, minimum readable text size, maximum text size, and missing image paths; Files: `lib/screens/id_card_screen.dart`, `lib/models/card_template.dart`; Dependencies: T018-T020; Validation: tests authored, execution skipped per user instruction; Risk: Low, validation only.

### Phase 2 Checkpoint

- [X] T022 Goal: Review Phase 2 independently before integrating barcode/images into generated PDFs; Files: `lib/screens/id_card_screen.dart`, `lib/widgets/card_designer_preview.dart`, `lib/models/card_template.dart`; Dependencies: T012-T021; Validation: `flutter analyze`, card template tests, and designer widget tests skipped per user instruction; manual RTL preview remains required; Risk: Low, checkpoint only.

## Phase 3: Barcode, Images, Template Persistence, and Card Printing Integration (US3)

**Goal**: Complete card customization by adding barcode controls, image elements, template persistence, and PDF/print integration while preserving current barcode data behavior.
**Independent review**: A reviewer can save a card template, reopen it, print/preview it, resize/move the barcode, switch white/transparent barcode background, and confirm old simple printing still works.

### Tests for User Story 3

- [X] T023 [P] [US3] Goal: Add generator tests for reduced default barcode size, barcode position, white/transparent background modes, and preserved encoded person ID; Files: `test/print_generators_test.dart`, `lib/services/id_card_pdf_generator.dart`, `lib/models/card_template.dart`; Dependencies: T022; Validation: `flutter test test/print_generators_test.dart` skipped per user instruction; Risk: Medium, PDF output behavior.
- [X] T024 [P] [US3] Goal: Add persistence tests for image elements, barcode options, and active template reload after app restart; Files: `test/card_template_test.dart`, `lib/repositories/settings_repository.dart`, `lib/models/card_template.dart`; Dependencies: T022; Validation: `flutter test test/card_template_test.dart` skipped per user instruction; Risk: Medium, settings persistence.

### Implementation for User Story 3

- [X] T025 [US3] Goal: Extend the card template model with barcode size, barcode position, barcode background mode, and free image element definitions; Files: `lib/models/card_template.dart`; Dependencies: T023, T024; Validation: card template tests authored, execution skipped per user instruction; Risk: Medium, schema-free JSON compatibility.
- [X] T026 [US3] Goal: Add Arabic controls for barcode size, barcode position, and white/transparent background mode in the designer; Files: `lib/screens/id_card_screen.dart`, `lib/widgets/card_designer_preview.dart`; Dependencies: T025; Validation: designer widget/manual preview remains required; Risk: Medium, barcode must remain visible.
- [X] T027 [US3] Goal: Add image element selection, positioning, sizing, and removal controls using existing file/image picker conventions; Files: `lib/screens/id_card_screen.dart`, `lib/widgets/card_designer_preview.dart`, `pubspec.yaml`; Dependencies: T025; Validation: manual add/remove image in designer remains required; Risk: Medium, local paths may become unavailable.
- [X] T028 [US3] Goal: Persist the active card template through existing settings APIs and load it when the Card tab opens; Files: `lib/screens/id_card_screen.dart`, `lib/repositories/settings_repository.dart`, `lib/models/card_template.dart`; Dependencies: T024-T027; Validation: close/reopen app confirmation remains manual; Risk: Medium, stored malformed JSON must fall back safely.
- [X] T029 [US3] Goal: Update the card PDF generator to render template fields, fixed text, background image, free images, and barcode options while keeping the old simple generator path available; Files: `lib/services/id_card_pdf_generator.dart`, `lib/screens/id_card_screen.dart`, `lib/models/card_template.dart`; Dependencies: T025-T028; Validation: generator tests authored, execution skipped per user instruction; manual print preview remains required; Risk: High, existing print output must not break.
- [X] T030 [US3] Goal: Add scannability safeguards for minimum barcode/QR size, quiet-zone behavior, and visible contrast warnings in Arabic; Files: `lib/screens/id_card_screen.dart`, `lib/services/id_card_pdf_generator.dart`, `lib/widgets/card_designer_preview.dart`; Dependencies: T026, T029; Validation: manual barcode and QR scan smoke test remains required; Risk: High, users rely on scan behavior.
- [X] T031 [US3] Goal: Wire designer print execution into existing progress and print dialog flow without removing current print buttons; Files: `lib/screens/id_card_screen.dart`, `lib/widgets/print_progress_dialog.dart`, `lib/services/id_card_pdf_generator.dart`; Dependencies: T029, T030; Validation: `flutter test test/print_progress_dialog_test.dart test/print_generators_test.dart` skipped per user instruction; Risk: High, print flow regression.

### Phase 3 Checkpoint

- [X] T032 Goal: Review Phase 3 independently before attendance/export work; Files: `lib/screens/id_card_screen.dart`, `lib/services/id_card_pdf_generator.dart`, `lib/models/card_template.dart`; Dependencies: T023-T031; Validation: `flutter analyze`, card tests, and print tests skipped per user instruction; manual card preview/print/scan checklist remains required; Risk: Low, checkpoint only.

## Phase 4: Attendance Grid and PDF/Grouping Export Improvements (US4, US5, US6)

**Goal**: Improve attendance grid point display, add reusable PDF orientation/stretch options, and add separate PDF per group without disrupting existing exports.
**Independent review**: A reviewer can see check marks and points in one attendance cell, export wide tables in portrait/landscape with stretch-to-fit, and generate one PDF per group.

### Tests for User Stories 4-6

- [X] T033 [P] [US4] Goal: Add widget or helper coverage that attendance grid points render beside the check mark in the same visible cell; Files: `test/attendance_grid_display_test.dart`, `lib/screens/attendance_screen.dart`; Dependencies: T032; Validation: `flutter test test/attendance_grid_display_test.dart` skipped per user instruction; Risk: Medium, attendance grid readability.
- [X] T034 [P] [US5] Goal: Add PDF option/generator coverage for portrait, landscape, stretch-to-fit enabled, and stretch-to-fit disabled behavior; Files: `test/print_generators_test.dart`, `lib/services/attendance_grid_pdf_generator.dart`, `lib/services/attendance_report_service.dart`; Dependencies: T032; Validation: `flutter test test/print_generators_test.dart` skipped per user instruction; Risk: Medium, PDF layout behavior.
- [X] T035 [P] [US6] Goal: Add unit coverage for Arabic-safe group PDF file names and empty group handling; Files: `test/group_export_test.dart`, `lib/services/grouped_pdf_export_service.dart`; Dependencies: T032; Validation: `flutter test test/group_export_test.dart` skipped per user instruction; Risk: Low, file naming only.

### Implementation for User Story 4

- [X] T036 [US4] Goal: Update attendance grid cell rendering so enabled points appear beside the check mark in the same RTL-friendly cell; Files: `lib/screens/attendance_screen.dart`; Dependencies: T033; Validation: attendance grid display test authored, execution skipped per user instruction; manual grid with many columns remains required; Risk: Medium, visual regression in existing attendance view.
- [X] T037 [US4] Goal: Remove or hide any points-only visible column while preserving underlying save/load data behavior; Files: `lib/screens/attendance_screen.dart`, `lib/repositories/attendance_repository.dart`; Dependencies: T036; Validation: points data remains read from existing `AttendanceDTO.point`; automated execution skipped per user instruction; Risk: Medium, avoid changing persistence semantics.

### Implementation for User Story 5

- [X] T038 [US5] Goal: Add a reusable PDF export options model for page orientation and stretch-to-fit; Files: `lib/models/pdf_export_options.dart`, `lib/services/attendance_grid_pdf_generator.dart`, `lib/services/attendance_report_service.dart`; Dependencies: T034; Validation: PDF option tests authored, execution skipped per user instruction; Risk: Low, additive model.
- [X] T039 [US5] Goal: Add Arabic export option controls to existing relevant export dialogs without changing defaults; Files: `lib/ui/dialogs/sorting_dialog.dart`, `lib/ui/dialogs/print_period_services_dialog.dart`, `lib/screens/attendance_screen.dart`; Dependencies: T038; Validation: manual dialog smoke test in RTL remains required; Risk: Medium, dialogs are shared export UI.
- [X] T040 [US5] Goal: Implement stretch-to-fit scaling for attendance report PDF tables while preserving existing output when disabled; Files: `lib/services/attendance_report_service.dart`, `lib/models/pdf_export_options.dart`; Dependencies: T038, T039; Validation: generator tests authored, execution skipped per user instruction; manual portrait/landscape export remains required; Risk: High, table overflow behavior.
- [X] T041 [US5] Goal: Implement stretch-to-fit scaling for attendance grid PDF tables while preserving existing output when disabled; Files: `lib/services/attendance_grid_pdf_generator.dart`, `lib/models/pdf_export_options.dart`; Dependencies: T038, T039; Validation: generator tests authored, execution skipped per user instruction; manual wide-grid PDF remains required; Risk: High, wide attendance tables.
- [X] T042 [US5] Goal: Apply orientation/stretch options to term/grouping-related table exports where they use the same PDF table patterns; Files: `lib/services/term_attendance_pdf_service.dart`, `lib/services/person_report_service.dart`, `lib/services/report_generator.dart`; Dependencies: T040, T041; Validation: manual PDF inspection for relevant table exports remains required; Risk: Medium, multiple export surfaces.

### Implementation for User Story 6

- [X] T043 [US6] Goal: Extend grouping export UI to choose between start each group on a new page and generate separate PDF per group; Files: `lib/ui/dialogs/sorting_dialog.dart`, `lib/screens/attendance_screen.dart`; Dependencies: T039; Validation: manual grouped export option flow remains required; Risk: Medium, current new-page behavior must remain default-compatible.
- [X] T044 [US6] Goal: Add grouped PDF export helper for one-PDF-per-group output, Arabic-safe file names, destination folder behavior, and empty group messages; Files: `lib/services/grouped_pdf_export_service.dart`, `lib/services/attendance_report_service.dart`; Dependencies: T035, T043; Validation: group export tests authored, execution skipped per user instruction; Risk: High, file generation can mix or lose group data.
- [X] T045 [US6] Goal: Wire separate PDF generation into existing grouping/export action paths and keep new-page-per-group path unchanged; Files: `lib/screens/attendance_screen.dart`, `lib/ui/dialogs/sorting_dialog.dart`, `lib/services/grouped_pdf_export_service.dart`; Dependencies: T044; Validation: manual export with two groups and one empty group remains required; Risk: High, export behavior regression.

### Phase 4 Checkpoint

- [X] T046 Goal: Review Phase 4 independently before database relationship changes; Files: `lib/screens/attendance_screen.dart`, `lib/services/attendance_grid_pdf_generator.dart`, `lib/services/attendance_report_service.dart`, `lib/services/grouped_pdf_export_service.dart`; Dependencies: T033-T045; Validation: `flutter analyze`, targeted export/grid tests, and manual PDF inspection skipped/deferred per user instruction; Risk: Low, checkpoint only.

## Phase 5: Multi-Service Chorus/Group and Stage Links with Attendance Restrictions (US7)

**Goal**: Add safe many-to-many service links for choruses/groups and stages, migrate legacy single-service links, and enforce service eligibility in attendance.
**Independent review**: A reviewer can assign multiple services to a group/stage, confirm existing assignments migrated, and verify invalid attendance is rejected before save and at save validation.

### Tests for User Story 7

- [X] T047 [P] [US7] Goal: Add migration coverage for copying legacy `Service_ID` values into new group/stage service link tables; Files: `test/service_links_migration_test.dart`, `lib/database/database.dart`, `lib/database/tables.dart`; Dependencies: T046; Validation: `flutter test test/service_links_migration_test.dart` skipped per user instruction; Risk: High, data migration safety.
- [X] T048 [P] [US7] Goal: Add repository tests for group/stage multi-service assignment, member eligibility resolution, and conflict handling; Files: `test/service_eligibility_test.dart`, `lib/repositories/khoros_repository.dart`, `lib/repositories/stages_repository.dart`, `lib/repositories/service_eligibility_repository.dart`; Dependencies: T046; Validation: `flutter test test/service_eligibility_test.dart` skipped per user instruction; Risk: High, business rule coverage.
- [X] T049 [P] [US7] Goal: Add attendance validation tests for rejecting a person not assigned to the selected service with a clear Arabic message; Files: `test/attendance_service_restriction_test.dart`, `lib/repositories/attendance_repository.dart`, `lib/screens/attendance_screen.dart`; Dependencies: T046; Validation: `flutter test test/attendance_service_restriction_test.dart` skipped per user instruction; Risk: High, critical attendance flow.

### Migration and Data Model for User Story 7

- [X] T050 [US7] Goal: Add Drift tables for group-service and stage-service many-to-many links while leaving legacy `Service_ID` columns in place for compatibility; Files: `lib/database/tables.dart`; Dependencies: T047; Validation: generated-code command deferred per user instruction; Risk: High, database schema change.
- [X] T051 [US7] Goal: Add schema version upgrade and migration that seeds new link tables from existing `Khoroses.Service_ID` and `Stages.Service_ID`; Files: `lib/database/database.dart`; Dependencies: T050; Validation: migration test authored, execution skipped per user instruction; Risk: High, must preserve existing single-service assignments.
- [ ] T052 [US7] Goal: Regenerate Drift database code after table and migration changes; Files: `lib/database/database.g.dart`, `lib/database/database.dart`, `lib/database/tables.dart`; Dependencies: T050, T051; Validation: `dart run build_runner build --delete-conflicting-outputs`; Risk: Medium, generated code churn.
- [X] T053 [US7] Goal: Update backup/restore and schema repair paths so new link tables are created and preserved; Files: `lib/services/database_backup_service.dart`, `lib/database/database.dart`; Dependencies: T052; Validation: migration tests authored and manual backup/restore smoke test deferred per user instruction; Risk: High, backup compatibility.

### Repository and UI Implementation for User Story 7

- [X] T054 [US7] Goal: Update group repository APIs to read/write multiple linked services while preserving legacy reads; Files: `lib/repositories/khoros_repository.dart`, `lib/database/database.dart`; Dependencies: T052; Validation: service eligibility tests authored, execution skipped per user instruction; Risk: High, group management data behavior.
- [X] T055 [US7] Goal: Update stage repository APIs to read/write multiple linked services while preserving legacy reads; Files: `lib/repositories/stages_repository.dart`, `lib/database/database.dart`; Dependencies: T052; Validation: service eligibility tests authored, execution skipped per user instruction; Risk: High, stage management data behavior.
- [X] T056 [US7] Goal: Add a single eligibility resolver that combines direct person services, group services, and stage services using the approved conflict rule; Files: `lib/repositories/service_eligibility_repository.dart`, `lib/repositories/persons_repository.dart`; Dependencies: T054, T055; Validation: service eligibility tests authored, execution skipped per user instruction; Risk: High, central business rule.
- [X] T057 [US7] Goal: Update group management UI to select multiple services with clear Arabic labels and validation; Files: `lib/screens/khoros_screen.dart`, `lib/repositories/khoros_repository.dart`; Dependencies: T054; Validation: manual create/edit group with multiple services deferred; Risk: Medium, existing group edit flow.
- [X] T058 [US7] Goal: Update stage management UI to select multiple services with clear Arabic labels and validation; Files: `lib/screens/stages_screen.dart`, `lib/repositories/stages_repository.dart`; Dependencies: T055; Validation: manual create/edit stage with multiple services deferred; Risk: Medium, existing stage edit flow.
- [X] T059 [US7] Goal: Update person service synchronization so group/stage service changes do not remove unrelated direct service assignments; Files: `lib/repositories/persons_repository.dart`, `lib/screens/person_dialog.dart`, `lib/screens/transfer_screen.dart`; Dependencies: T056-T058; Validation: service eligibility tests authored plus manual edit/transfer smoke test deferred; Risk: High, person service access could be over-removed.
- [X] T060 [US7] Goal: Reject invalid service attendance during search/selection with Arabic feedback before the user reaches save; Files: `lib/screens/attendance_screen.dart`, `lib/repositories/service_eligibility_repository.dart`; Dependencies: T056; Validation: attendance restriction tests authored and manual invalid selection deferred; Risk: High, attendance UX change.
- [X] T061 [US7] Goal: Enforce the same invalid service attendance rejection during save in repository validation as a defensive check; Files: `lib/repositories/attendance_repository.dart`, `lib/repositories/service_eligibility_repository.dart`; Dependencies: T056, T060; Validation: attendance restriction tests authored, execution skipped per user instruction; Risk: High, save behavior change.
- [X] T062 [US7] Goal: Ensure scanner-driven attendance uses the same eligibility validation and Arabic rejection message; Files: `lib/screens/attendance_screen.dart`, `lib/screens/qr_scanner_screen.dart`; Dependencies: T060, T061; Validation: manual scan invalid/valid person flows deferred; Risk: High, barcode scan attendance regression.

### Phase 5 Checkpoint

- [ ] T063 Goal: Review Phase 5 independently before behavior scoring changes; Files: `lib/database/database.dart`, `lib/database/tables.dart`, `lib/repositories/service_eligibility_repository.dart`, `lib/screens/attendance_screen.dart`; Dependencies: T047-T062; Validation: build runner clean, `flutter analyze`, migration tests, eligibility tests, attendance restriction tests, manual upgraded database smoke test; Risk: Low, checkpoint only.

## Phase 6: Multi-Service Behavior and Default Score 5 in Analysis/Term Closing (US8)

**Goal**: Allow behavior recording for multiple services and treat missing behavior records as 5 in closing and analysis while preserving explicit recorded values.
**Independent review**: A reviewer can enter behavior for multiple services, leave another service missing, and confirm analysis/term closing uses recorded values where present and 5 where missing.

### Tests for User Story 8

- [ ] T064 [P] [US8] Goal: Add repository tests for multi-service behavior save/load and explicit recorded values overriding default 5; Files: `test/behavior_scoring_test.dart`, `lib/repositories/attendance_repository.dart`, `lib/screens/behavior_screen.dart`; Dependencies: T063; Validation: `flutter test test/behavior_scoring_test.dart`; Risk: High, scoring data behavior.
- [ ] T065 [P] [US8] Goal: Add term closing and analysis tests proving missing behavior records count as 5 and explicit 0 remains 0 only if valid in the existing range; Files: `test/term_attendance_behavior_test.dart`, `lib/repositories/term_attendance_repository.dart`, `lib/repositories/reports_repository.dart`; Dependencies: T063; Validation: `flutter test test/term_attendance_behavior_test.dart`; Risk: High, historical calculations.

### Implementation for User Story 8

- [ ] T066 [US8] Goal: Update Behavior tab UI from single-service selection to multi-service selection with default score 5 and Arabic validation for the existing 0-7 range; Files: `lib/screens/behavior_screen.dart`; Dependencies: T064; Validation: behavior screen manual test and repository tests; Risk: Medium, existing behavior entry workflow.
- [ ] T067 [US8] Goal: Update behavior save/load repository logic to handle selected multiple services without corrupting existing `Coming.Behavior` records; Files: `lib/repositories/attendance_repository.dart`, `lib/database/database.dart`; Dependencies: T064, T066; Validation: behavior scoring tests pass; Risk: High, behavior records share attendance data.
- [ ] T068 [US8] Goal: Update term attendance closing calculations so missing records for a person/service are counted as behavior 5 instead of 0; Files: `lib/repositories/term_attendance_repository.dart`, `lib/widgets/dashboard/term_attendance_closure_widget.dart`; Dependencies: T065, T067; Validation: term attendance behavior tests pass; Risk: High, closing results change.
- [ ] T069 [US8] Goal: Update analysis/report calculations so missing behavior uses 5 and recorded behavior values remain authoritative; Files: `lib/repositories/reports_repository.dart`, `lib/repositories/period_comparison_repository.dart`, `lib/services/report_generator.dart`; Dependencies: T065, T067; Validation: term/report behavior tests plus manual Data Analysis check; Risk: High, analytics regression.
- [ ] T070 [US8] Goal: Update term attendance PDF/Excel output labels or values only where behavior calculations are displayed; Files: `lib/services/term_attendance_pdf_service.dart`, `lib/services/term_attendance_excel_service.dart`; Dependencies: T068, T069; Validation: manual PDF/Excel inspection; Risk: Medium, export values must match analysis.
- [ ] T071 [US8] Goal: Ensure old behavior data remains valid and no migration rewrites historical values unnecessarily; Files: `lib/repositories/attendance_repository.dart`, `lib/repositories/term_attendance_repository.dart`, `lib/database/database.dart`; Dependencies: T067-T070; Validation: test with pre-existing single-service behavior records; Risk: High, historical data protection.

### Phase 6 Checkpoint

- [ ] T072 Goal: Review Phase 6 independently before final regression/polish; Files: `lib/screens/behavior_screen.dart`, `lib/repositories/attendance_repository.dart`, `lib/repositories/term_attendance_repository.dart`, `lib/repositories/reports_repository.dart`; Dependencies: T064-T071; Validation: `flutter analyze`, behavior tests, term behavior tests, manual multi-service behavior scenario; Risk: Low, checkpoint only.

## Phase 7: Regression, Polish, Accessibility, and Documentation

**Goal**: Validate the complete feature set, polish RTL Arabic UX, and document manual checks without adding new functional scope.
**Independent review**: A reviewer can run the documented checks across login, cards, attendance, exports, service rules, behavior, and analysis with no unrelated regressions.

### Final Validation and Polish

- [ ] T073 [P] Goal: Run an RTL Arabic UI polish pass for spacing, typography, color contrast, button affordances, overflow, and responsive behavior on changed screens; Files: `lib/screens/login_screen.dart`, `lib/screens/services_management_screen.dart`, `lib/screens/id_card_screen.dart`, `lib/screens/attendance_screen.dart`, `lib/screens/khoros_screen.dart`, `lib/screens/stages_screen.dart`, `lib/screens/behavior_screen.dart`; Dependencies: T072; Validation: manual desktop/tablet/narrow-width smoke screenshots; Risk: Medium, visual-only changes can affect dense operational screens.
- [ ] T074 [P] Goal: Update quickstart/manual checklist for reviewers with exact Arabic scenarios for program name, card designer, barcode scan, PDFs, service restrictions, and behavior default 5; Files: `specs/001-program-service-customization/quickstart.md`; Dependencies: T072; Validation: reviewer can follow checklist end to end; Risk: Low, documentation only.
- [ ] T075 Goal: Run generated-code consistency checks after all database/provider changes; Files: `lib/database/database.g.dart`, `lib/database/database.dart`, `lib/database/tables.dart`; Dependencies: T063, T072; Validation: `dart run build_runner build --delete-conflicting-outputs` has no unintended generated drift; Risk: Medium, generated files can hide schema mistakes.
- [ ] T076 Goal: Run the full automated suite and static analysis; Files: `pubspec.yaml`, `analysis_options.yaml`, `test/`; Dependencies: T073-T075; Validation: `flutter analyze` and `flutter test`; Risk: Medium, may reveal pre-existing unrelated failures that must be documented, not silently fixed.
- [ ] T077 Goal: Perform manual regression of existing critical flows: login, service CRUD, person CRUD, simple card printing, attendance save/load, existing grouped export new-page mode, backup/restore, and analysis; Files: `specs/001-program-service-customization/quickstart.md`, `lib/screens/`, `lib/services/`, `lib/repositories/`; Dependencies: T076; Validation: completed manual checklist with screenshots or notes; Risk: High, protects old behavior.
- [ ] T078 Goal: Review final diff for unrelated deletions, accidental rewrites, Arabic/RTL compliance, and phase-by-phase reviewability; Files: `specs/001-program-service-customization/tasks.md`, `specs/001-program-service-customization/plan.md`, `specs/001-program-service-customization/spec.md`; Dependencies: T077; Validation: `git diff --stat` and targeted file review; Risk: Low, release hygiene.

## Dependencies and Execution Order

1. Phase 1 must complete before any UI or data-model work because it establishes baseline tests and settings conventions.
2. Phase 2 must complete before Phase 3 because barcode, images, persistence, and PDF printing depend on the template model and preview surface.
3. Phase 4 can start after Phase 3 because it touches attendance/export surfaces but does not depend on service-link schema changes.
4. Phase 5 must run migration tasks T050-T052 before any repository/UI code depends on new group/stage service link tables.
5. Phase 6 must run after Phase 5 so behavior multi-service selection can use finalized service assignment semantics.
6. Phase 7 runs only after all feature phases are independently reviewed.

## Parallel Opportunities

- Phase 1: T002 and T003 can run in parallel with T001; T004 and T005 can be authored in parallel after T001.
- Phase 2: T012 and T013 can run in parallel.
- Phase 3: T023 and T024 can run in parallel.
- Phase 4: T033, T034, and T035 can run in parallel.
- Phase 5: T047, T048, and T049 can run in parallel before schema implementation.
- Phase 6: T064 and T065 can run in parallel.
- Phase 7: T073 and T074 can run in parallel after T072.

## User Story Validation Summary

- **US1 Configurable Program Name**: T004-T010, checkpoint T011.
- **US2 Card Designer Foundation**: T012-T021, checkpoint T022.
- **US3 Barcode and Card Printing Integration**: T023-T031, checkpoint T032.
- **US4 Attendance Grid Points Display**: T033, T036-T037, checkpoint T046.
- **US5 PDF Stretch/Orientation**: T034, T038-T042, checkpoint T046.
- **US6 Separate PDF Per Group**: T035, T043-T045, checkpoint T046.
- **US7 Multi-Service Groups/Stages and Attendance Restrictions**: T047-T062, checkpoint T063.
- **US8 Multi-Service Behavior and Default 5**: T064-T071, checkpoint T072.

## MVP Scope

The smallest independently useful MVP is Phase 1 only: configurable global program name with persisted fallback behavior. The next reviewable increment is Phases 2-3 together for the complete card designer and printing workflow.

## Format Check

All implementation tasks use the required checklist format, include concrete file paths, include dependencies and validation, isolate database migrations before dependent code, and avoid rebuild-from-scratch or unrelated deletion work.
