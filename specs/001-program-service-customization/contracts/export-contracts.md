# Export and Printing Contracts

These contracts describe internal export behavior for planning and testing.

## PdfExportOptions

Fields:

- `orientation`: `portrait` or `landscape`.
- `stretchToFit`: boolean.
- `groupMode`: `singlePdfNewPages` or `separatePdfPerGroup`.
- `destinationFolder`: required only for `separatePdfPerGroup`.

Arabic labels:

- `اتجاه الصفحة`
- `طولي`
- `عرضي`
- `ملاءمة الجدول داخل الصفحة`
- `كل مجموعة تبدأ في صفحة جديدة`
- `كل مجموعة في ملف PDF منفصل`
- `اختر مجلد الحفظ`

## Stretch-to-Fit Behavior

- When disabled: preserve current export behavior, including current auto-orientation rules.
- When enabled:
  - Respect selected orientation.
  - Keep table content within page boundaries.
  - Prefer readable font limits and pagination over clipping.
  - If readability becomes poor, show Arabic warning before or during export.

## Separate Group PDF Behavior

- Input grouping source: top-level selected grouping criterion from the existing sorting/grouping dialog.
- Output: one PDF per non-empty group in the selected folder.
- File name:
  - Preserve Arabic group name where possible.
  - Remove path-unsafe characters.
  - Add date/service/export suffix for clarity.
  - De-duplicate repeated names.
- Empty groups:
  - Report in Arabic.
  - Do not silently mix or lose data.

## Card Print Contract

- Legacy print flow remains available.
- Designer print uses the active card template.
- Barcode/QR data remains the person ID string.
- PDF output must use Arabic-capable fonts and preserve RTL text.
- Manual verification must include Code128 and QR scan tests.
