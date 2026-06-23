# Feature Specification: Configurable Program Identity, Card Designer, Exports, Services, and Behavior Scoring

**Feature Branch**: `001-program-service-customization`
**Created**: 2026-06-18
**Status**: Draft
**Input**: User description: "Configurable Sunday School Program Identity, Advanced Card Designer, Attendance/PDF Export Improvements, Service-Based Access Rules, and Multi-Service Behavior Scoring."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Rename the Program Across the App (Priority: P1)

An admin/user changes the displayed program name from the current default "برنامج مدارس الأحد" to a service-specific Arabic name such as "مدرسة الشمامسة", then sees that name on login and in internal places where the program name is shown, especially service management areas.

**Why this priority**: This is a low-friction identity customization that allows churches and services to adopt the app without forcing the Sunday School naming model.

**Independent Test**: Change the program name from an appropriate existing settings or services configuration area, close and reopen the app, confirm the login title and internal program references use the new name, then clear the custom value and confirm the old default returns.

**Acceptance Scenarios**:

1. **Given** no custom program name exists, **When** the login screen and Services tab are opened, **Then** the app displays "برنامج مدارس الأحد".
2. **Given** an admin/user saves "مدرسة الشمامسة" as the program name, **When** the app is reopened, **Then** login and internal program-name references display "مدرسة الشمامسة" in Arabic RTL.
3. **Given** a custom program name is saved, **When** unrelated screens and data records are viewed, **Then** unrelated labels and existing data remain unchanged.

---

### User Story 2 - Design and Preview Printable ID Cards (Priority: P1)

A user opens a new card preview/designer page from the Card tab, adjusts card text, labels, images, background, and barcode appearance, then previews the final Arabic RTL card before printing without losing the existing simple card printing workflow.

**Why this priority**: ID cards are a visible operational output, and flexible layout control is required for different church card designs.

**Independent Test**: Open the Card tab, launch the new designer page, change text size, text color, field position, label display, background fit, custom text, custom image, chorus/group field, and barcode settings, then confirm the preview updates and existing simple card printing still works.

**Acceptance Scenarios**:

1. **Given** a person has name, service, stage, and chorus/group data, **When** the card designer preview is opened, **Then** the preview can display all selected fields including chorus/group.
2. **Given** the user changes text size, text color, position, label visibility, fixed text, images, or background fit, **When** the preview refreshes, **Then** the visible card reflects the changes before printing.
3. **Given** a data field label is disabled, **When** the field is shown on the card, **Then** only the field value appears, such as "كيرلس" instead of "الاسم: كيرلس".
4. **Given** a background image is selected, **When** the user chooses "احتواء داخل البطاقة", "ملء البطاقة", or "الحجم الأصلي", **Then** the preview visibly applies the selected fit mode.
5. **Given** the user uses the existing simple card print flow, **When** they print without entering the new designer, **Then** the previous print behavior remains available.

---

### User Story 3 - Customize Barcode Placement and Background (Priority: P1)

A user controls the barcode/QR element on the card by making it smaller by default, moving it, resizing it within reasonable limits, and choosing whether it has a white or transparent background while preserving the existing encoded data.

**Why this priority**: Barcode layout affects both card appearance and scan reliability, so customization must be part of the card preview workflow.

**Independent Test**: In the card designer, resize and move the barcode, switch between white and transparent backgrounds, print/preview the card, and confirm the barcode remains visible and scannable in normal print conditions.

**Acceptance Scenarios**:

1. **Given** the card designer opens with the barcode visible, **When** the default layout appears, **Then** the barcode is smaller than the current fixed design.
2. **Given** the user changes barcode size or position, **When** the preview updates, **Then** the barcode moves and resizes without changing the person data encoded in it.
3. **Given** the user chooses a transparent barcode background, **When** the preview and print output are generated, **Then** the barcode remains readable against the selected card background or prompts the user when readability is at risk.

---

### User Story 4 - Improve Attendance Grid Points Display (Priority: P2)

A user enables points in the Attendance grid and sees points beside the attendance check mark in the same visible table cell, without adding a separate points-only column.

**Why this priority**: This improves readability of dense attendance tables without changing attendance marking behavior.

**Independent Test**: Enable points in the attendance grid, mark and unmark attendance, save and reload attendance, and verify the combined check mark plus points display remains in the same RTL-friendly cell.

