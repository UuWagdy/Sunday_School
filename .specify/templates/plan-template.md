# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See
`.specify/templates/plan-template.md` for the execution workflow.

## Summary

[Extract from feature spec: primary Arabic user-facing requirement + technical
approach after existing-project discovery]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with project-specific
  technical details for this feature. Product behavior belongs in spec.md;
  this section explains how the existing implementation will be extended safely.
-->

**Language/Version**: Dart / Flutter SDK from `pubspec.yaml` or NEEDS CLARIFICATION
**Primary Dependencies**: Flutter Material, Riverpod, Drift/SQLite, pdf/printing, excel, barcode, url_launcher or NEEDS CLARIFICATION
**Storage**: Existing Drift/SQLite database and asset seed database or N/A
**Testing**: `flutter analyze`, targeted Flutter/widget/unit tests, migration/export/PDF checks as applicable
**Target Platform**: Existing Flutter targets in this repository, with desktop-first behavior unless specified
**Project Type**: Existing Arabic Sunday School management Flutter application
**Performance Goals**: Preserve responsive admin workflows, reliable PDF/export generation, and safe database access
**Constraints**: Arabic RTL UI, existing-project compatibility, data preservation, no overflow, explicit validation and feedback
**Scale/Scope**: One or two related areas per implementation phase

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Existing Project First**: List the existing screens, repositories, providers,
  database tables/migrations, services, PDF/export code, assets, and UI patterns
  inspected before design. Reuse the current stack and folder conventions.
- **Product vs Technical Separation**: Confirm product behavior is described
  separately from implementation choices.
- **Arabic RTL Product**: Confirm all new user-facing UI, messages, print/PDF
  text, and export headings are Arabic and RTL-aware.
- **Backward Compatibility**: Identify existing login, permissions, attendance,
  services, cards, behavior, analysis, choruses/groups, stages, exports, reports,
  and maintenance flows affected, plus regression criteria for each.
- **Data and Migration Safety**: Document schema changes, Drift schema version
  impact, safe migration behavior, and data preservation guarantees.
- **UI/UX Quality**: Define responsive behavior, visual-system alignment,
  accessibility considerations, and empty/loading/error/success states.
- **Validation and Safety**: List validation for forms, URLs, phone/WhatsApp
  links, print settings, exports, file paths, and free text. Confirm generated
  URLs use proper encoding.
- **Printing and Export Reliability**: For affected reports/cards/exports,
  define page size/orientation, barcode behavior, font embedding, scaling, and
  representative verification data.
- **Incremental Delivery**: Limit this plan to one or two related areas, name
  the stop point, and state the summary/tests/risks expected at phase completion.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
\-- tasks.md
```

### Source Code (repository root)

```text
lib/
|-- database/       # Drift database, tables, migrations, generated artifacts
|-- models/         # Lightweight DTOs/value models
|-- repositories/   # Drift-backed query and persistence boundaries
|-- screens/        # Arabic RTL Material screens and dialogs
|-- services/       # Auth, PDF, printing, export, backup, and domain services
|-- theme/          # Existing visual identity and shared theme
|-- ui/             # Shared dialogs/widgets
|-- utils/          # Utilities
\-- widgets/        # Shared and dashboard widgets

test/               # Flutter tests where present or added for this feature
assets/             # Database seed, fonts, logos, and print assets
```

**Structure Decision**: [Document the selected existing directories and exact
files this feature will reuse or modify]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., new storage path] | [current need] | [why existing Drift/SQLite path is insufficient] |
