<!--
Sync Impact Report
Version change: template -> 1.0.0
Modified principles:
- Template principle 1 -> I. Existing Project First
- Template principle 2 -> II. Arabic RTL Product
- Template principle 3 -> III. Backward Compatibility and Data Preservation
- Template principle 4 -> IV. Professional UI/UX Quality Bar
- Template principle 5 -> V. Validation, Safety, and Explicit Feedback
Added principles:
- VI. Printing and Export Reliability
- VII. Incremental Implementation
Added sections:
- Product Requirements
- Technical Planning and Delivery Workflow
Removed sections:
- Placeholder Section 2
- Placeholder Section 3
Templates requiring updates:
- UPDATED .specify/templates/plan-template.md
- UPDATED .specify/templates/spec-template.md
- UPDATED .specify/templates/tasks-template.md
- REVIEWED .specify/templates/commands/*.md (directory not present; no command templates to update)
Runtime guidance reviewed:
- REVIEWED AGENTS.md
- REVIEWED README.md
- REVIEWED implementation_plan.md
Follow-up TODOs: None
-->
# Petros Pols Flutter Constitution

## Core Principles

### I. Existing Project First
This is an existing production-like Arabic Sunday School management application.
Contributors MUST inspect the current repository before changing code, including
the active Flutter modules, UI patterns, state management, Drift database schema
and migrations, authentication and permissions, admin screens, PDF/printing,
barcode rendering, exports, assets, naming conventions, and generated files.
Work MUST extend the current Flutter/Dart, Riverpod, Drift/SQLite, Material UI,
PDF/printing, Excel export, and asset structure unless an approved plan documents
why a focused exception is required. Rebuilding the application from scratch is
FORBIDDEN unless the user explicitly requests a rebuild.

Rationale: The repository already contains functioning domain modules for login,
people, attendance, reports, services, cards, choruses/groups, stages, behavior,
exports, and maintenance. Uninspected rewrites create regression and data-loss risk.

### II. Arabic RTL Product
All user-facing application UI, messages, labels, dialogs, empty states, loading
states, errors, success messages, print output, PDF output, and export headings
MUST be Arabic unless an existing screen intentionally uses a specific English
term. New UI MUST use RTL directionality and MUST preserve Arabic-capable fonts
for app and PDF rendering. Mixed-direction content such as phone numbers, codes,
URLs, and file names MUST be displayed without breaking the surrounding RTL flow.

Rationale: The product serves Arabic Sunday School workflows. Language and text
direction are core product behavior, not presentation details.

### III. Backward Compatibility and Data Preservation
Changes MUST NOT break existing login, permissions, people, services, attendance,
ID card printing, barcode scanning, behavior, analysis, choruses/groups, stages,
exports, reports, maintenance, or backup/restore behavior. Existing data MUST be
preserved. Database changes MUST use safe Drift migrations, increment the schema
version when required, include forward migration behavior, and avoid deleting
unrelated data. Destructive cleanup, feature removal, or schema replacement is
FORBIDDEN unless an approved migration plan explains user impact and rollback or
safe-hide behavior.

Rationale: The app carries operational church data. Compatibility failures are
product failures even when new code compiles.

### IV. Professional UI/UX Quality Bar
UI changes MUST follow a professional design-system approach using the existing
visual identity unless the current design is demonstrably inconsistent. New or
changed screens MUST provide consistent colors, typography, spacing, responsive
layout behavior, accessibility semantics where relevant, clear visual hierarchy,
and complete empty, loading, error, and success states. Screens MUST work on
common desktop and mobile sizes without overflow, clipped text, unusable controls,
or overlapping content.

Rationale: The application is used for repeated administrative work. Polished,
predictable flows reduce mistakes and support burden.

### V. Validation, Safety, and Explicit Feedback
Forms, filters, phone numbers, WhatsApp or telephone links, payment fields if
introduced, URLs, print settings, PDF settings, file paths, imports, exports, and
free-text fields MUST be validated before use. Generated URLs MUST use structured
URI builders or equivalent URL encoding. Failures MUST surface clear Arabic error
messages and recoverable actions where possible. Silent failures, swallowed errors
without user feedback, and invalid generated output are FORBIDDEN.

Rationale: Administrative data and external actions such as calls, files, and
exports require predictable validation and visible failure states.

### VI. Printing and Export Reliability
Card printing, barcode rendering, PDF generation, table exports, page orientation,
page scaling, font embedding, RTL text rendering, and layout fitting MUST be
treated as testable product behavior. PDF and table output MUST fit within the
target page or sheet boundaries and MUST NOT overflow outside the page. Changes
that affect reports, cards, barcodes, or exports MUST include verification with
representative Arabic data, long names, empty values, and realistic print settings.

Rationale: Printed cards and reports are primary deliverables of the application,
so visual correctness and page fitting are functional requirements.

### VII. Incremental Implementation
Implementation MUST be phased. Each phase MUST cover only one or two related
areas, complete a coherent increment, stop for summary, list tests or checks
performed, and disclose remaining risks. Large feature sets MUST be split into
independently reviewable phases that preserve existing behavior at every step.
Plans and tasks MUST avoid bundling unrelated modules in one implementation pass.

Rationale: Incremental delivery limits regression risk in an existing app with
database, UI, printing, and export surfaces.

## Product Requirements

Product requirements MUST describe user-visible behavior independently from the
technical implementation. Specifications MUST identify the affected Arabic user
flows, user roles or permissions, expected RTL screens, required Arabic messages,
empty/loading/error states, data preservation expectations, and acceptance
criteria for printing or exports when relevant.

Product requirements MUST explicitly state whether existing behavior is preserved,
extended, hidden, or migrated. If a proposed feature changes login, permissions,
attendance, services, people, cards, reports, exports, choruses/groups, stages,
behavior, or maintenance workflows, the specification MUST include regression
acceptance criteria for the old workflow.

## Technical Planning and Delivery Workflow

Technical plans MUST start with discovery of the current implementation before
designing changes. A plan MUST name the existing files, modules, repositories,
database tables, generated Drift artifacts, providers, services, assets, and UI
patterns it will reuse or modify. Technical decisions MUST remain separate from
product requirements and MUST explain any deviation from existing architecture.

Before implementation, every plan MUST pass a Constitution Check covering:
existing-project discovery, Arabic RTL behavior, backward compatibility and data
preservation, professional UI/UX states, validation and explicit feedback,
printing/export reliability when applicable, and phased delivery scope. Tasks
MUST include verification appropriate to the risk area, including `flutter analyze`,
targeted tests, migration checks, responsive UI review, and PDF/export inspection
when affected.

## Governance

This constitution supersedes conflicting local practices for Spec Kit planning
and implementation in this repository. Amendments MUST update this file, include
a Sync Impact Report, and propagate any changed rules to dependent templates or
runtime guidance. Each amendment MUST use semantic versioning:

- MAJOR: backward-incompatible governance changes or removal/redefinition of
  existing principles.
- MINOR: new principles, new mandatory sections, or materially expanded guidance.
- PATCH: clarifications, wording improvements, or typo fixes without changing
  obligations.

Compliance review is required at specification, planning, task generation, and
implementation completion. Any plan or task list that violates a principle MUST
document the violation, justify why it is necessary, identify the safer
alternative considered, and receive explicit user approval before coding.

**Version**: 1.0.0 | **Ratified**: 2026-06-18 | **Last Amended**: 2026-06-18