**Acceptance Scenarios**:

1. **Given** attendance grid view is open and points display is enabled, **When** a person has attendance and points for a column, **Then** the same visible cell shows the check mark and points together.
2. **Given** points display is enabled, **When** the table contains many people and many attendance columns, **Then** no separate points-only column appears and the table remains readable.
3. **Given** the user saves and reloads attendance, **When** the grid is reopened, **Then** existing save/load and marking behavior remains unchanged.

---

### User Story 5 - Export PDF Tables That Fit the Page (Priority: P2)

A user exports attendance, grouping, or other relevant tables to PDF and can choose portrait or landscape orientation plus an optional stretch-to-fit mode so wide or tall tables stay inside the PDF page.

**Why this priority**: Current exports must be reliable print deliverables, especially for wide attendance and grouping data.

**Independent Test**: Export representative Arabic tables with short and long names, many rows, and many columns using portrait and landscape with stretch-to-fit enabled and disabled, then verify page boundaries, readability, and old export behavior.

**Acceptance Scenarios**:

1. **Given** a relevant table export is started, **When** the export options are shown, **Then** the user can choose portrait or landscape orientation in Arabic.
2. **Given** stretch-to-fit is enabled, **When** the PDF is generated, **Then** the table stays within page boundaries horizontally and vertically as reasonably as possible.
3. **Given** stretch-to-fit is disabled, **When** the PDF is generated, **Then** existing export behavior remains available.
4. **Given** a wide attendance table is exported in landscape, **When** the PDF opens, **Then** wide columns are more readable than portrait output.

---

### User Story 6 - Export One PDF Per Chorus/Group (Priority: P2)

A user generating grouped exports chooses either the existing "start each group on a new page" behavior or a new "separate PDF per group" behavior, producing one Arabic-safe file per chorus/group.

**Why this priority**: Separate group files support distribution and printing workflows without manually splitting a combined report.

**Independent Test**: Generate grouped exports for multiple choruses/groups, including an empty group, and confirm each selected mode produces clear output without mixing group data.

**Acceptance Scenarios**:

1. **Given** grouped export options are visible, **When** the user selects "كل مجموعة في ملف PDF منفصل", **Then** the export produces one PDF file per chorus/group.
2. **Given** the user selects the existing new-page option, **When** the export runs, **Then** each group starts on a new page in one PDF as before.
3. **Given** a group has no members, **When** separate PDFs are generated, **Then** the app clearly reports how the empty group was handled in Arabic.
4. **Given** a group name contains Arabic characters or file-unsafe symbols, **When** a PDF file is named, **Then** the file name remains understandable and safe for saving.

---

### User Story 7 - Link Groups and Stages to Multiple Services with Attendance Restrictions (Priority: P1)

An admin/user assigns one chorus/group and relevant stages/classes to one or more services, existing single-service assignments remain intact, and attendance for a selected service accepts only people assigned or eligible for that service.

**Why this priority**: Service membership controls access and attendance integrity across multiple church services.

**Independent Test**: Assign a chorus/group to multiple services, confirm existing assignments remain, attempt attendance for allowed and disallowed services, and verify accepted attendance is saved while rejected attendance shows a clear Arabic message.

**Acceptance Scenarios**:

1. **Given** an existing chorus/group has one service assignment, **When** the feature is available, **Then** that assignment is preserved and visible as one selected service.
2. **Given** an admin/user selects multiple services for a chorus/group, **When** the assignment is saved, **Then** members of that chorus/group become eligible for those services according to existing business rules.
3. **Given** a stage/class must restrict service access, **When** services are configured for that stage/class, **Then** attendance eligibility follows those service links where relevant.
4. **Given** a person is not assigned or eligible for the selected service, **When** attendance is recorded for that service, **Then** the app rejects the action with a clear Arabic message and does not save invalid attendance.
5. **Given** a person is assigned or eligible for the selected service, **When** attendance is recorded, **Then** the current valid attendance flow continues to work.

---

### User Story 8 - Record Behavior for Multiple Services with Default Score 5 (Priority: P1)

A user records behavior for one or more selected services, sees a default score of 5, and analysis/term closing treat missing behavior as 5 rather than 0 while recorded values override the default.

