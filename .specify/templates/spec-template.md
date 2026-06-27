# Feature Specification: [FEATURE NAME]

**Feature Branch**: `[###-feature-name]`
**Created**: [DATE]
**Status**: Draft
**Input**: User description: "$ARGUMENTS"

## User Scenarios & Testing *(mandatory)*

<!--
  User stories must describe Arabic user-facing behavior, not technical design.
  Prioritize journeys by value. Each story must be independently testable and
  preserve existing Sunday School workflows unless this spec says otherwise.
-->

### User Story 1 - [Brief Title] (Priority: P1)

[Describe this Arabic RTL user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently and what
existing workflow must still work]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected Arabic RTL outcome]
2. **Given** [initial state], **When** [action], **Then** [expected preserved behavior]

---

### User Story 2 - [Brief Title] (Priority: P2)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### User Story 3 - [Brief Title] (Priority: P3)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

[Add more user stories as needed, each with an assigned priority]

### Edge Cases

- What happens with empty data, long Arabic names, missing optional fields, and invalid input?
- How does the system show Arabic loading, success, empty, and error states?
- How are existing records, permissions, and reports protected from regression?
- If printing/exporting is affected, how are page overflow, scaling, fonts, and orientation handled?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST [specific capability]
- **FR-002**: System MUST [specific capability]
- **FR-003**: Users MUST be able to [key interaction]
- **FR-004**: System MUST [data requirement]
- **FR-005**: System MUST [behavior]

*Example of marking unclear requirements:*

- **FR-006**: System MUST authenticate users via [NEEDS CLARIFICATION: auth method not specified]
- **FR-007**: System MUST retain user data for [NEEDS CLARIFICATION: retention period not specified]

### Product Constraints *(mandatory for this project)*

- **PC-001**: User-facing UI, messages, print/PDF text, and export headings MUST
  be Arabic unless the existing application intentionally uses a specific English term.
- **PC-002**: New or changed UI MUST preserve RTL behavior and define empty,
  loading, error, and success states.
- **PC-003**: Existing login, permissions, attendance, services, ID cards,
  behavior, analysis, choruses/groups, stages, exports, reports, and maintenance
  workflows MUST be preserved unless this spec explicitly describes a safe change.
- **PC-004**: Any data model change MUST preserve existing data and require a
  migration-safe implementation plan.
- **PC-005**: Any affected printing, barcode, PDF, or table export behavior MUST
  include page fitting, orientation/scaling, Arabic font, and overflow acceptance
  criteria.
- **PC-006**: Implementation scope MUST fit one or two related areas per phase.

### Key Entities *(include if feature involves data)*

- **[Entity 1]**: [What it represents, key attributes without implementation]
- **[Entity 2]**: [What it represents, relationships to other entities]

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: [Measurable user/product outcome]
- **SC-002**: [Measurable compatibility or data-preservation outcome]
- **SC-003**: [Measurable Arabic RTL UI quality or workflow completion outcome]
- **SC-004**: [Measurable print/export/report outcome, or N/A with rationale]

## Constitution Alignment *(mandatory)*

- **Existing Project Discovery**: [List current files/modules/screens/services/database tables inspected]
- **Product Requirements**: [Describe user-visible Arabic RTL behavior without technical design]
- **Backward Compatibility**: [List existing workflows that must keep working and how they will be checked]
- **Validation and Feedback**: [List required validation plus Arabic error/success/loading/empty states]
- **Printing/Export Impact**: [State N/A or define affected PDF/print/export acceptance criteria]
- **Phased Delivery**: [Define the one- or two-area phase boundary and stop point]

## Assumptions

- [Assumption about target users]
- [Assumption about scope boundaries]
- [Assumption about data/environment]
- [Dependency on existing system/service]
