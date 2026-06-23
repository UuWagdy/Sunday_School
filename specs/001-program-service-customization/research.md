# Research: Configurable Program Identity, Card Designer, Exports, Services, and Behavior Scoring

## Decision: Use the Existing Flutter/Riverpod/Drift Stack

**Rationale**: `pubspec.yaml`, `lib/main.dart`, and repositories show this is a local Flutter app using Material UI, Riverpod, Drift/SQLite, and generated providers. The constitution forbids rebuilding or introducing a new major framework.

**Alternatives considered**: New routing/state-management framework, web/backend split, separate admin panel. Rejected because the app has no backend and existing flows are already implemented locally.

## Decision: Store Program Name and Active Card Template in Existing Settings

**Rationale**: `SettingsRepository` already persists `church_name`, `church_logo`, and many `id_card_*` settings. The configurable program name is global and simple. One active card template matches current one-active-card-settings behavior.

**Alternatives considered**: New settings table, shared preferences, per-service program name, multiple templates. Rejected for Phase 1-3 because they add migration/UX complexity without current project precedent.

## Decision: Use Settings Image Bytes for Card Designer Images

**Rationale**: Current card logo/background settings already store base64 image bytes in Settings. Service, khoros, and person images use BLOB/bytes. Reusing byte storage avoids broken external file paths after moving files or restoring backups.

**Alternatives considered**: Local file path references, app assets, new media system. Rejected because local paths are fragile and no general media system exists.

## Decision: Preserve Existing Barcode/QR Data and Libraries

**Rationale**: `id_card_pdf_generator.dart` uses `Barcode.code128()` and `Barcode.qrCode()` from the `barcode` package. Both encode `person.id.toString()`. `qr_scanner_screen.dart` and attendance scanning expect IDs/codes.

**Alternatives considered**: New barcode library, richer encoded payload. Rejected because it would risk scanner compatibility and existing card behavior.

## Decision: Add New Many-to-Many Tables for Khoros/Stage Services

**Rationale**: Current `Person_Services` already models many-to-many person services. `Stages.Service_ID` and `Khoroses.Service_ID` are single-service legacy links. New link tables preserve old data while allowing multiple services.

**Alternatives considered**: CSV service IDs in existing columns, duplicate khoros/stage records, direct-only person services. Rejected because they are harder to query/migrate and risk data duplication.

## Decision: Use Union Eligibility Rules

**Rationale**: Current person add/update already unions explicit person services with stage and khoros services. Keeping union semantics avoids conflicts and preserves existing behavior when stage and khoros differ.

**Alternatives considered**: Stage wins, khoros wins, explicit person services only. Rejected because they would remove access that current inherited service behavior grants.

## Decision: Reject Invalid Attendance in UI and Repository

**Rationale**: UI feedback prevents user confusion during scan/search, while repository validation protects all save paths. This matches existing validation pattern where UI checks selected service/day and repository returns Arabic error messages.

**Alternatives considered**: UI-only validation, save-only validation. Rejected because either path leaves a regression risk.

## Decision: Add PDF Options Incrementally

**Rationale**: Attendance list/grid and term attendance are the highest-risk wide table exports. Existing services already auto-orient and use Arabic fonts. A reusable options model can be introduced there first, then expanded after review.

**Alternatives considered**: Modify every PDF generator in one phase. Rejected because it increases regression risk across unrelated reports.

## Decision: Separate Group PDFs Go to a User-Selected Folder

**Rationale**: Multiple output files are easiest to understand when generated into one chosen folder with safe names. Existing file workflows already use `file_picker` for save/pick operations.

**Alternatives considered**: ZIP file, prompt once per group, print dialogs only. Rejected because ZIP adds new packaging behavior and per-file prompts are slow for many groups.

## Decision: Missing Behavior Defaults to 5 Only in Calculation

**Rationale**: `Coming.Behavior` already defaults to 5 and UI allows 0-7. Missing/no-record must be interpreted as 5 for analysis/term closing, but explicit 0 is valid and must remain 0.

**Alternatives considered**: Backfill missing records with 5, treat 0 as missing. Rejected because backfill mutates history unnecessarily and 0 is an allowed recorded score.