**Why this priority**: Behavior scoring affects analysis and closing results, and treating missing scores as zero creates incorrect outcomes.

**Independent Test**: Record behavior for multiple services, leave some service/person combinations without explicit behavior, run analysis and term closing, and verify missing behavior contributes 5 while recorded behavior uses the saved value.

**Acceptance Scenarios**:

1. **Given** the Behavior tab is open, **When** the user records behavior, **Then** they can select multiple services and the default score shown is 5.
2. **Given** no behavior is recorded for a person/service, **When** term closing or analysis calculates behavior, **Then** the missing value is treated as 5.
3. **Given** behavior is recorded for a person/service, **When** term closing or analysis calculates behavior, **Then** the recorded value overrides the default 5.
4. **Given** old behavior records exist, **When** behavior analysis is run after this feature, **Then** old records remain valid and are not corrupted.

---

### Edge Cases

- Empty or whitespace-only program names are rejected with a clear Arabic validation message; long Arabic names remain readable on login and internal headings.
- Missing optional card fields, missing chorus/group values, long Arabic names, and mixed Arabic/numeric values do not break card preview or print layout.
- Invalid image files, missing image files, unsupported image sizes, unreadable backgrounds, and barcode settings that risk scanning failure show clear Arabic feedback.
- Attendance grids with many rows, many columns, points enabled, and RTL text remain readable without introducing hidden save/load changes.
- PDF exports with very wide tables, very tall tables, long Arabic headers, empty result sets, and large grouped outputs stay within page boundaries or clearly explain any unavoidable readability tradeoff.
- Empty groups in grouped export are not silently skipped unless the user is clearly told; selected mode determines whether an empty PDF, a notice, or a skipped output is produced.
- Existing records with one service assignment migrate safely into the multi-service model without duplicates or lost relationships.
- Attendance rejection for service mismatch is explicit, recoverable, and does not block valid attendance for other services.
- Missing behavior values in legacy and new records are interpreted as 5 only for calculation purposes unless the user explicitly records another value.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST allow an admin/user to configure the program display name from an appropriate existing settings or services configuration area.
- **FR-002**: The system MUST display the configured program name on the login screen and in internal locations where the hardcoded program name currently appears, especially the Services tab.
- **FR-003**: The system MUST default to "برنامج مدارس الأحد" when no custom program name exists.
- **FR-004**: The system MUST persist the configured program name after the app is closed and reopened.
- **FR-005**: Program-name changes MUST NOT modify unrelated labels, records, reports, exports, permissions, or church data.
- **FR-006**: The Card tab MUST include a new preview/designer page for ID card layout and printing.
- **FR-007**: The card preview MUST update when the user changes text color, text size, text position, field label display, images, fixed text, background image, background fit mode, or barcode settings.
- **FR-008**: The card designer MUST support showing person data fields currently used by cards plus the chorus/group field.
- **FR-009**: The card designer MUST allow users to add fixed custom Arabic text anywhere on the card.
- **FR-010**: The card designer MUST allow users to add one or more images to the card.
- **FR-011**: The card designer MUST allow users to add a background image and choose among shrink-to-fit, zoom-to-fit, and actual-size display modes using clear Arabic labels.
- **FR-012**: The card designer MUST allow field labels to be shown or hidden consistently, either per field or globally if that better fits the existing user experience.
- **FR-013**: Existing simple card printing MUST remain available and must not be broken by the new designer.
- **FR-014**: The barcode/QR/card code element MUST be smaller by default than the current fixed card design.
- **FR-015**: The card designer MUST allow barcode size and position editing within reasonable limits that protect scan readability.
- **FR-016**: The card designer MUST allow the barcode background to be either white or transparent.
- **FR-017**: Barcode customization MUST preserve the existing barcode data behavior.
- **FR-018**: Attendance grid points display MUST place points beside the check mark in the same visible table cell when points are enabled.
- **FR-019**: Attendance grid points display MUST NOT add a separate visible points-only column.
- **FR-020**: Attendance marking, saving, loading, and existing attendance data behavior MUST remain unchanged by the display change.
- **FR-021**: Relevant table PDF exports, especially attendance and grouping/export screens, MUST allow the user to choose portrait or landscape orientation.
- **FR-022**: Relevant table PDF exports MUST include a stretch-to-fit option that scales the table to fit within page width and height as reasonably as possible.
- **FR-023**: When stretch-to-fit is disabled, existing PDF export behavior MUST remain available.
- **FR-024**: Grouping/export MUST allow the user to choose between starting each group on a new page in one PDF and generating each group as a separate PDF file.
- **FR-025**: Separate grouped PDF export MUST produce one PDF per selected chorus/group with Arabic-safe, understandable file names.
- **FR-026**: Grouped export MUST handle empty groups with clear Arabic feedback and no silent data loss.
- **FR-027**: Choruses/groups MUST be assignable to multiple services while preserving existing single-service assignments.
- **FR-028**: Existing chorus/group service assignments MUST be safely represented as selected services after the multi-service change.
- **FR-029**: Members related to a chorus/group MUST become eligible for the services linked to that chorus/group according to existing business rules.
- **FR-030**: Stages/classes MUST be linkable to services where service restrictions apply to attendance eligibility.
- **FR-031**: Attendance for a selected service MUST reject people who are not assigned or eligible for that service.
- **FR-032**: Service eligibility rejection MUST show a clear Arabic message and MUST NOT save invalid attendance.
- **FR-033**: The Behavior tab MUST allow selecting multiple services when recording behavior.
- **FR-034**: The default behavior score MUST be 5.
- **FR-035**: Term attendance closing and Data Analysis MUST treat missing behavior for a person/service as 5, not 0.
- **FR-036**: Recorded behavior values MUST override the default score for the matching person/service.
- **FR-037**: Multi-service behavior values MUST be included correctly in analysis for the selected services.
- **FR-038**: Old behavior records MUST remain valid and uncorrupted.
- **FR-039**: All new controls, validation messages, empty states, loading states, error states, success states, print text, and PDF/export text MUST be Arabic and RTL.
- **FR-040**: Implementation MUST be delivered in phases, and each phase MUST stop for review before the next phase begins.

