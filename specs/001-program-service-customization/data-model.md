# Data Model: Configurable Program Identity, Card Designer, Exports, Services, and Behavior Scoring

## Existing Entities Reused

### Settings

- Table: `Settings`
- Fields: `Setting_Key`, `Setting_Value`
- Used for: `church_name`, `church_logo`, existing `id_card_*` settings.
- New settings:
  - `program_name`: nullable/empty means default `برنامج مدارس الأحد`.
  - `id_card_active_template`: structured active template data.
  - Optional supporting image keys if template data is split for size/readability.
- Validation:
  - Program name must be non-empty after trim when saved.
  - Template data must parse and fall back safely to default template on invalid data.

### Persons

- Table: `Persons`
- Key fields: `Person_ID`, `Person_Name`, `Stage_ID`, `Khoros_ID`, `Area_ID`, `Father_ID`, `Photo`, phone/mobile/street/birthday/gender fields.
- Card data DTO: `PersonListDTO` already includes `khorosName`, `khorosId`, `photo`, `stageName`, `areaName`, `fatherName`, phone/mobile/street.
- Relationship:
  - One person has one current stage and one current khoros.
  - One person has many services through `Person_Services`.

### Services

- Table: `Services`
- Fields: `Service_ID`, `Service_Name`, `Day_Of_Week`, start/end time fields, `Logo`.
- Used for attendance validation, reports, filters, and service labels/logos.

### Khoroses

- Table: `Khoroses`
- Current fields: `Khoros_ID`, `Khoros_Name`, `Logo`, legacy `Service_ID`.
- New relationship: many services through `Khoros_Services`.
- Migration: each non-null legacy `Service_ID` becomes one row in `Khoros_Services`.

### Stages

- Table: `Stages`
- Current fields: `Stage_ID`, `Stage_Name`, legacy `Service_ID`, `Next_Stage_ID`.
- New relationship: many services through `Stage_Services`.
- Migration: each non-null legacy `Service_ID` becomes one row in `Stage_Services`.

### PersonServices

- Table: `Person_Services`
- Fields: `Person_ID`, `Service_ID`
- Primary key: `{Person_ID, Service_ID}`
- Meaning after feature: resolved eligibility services from explicit person assignment plus inherited stage/khoros services.

### Coming

- Table: `Coming`
- Fields used here: `Person_ID`, `date_Week`, `Point`, `Service_ID`, `Attend_Time`, `Checkout_Time`, `Behavior`.
- Behavior:
  - Stored behavior is an explicit score and can be `0`.
  - Missing row or missing behavior for a person/service calculation counts as 5.
  - Attendance rejection must prevent invalid `Coming` rows for ineligible person/service pairs.

## New Entities

### Program Identity Setting

- Storage: `Settings.program_name`.
- Default state: absent/null/empty uses `برنامج مدارس الأحد`.
- State transitions:
  - Default -> Custom when a valid name is saved.
  - Custom -> Default when setting is cleared/deleted.
- Validation:
  - Empty/whitespace save rejected or treated as delete only through explicit clear action.
  - Long names displayed with ellipsis/wrapping based on surface.

### CardTemplate

- Storage: one active template in `Settings`.
- Fields:
  - Template version.
  - Card dimensions and preview scale metadata.
  - Background image reference/bytes and fit mode: shrink-to-fit, zoom-to-fit, actual-size.
  - Global label visibility default.
  - Data field elements.
  - Fixed text elements.
  - Image elements.
  - Barcode/QR element.
- Relationships:
  - References person data fields by canonical field keys.
  - Does not create new person data.
- Validation:
  - Elements must remain within or intentionally clipped to card bounds.
  - Text size within safe configured min/max.
  - Image bytes must be decodable.
  - Unknown field keys ignored with Arabic warning or fallback.

### CardDataFieldElement

- Fields:
  - `fieldKey`: name, code, stage, area, street, phone, mobile, father, photo, khoros.
  - Position: normalized x/y.
  - Text color.
  - Text size.
  - Label mode: inherit/show/hide.
  - Visibility.
- Validation:
  - Missing optional values render as empty or hide based on template rule.
  - Label mode must be consistent with global default and per-field override.

### CardFixedTextElement

- Fields:
  - Text.
  - Position.
  - Text color.
  - Text size.
  - Alignment/direction defaults to RTL.
- Validation:
  - Empty text not saved as visible element.

### CardImageElement

- Fields:
  - Image bytes/reference.
  - Position.
  - Size.
  - Fit mode.
- Validation:
  - Decodable image required.
  - Size constrained to card bounds.

### BarcodeElement

- Fields:
  - Type: code128 barcode or QR.
  - Data source: person ID.
  - Position.
  - Size.
  - Background mode: white or transparent.
  - Quiet-zone/padding flag for white background.
- Validation:
  - Minimum visual size by type.
  - Warn if transparent background may reduce contrast.
  - Data behavior must remain unchanged.

### PdfExportOptions

- Fields:
  - Orientation: portrait or landscape.
  - StretchToFit: true/false.
  - Group export mode: single PDF with new pages or separate PDFs per group.
  - Destination folder for separate PDFs.
- Validation:
  - Destination required for separate PDFs.
  - Empty data/groups reported clearly.
  - File names sanitized and de-duplicated.

### KhorosServices

- Table: `Khoros_Services`
- Fields:
  - `Khoros_ID` references `Khoroses`.
  - `Service_ID` references `Services`.
- Primary key: `{Khoros_ID, Service_ID}`
- Validation:
  - No duplicates.
  - Removing a service updates member eligibility only when no other source requires it.

### StageServices

- Table: `Stage_Services`
- Fields:
  - `Stage_ID` references `Stages`.
  - `Service_ID` references `Services`.
- Primary key: `{Stage_ID, Service_ID}`
- Validation:
  - No duplicates.
  - Removing a service updates member eligibility only when no other source requires it.

### ServiceEligibility

- Derived, not necessarily persisted as a table.
- Inputs:
  - Explicit person services from `Person_Services`.
  - Khoros services from `Khoros_Services`.
  - Stage services from `Stage_Services`.
- Rule:
  - Eligibility is the union of all sources.
  - If stage and khoros conflict, both sets are valid.
- Consumers:
  - Person add/update.
  - Bulk transfer.
  - Attendance search/scan/save.
  - Reports where selected service should respect person eligibility.

## Migration Rules

1. Increment Drift schema version from 31 to the next version during Phase 5.
2. Add `Khoros_Services` and `Stage_Services` to `tables.dart`.
3. Create tables safely in `onUpgrade`.
4. Insert migrated links from `Khoroses.Service_ID` and `Stages.Service_ID`.
5. Add tables to `_ensureAllColumnsAndTablesExist`.
6. Keep old single-service columns for compatibility during the feature.
7. Regenerate Drift artifacts.
8. Validate migration using an old database with populated stages/khoroses.

## Behavior Calculation Rule

- Possible behavior points are evaluated per eligible person/service/date meeting where behavior is included.
- If a matching `Coming` row has `Behavior = 0`, use 0.
- If a matching row has `Behavior = null`, use 5.
- If no matching row exists for a possible service/date, use 5 for behavior calculations only.
- Do not insert default records solely to represent missing behavior.
