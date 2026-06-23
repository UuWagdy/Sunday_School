# UI Contracts

These are internal application UI contracts, not external APIs.

## Program Name Contract

- Location: Services Management identity area near church name/logo.
- Arabic labels:
  - `اسم البرنامج`
  - `مثال: مدرسة الشمامسة`
  - `تم حفظ اسم البرنامج`
  - `تم حذف اسم البرنامج`
  - `الرجاء إدخال اسم البرنامج`
- Consumers:
  - Login title.
  - Main shell app bar/drawer/account identity.
  - About dialog program title.
  - App title where runtime consumption is feasible.
- Fallback: `برنامج مدارس الأحد`.

## Card Designer Contract

- Entry point: Card tab, as a visible designer/preview mode without removing existing simple print controls.
- Layout:
  - Preview surface with fixed card aspect and responsive scaling.
  - RTL properties panel using sections/tabs for fields, text, images, background, barcode.
  - Icon buttons for add/remove/move actions; sliders/inputs for sizes/positions; swatches/color controls for colors.
- Required Arabic states:
  - Loading template.
  - Empty selected person preview.
  - Invalid image.
  - Element outside card bounds.
  - Barcode may be hard to scan.
  - Template saved.
  - Print canceled/error/success.
- Field label modes:
  - Global default: show labels or hide labels.
  - Per-field override: inherit/show/hide.
- Background fit labels:
  - `احتواء داخل البطاقة`
  - `ملء البطاقة`
  - `الحجم الأصلي`

## Attendance Rejection Contract

- Trigger points:
  - Person autocomplete selection.
  - Manual code submit.
  - QR/barcode scan submit.
  - Repository save validation.
- Message:
  - `هذا الشخص غير مرتبط بالخدمة المحددة ولا يمكن تسجيل حضوره فيها.`
- Behavior:
  - Clear/refocus input consistent with current attendance validation.
  - Do not save invalid attendance.
  - Preserve existing duplicate/day-of-week messages.

## Behavior Screen Contract

- Service selector becomes multi-select.
- Score buttons remain numeric 0-7.
- Default score display remains 5.
- Explicit 0 remains valid.
- Required Arabic states:
  - No selected services.
  - No matching persons.
  - Saving.
  - Save success.
  - Save failure.