### Product Constraints *(mandatory for this project)*

- **PC-001**: User-facing UI, messages, print/PDF text, and export headings MUST be Arabic unless the existing application intentionally uses a specific English term.
- **PC-002**: New or changed UI MUST preserve RTL behavior and define empty, loading, error, and success states.
- **PC-003**: Existing login, permissions, attendance, services, ID cards, behavior, analysis, choruses/groups, stages, exports, reports, and maintenance workflows MUST be preserved unless this spec explicitly describes a safe change.
- **PC-004**: Any data model change MUST preserve existing data and require a migration-safe implementation plan.
- **PC-005**: Any affected printing, barcode, PDF, or table export behavior MUST include page fitting, orientation/scaling, Arabic font, and overflow acceptance criteria.
- **PC-006**: Implementation scope MUST fit one or two related areas per phase and MUST stop after each phase for user review.
- **PC-007**: The application MUST NOT be rebuilt from scratch; future implementation planning must inspect the existing project and preserve current behavior.
- **PC-008**: No technical stack, framework, package, or storage choice is selected by this specification.

### Key Entities *(include if feature involves data)*

- **Program Identity Setting**: The configurable Arabic display name for the application/program, with a default value of "برنامج مدارس الأحد".
- **Card Design**: A user-controlled card layout containing selected person fields, labels, fixed text, images, background image, barcode settings, and print preview settings.
- **Card Field**: A person-related value that may appear on the card, including name, service-related fields, stage/class, chorus/group, and other currently supported fields, with label visibility control.
- **Barcode Element**: The scannable card element whose encoded data is preserved while size, position, and background behavior can be configured.
- **Attendance Grid Cell**: A visible attendance table cell that may contain a check mark and points together for a person/date or person/service context.
- **PDF Export Options**: User choices for orientation, stretch-to-fit behavior, grouped export mode, and file output expectations.
- **Chorus/Group Service Link**: The relationship that allows one chorus/group to be associated with one or more services.
- **Stage/Class Service Link**: The relationship that allows a stage/class to be associated with one or more services where attendance restrictions require it.
- **Service Eligibility**: The set of services for which a person is allowed to record attendance based on direct or inherited service links.
- **Behavior Record**: A behavior score associated with a person and one or more services; missing values are treated as 5 for calculations.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In user acceptance testing, 100% of configured program-name references identified on login and service-management areas display the custom Arabic name after app restart, with the default name shown when no custom value exists.
- **SC-002**: A user can create or modify a representative ID card design, including chorus/group, custom text, image, background fit, label mode, and barcode settings, and reach print preview in under 5 minutes without using external editing tools.
- **SC-003**: In representative card previews and print outputs, 100% of barcode samples within allowed resize limits remain visible and scannable under normal print conditions.
- **SC-004**: Attendance grid testing confirms 100% of enabled points displays appear in the same visible cell as the check mark, with no additional points-only column.
- **SC-005**: Representative PDF table exports in portrait and landscape with stretch-to-fit enabled stay within page boundaries for at least 95% of tested attendance and grouping tables; any unavoidable readability limitation is communicated before or during export.
- **SC-006**: Separate grouped PDF export produces exactly one file per selected non-empty group in 100% of tested grouped exports and clearly reports empty-group handling.
- **SC-007**: Migration validation confirms 100% of existing single-service chorus/group assignments remain available after the multi-service change.
- **SC-008**: Attendance attempts for service-ineligible people are rejected in 100% of tested cases with a clear Arabic message, while valid attendance attempts continue to save successfully.
- **SC-009**: Behavior analysis and term closing treat missing person/service behavior values as 5 in 100% of tested missing-value cases, while recorded values override the default.
- **SC-010**: Each implementation phase covers no more than two related product areas and ends with a review summary before the next phase begins.

