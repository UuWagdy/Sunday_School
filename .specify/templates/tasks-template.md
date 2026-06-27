---

description: "Task list template for feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Include tests or explicit verification tasks for every constitution
risk area touched by the feature. At minimum, include `flutter analyze`; add
targeted Flutter/widget/unit tests, migration checks, responsive UI review, and
PDF/export inspection when relevant.

**Organization**: Tasks are grouped by user story to enable independent
implementation and testing of each story. Each implementation phase must cover
only one or two related areas, then stop for summary, tests performed, and
remaining risks.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Flutter app code: `lib/`
- Drift database: `lib/database/`
- Repositories: `lib/repositories/`
- Screens/dialogs: `lib/screens/` and `lib/ui/`
- Services, PDF, printing, exports, backup: `lib/services/`
- Shared widgets: `lib/widgets/`
- Tests: `test/`
- Assets, fonts, seed database, logos: `assets/`

<!--
  The /speckit-tasks command MUST replace these sample tasks with actual tasks
  based on user stories, requirements, plan.md, data-model.md, and contracts/.
  Do not keep sample paths or unrelated phases in the generated tasks.md file.
-->

## Phase 1: Setup (Existing-Project Discovery)

**Purpose**: Understand current implementation and keep scope narrow

- [ ] T001 Inspect affected existing Flutter screens, repositories, providers, services, database tables, generated Drift files, PDF/export code, assets, and UI patterns
- [ ] T002 Document product requirements separately from technical implementation decisions in the plan
- [ ] T003 Confirm the phase is limited to one or two related areas and define the stop point
- [ ] T004 [P] Identify existing Arabic RTL labels/messages and design-system patterns to preserve

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared safety decisions that MUST be complete before user story work

**CRITICAL**: No user story work can begin until this phase is complete

- [ ] T005 Define safe Drift migration approach if schema/data changes are required
- [ ] T006 [P] Define validation and Arabic feedback states for all changed forms/actions
- [ ] T007 [P] Define responsive RTL UI behavior and empty/loading/error/success states
- [ ] T008 Define regression checks for affected login, permissions, attendance, services, cards, reports, exports, or maintenance flows
- [ ] T009 Define PDF/printing/barcode/export verification data and page fitting criteria if applicable

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - [Title] (Priority: P1)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 1

- [ ] T010 [P] [US1] Add targeted test or verification for [changed behavior] in [path]
- [ ] T011 [P] [US1] Add regression check for preserved existing workflow in [path or manual checklist]

### Implementation for User Story 1

- [ ] T012 [P] [US1] Update existing model/DTO in [exact file path]
- [ ] T013 [P] [US1] Update existing repository/provider/service in [exact file path]
- [ ] T014 [US1] Update Arabic RTL UI in [exact file path]
- [ ] T015 [US1] Add validation, URL encoding where relevant, and Arabic error/success/loading/empty states
- [ ] T016 [US1] Verify RTL layout, responsive behavior, and existing workflow compatibility

**Checkpoint**: User Story 1 is functional, verified, summarized, and ready to stop

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 2

- [ ] T017 [P] [US2] Add targeted test or verification for [changed behavior] in [path]
- [ ] T018 [P] [US2] Add regression check for preserved existing workflow in [path or manual checklist]

### Implementation for User Story 2

- [ ] T019 [P] [US2] Update existing model/DTO in [exact file path]
- [ ] T020 [US2] Update existing repository/provider/service in [exact file path]
- [ ] T021 [US2] Update Arabic RTL UI in [exact file path]
- [ ] T022 [US2] Verify validation, responsive layout, and compatibility

**Checkpoint**: User Stories 1 and 2 both work independently

---

[Add more user story phases only if they fit the approved phase boundary]

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements and checks that affect the completed phase

- [ ] TXXX [P] Documentation updates in docs/ or specs/
- [ ] TXXX Code cleanup and refactoring within touched files only
- [ ] TXXX Performance review for changed queries, PDF generation, or export paths
- [ ] TXXX [P] Additional tests or manual verification for changed behavior
- [ ] TXXX Run `flutter analyze`
- [ ] TXXX Verify Arabic RTL UI on common desktop and mobile sizes
- [ ] TXXX Verify PDF/print/export output does not overflow when affected
- [ ] TXXX Security and validation hardening
- [ ] TXXX Run quickstart.md validation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - discovery starts immediately
- **Foundational (Phase 2)**: Depends on discovery completion - BLOCKS user stories
- **User Stories (Phase 3+)**: Depend on Foundational phase completion
- **Polish (Final Phase)**: Depends on all approved stories in this phase

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational - no dependency on later stories
- **User Story 2 (P2)**: Can start after Foundational - may integrate with US1 but must remain testable
- **User Story 3 (P3)**: Add only when approved for this phase boundary

### Within Each User Story

- Tests or explicit verification before implementation when practical
- Database migration before repository changes when schema is affected
- Repositories/services before UI that depends on them
- Validation and Arabic feedback before story checkpoint
- Story complete before moving to the next priority

### Parallel Opportunities

- Discovery tasks marked [P] can run in parallel
- Validation-state and UI-state definitions marked [P] can run in parallel
- Tests for a user story marked [P] can run in parallel
- Different files within the same approved scope can be worked in parallel

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Existing-project discovery
2. Complete Phase 2: Foundational safety decisions
3. Complete Phase 3: User Story 1
4. STOP and VALIDATE: Test User Story 1 independently, summarize changes, list tests, and disclose risks

### Incremental Delivery

1. Complete discovery and foundational safety decisions
2. Add User Story 1, test independently, then stop for summary
3. Add User Story 2 only if it belongs to the same approved phase boundary
4. Preserve existing behavior at every checkpoint

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to a specific user story for traceability
- Each story must be independently completable and testable
- Avoid vague tasks, unrelated modules, and cross-story dependencies that break independence
- Do not rebuild or replace the existing application structure