## Constitution Alignment *(mandatory)*

- **Existing Project Discovery**: Reviewed the current plan and constitution. Existing product areas identified for later implementation discovery include `login_screen`, `services_management_screen`, `id_card_screen`, `attendance_screen`, `khoros_screen`, `stages_screen`, `behavior_screen`, dashboard/analysis term closing, attendance and card PDF generation, grouped/report exports, settings, services, attendance, khoros/groups, stages, behavior, and database-related modules. This specification does not select implementation details and requires future planning to inspect the exact current behavior before changes.
- **Product Requirements**: The feature extends Arabic RTL product identity, card design/printing, attendance display, PDF/table export, grouped export, service eligibility, and behavior scoring. All new user-facing labels, messages, dialogs, print text, and PDF/export output must be Arabic.
- **Backward Compatibility**: Existing login, Services tab, simple card printing, barcode data behavior, attendance marking/save/load, current PDF exports, current "new page per group" export, existing single-service assignments, old behavior records, analysis, and term closing workflows must continue to work unless explicitly extended by this spec.
- **Validation and Feedback**: Required validation includes program-name input, image/background selection, barcode readability limits, PDF/export options, empty grouped exports, file-name safety, service eligibility, and behavior score entry. All validation, success, error, empty, and loading feedback must be Arabic and recoverable where possible.
- **Printing/Export Impact**: Card preview/printing, barcode rendering, table PDF export, attendance PDF export, grouped PDF export, orientation, stretch-to-fit behavior, background fit, Arabic fonts, RTL text, and page overflow are all affected and require visible acceptance checks with representative Arabic data.
- **Phased Delivery**: Phase 1: program identity and service configuration naming. Phase 2: card designer and barcode customization. Phase 3: attendance grid points and PDF table export fitting. Phase 4: grouped export separate PDFs. Phase 5: multi-service chorus/group and stage/class access rules. Phase 6: multi-service behavior scoring and default 5 calculations. Each phase must stop for review before the next phase starts.

## Assumptions

- Admin/user means the existing roles that already have permission to manage the affected area; this spec does not introduce new roles.
- "Chorus/group" refers to the existing group/chorus concept used by the app, including the current Khoros/Groups area.
- Service eligibility follows existing business rules first, then extends them with multi-service chorus/group and stage/class links.
- Label visibility for cards may be global or per field, as long as the chosen UX is clear, Arabic, and consistently applies to all supported fields.
- "Reasonable barcode limits" means the app prevents or warns against sizes and backgrounds likely to make the barcode unreadable in normal print preview.
- "Stretch to fit" prioritizes keeping the table inside page boundaries while preserving readability; extremely large tables may require smaller text, pagination, or clear user feedback.
- Missing behavior is treated as 5 for calculations and reporting; it does not automatically create a stored behavior record unless the user records one.
- Future implementation planning will inspect the existing code and data model before deciding how to preserve, migrate, or extend current behavior.
